## 1.2.5.6

**Bambuddy 1.2.5.6**

**What this is**

A fix release on top of the 1.2.5.5 hotfix, and the first one since 1.2.5 whose headline is not a feature. 40 fixes, three behaviour changes, Swedish as the fifteenth interface language, and four dependency advisories closed. What holds it together is a run of faults that took the whole server down rather than one page: slicing a plate of many copies of one part could get Bambuddy OOM-killed, a printer that had been offline for hours could wedge the connection watchdog, and restoring a backup made by a different version could drop your live database and then fail on the way back up. All three are fixed, and the last one is now refused before anything is touched rather than halfway through.

Around those sit the usual spread - AMS slots and K profiles, the queue and its dispatch, archives, the virtual printer, permissions - plus one structural change that should be invisible: the MakerWorld integration is now a model-provider package, so a second model site becomes an implementation rather than a second copy of the feature. Nothing about the MakerWorld flow changes.

Two changes come from outside contributors. 29 people are credited across this release. One schema change is applied automatically on both SQLite and PostgreSQL. There are no breaking API changes, but there is one permission change worth reading before you update.

If you are coming from 1.2.5 or earlier, read the 1.2.5 release notes first - all of its upgrade callouts apply to you as well. If you skipped 1.2.5.4, read its notes too.

**Upgrade notes**

- **A camera token no longer opens thumbnails (#3025).** Thirteen routes that have nothing to do with a camera used to take the camera stream token as their credential - library and archive thumbnails, plate previews, timelapses, print photos, QR codes, project covers, print-log and printer cover images, external-link icons. They now take a new media token that carries the identity of whoever asked, so each applies the permission its own resource is governed by. The cam wall, the streaming overlay and the kiosk views use only the three real camera routes and are unaffected. If you have an integration pulling a thumbnail or a cover image with a pasted `camera_stream`, `camwall` or `overlay` token, switch it to an API key: the media routes accept `X-API-Key` and `Authorization: Bearer` directly, which the camera-token-only versions did not.

- **ntfy per-event priorities start being honoured (#3139).** They have been set, stored and silently discarded since the feature shipped. On upgrade the values already sitting in your database take effect, so an event you mapped to Min or Low will arrive quieter than it did yesterday. That is the setting working, not alerts going missing.

- **An AMS that reports only the humidity drop index now reports no humidity at all (#3140).** The drop index is a 1-5 scale that runs the opposite way from a percentage, and it was being rendered as one. Such a unit now hides the water-drop indicator, leaves a gap in the history chart, and is skipped by the humidity alarm and auto-drying instead of reading as permanently bone dry. No supported printer is known to do this - the report came from an install running X1Plus - and temperature is recorded and alarmed on as before.

- **`user_wallets.currency` is dropped.** Applied automatically on PostgreSQL and on SQLite 3.35 or newer; older SQLite keeps the unused column, which costs nothing. Finance now reads the install's `currency` setting like every other page (#3123).

- **The virtual printer CA fix applies to newly generated CAs only (#3014).** An install that already has a CA keeps it untouched and nothing needs re-importing. If you run two Bambuddy instances and a slicer can only reach one of them, delete `bbl_ca.crt` and `bbl_ca.key` from `virtual_printer/certs/` on one install so a fresh, uniquely named CA is generated - and import that one into the slicer again.

- **Backups now carry a `manifest.json`** naming the version that wrote them, so a restore that cannot succeed says "this backup was made by X, this install runs Y" and refuses before services are paused, before the key file is written and before the first DROP. Backups taken before the manifest existed restore exactly as they did.

**Docker**

```bash
docker compose pull
docker compose up -d
```

**Native install - recommended path**

```bash
sudo BRANCH=main /opt/bambuddy/install/update.sh
```

**Native install - manual path**

```bash
sudo systemctl stop bambuddy
cd /opt/bambuddy
sudo -u bambuddy git fetch --prune --tags --force origin
sudo -u bambuddy git checkout main
sudo -u bambuddy git reset --hard origin/main
sudo /opt/bambuddy/venv/bin/pip install -r requirements.txt
cd frontend && sudo npm i
sudo systemctl start bambuddy
```

**Windows install**

Download `bambuddy-1.2.5.6-windows-x64-setup.exe` from this release page (or the unversioned `bambuddy-windows-x64-setup.exe` alias). Existing Windows installs upgrade in place via the in-app Install Update flow.

**New**

- **Swedish (sv) is now a supported interface language** (#3052, requested and contributed by @AntonPalmqvist in #3062) - the fifteenth locale, listed as "Svenska" in the language picker. It arrived in full parity with the reference locale: all 6302 leaves present, structure and key order matching `en.ts`, placeholders intact. The 156 leaves Swedish keeps in English - format strings, product names, and the technical UI vocabulary Swedish takes verbatim - are enumerated by value in a 74-entry allow-list, the same shape the other thirteen locales use.

**Changed**

- **The MakerWorld integration is now a model-provider package**, so a second model site is an implementation rather than a second copy of the feature (#2845 by @pascalheidmann). A `ModelProvider` descriptor carries identity, host patterns, credentials, library folder, permissions and SSRF allowlists; a per-request service does the transport; a registry hands a pasted URL to whichever provider claims it. Nothing about the MakerWorld flow changes - the endpoints and their shapes are unchanged, the new `source_type` field defaults to `makerworld`, and thirteen of the eighteen transport functions are byte-identical by AST comparison, including the CDN allowlist, the 200 MB download cap and the certifi-pinned TLS context that keeps S3 downloads working on Windows.

- **Every FTP session Bambuddy opens now records how it closed** (#3009, reported by @grengojbo). Neither a clean close nor a hard socket drop used to log anything at any level, so a session closed properly and a socket genuinely abandoned produced identical output - none. Both now log one DEBUG line naming the printer, whether QUIT was acknowledged, why, and how long the session was held. Nothing about the connection handling itself changed, and at default log level nothing new is printed.

- **The schema no longer contains a cycle that `metadata.sorted_tables` cannot sort.** Three nullable SET NULL links between print archives, library files and library folders formed a loop SQLAlchemy answered with a sort it could not make plus a warning on every backup and every restore - and the warning ends with "may raise an error in a future release", which would have broken both on one upgrade. One edge is now marked `use_alter`, which removes it from the sort graph without removing the constraint from the database.

**Fixes**

**AMS slots, K profiles and drying:**

- An AMS that reports no humidity percentage no longer shows the drop index as one (#3140, reported by @Sawtaytoes). Three smaller faults in the same paths went with it, including a humidity of exactly 0% being stored as NULL.
- Assigning a spool to a slot holding a non-Bambu filament configured nothing, and could delete the assignment afterwards (#3084, reported by @anthonyma94; #3100, reported by @Sawtaytoes).
- K values missing on a second AMS, and its slots unconfigurable (#3044, reported by @Zib-Astian) - an X2D with one AMS 2 Pro per hotend.
- Auto-drying skipped every composite spool (#3067, reported by @TheUltimateC0der) - PA6-CF was never reduced to its base material.
- AMS Filament Backup switched itself off with every print started from the queue (#3040, reported by @frnzzle). It never actually did: Bambuddy was reading its own request back as telemetry.
- Custom filament profiles arrived in the slicer as Generic, or as the Bambu profile they were built on (#3003, reported by @marivo).

**Spools, inventory and SpoolBuddy:**

- Linking a tag another spool already carries gave an answer nothing could act on, and a duplicate broke the request outright (#3110, reported by @Niko11111).
- "Clear RFID Tag" was permanently greyed out for a spool linked by its Bambu tray UUID (#3109, reported by @Niko11111).
- SpoolBuddy said "Unknown color" for spools Bambuddy names perfectly well (#3090, reported by @Sawtaytoes).

**Queue and dispatch:**

- Moving a queued job from "Any P2S" to one P2S threw away its filament colour (#3133, reported by @bgrr74).
- Asking for 25 copies across two printer models queued exactly one (#3101, reported by @Leander-Vh).
- A plate printed entirely from the external spool stalled at preheat and failed (#3087, reported by @Notaseraf) - HMS 07FF_8012, "Failed to get AMS mapping table".
- Preheat & Heat Soak delayed PLA prints by minutes with nothing to preheat for (#3041).
- The Timeline ignored Shortest Job First (#3043) and kept drawing the queue in its pre-SJF order indefinitely.
- A queue item pinned to one printer never said why it was waiting (#3074, reported by @Sawtaytoes).
- A queued print showed "ASAP" in the queue even when Queue was the option chosen (#3018, reported by @kilrah; also #2557, reported by @ddavidebor).
- Bulk edit could not turn G-code injection on or off (#3058).
- The Library bulk add-to-queue answered 200 for a call that queued nothing, and queued items nothing could dispatch (#3112, reported by @toxxicpickles).

**Slicing and previews:**

- Slicing a plate of many copies of one part could take the server down (#3135, reported by @TheUltimateC0der). 25 bins of 10,000 triangles arrived as 6.4 million, took 54 seconds and 8.4 GB, and ran on the main loop. The reporter's plate now renders in about 2.4 seconds under 400 MB, off the main loop, and a plate still too large is left without a thumbnail rather than risking the server.
- Server-side slicing rejected MakerWorld 3MFs over filament-index fields, and the plate preview was never sanitised at all (#3030, reported by @kielsucks).
- The Slice action offered Bambu Studio files its URI handler cannot load (#3029).
- "Slice" handed the slicer a download link that only worked once (#3029).

**Archives and printer connection:**

- A printer that had been offline for hours could stop the whole server (#3068, reported by @bazza2000) - the watchdog waited on a paho network thread that was never coming back.
- A print from Bambu Studio archived under the name `plate_1` instead of its own (#3126, reported by @alex-2000-ac-ghetto).
- An archive gave up on its 3MF for good after one slow transfer (#3063, reported by @dfrysinger).
- An archive left empty by a printer refusing FTPS blamed the slicer (#2780, reported by @AntonPalmqvist).
- Items Printed could not be set to 0 after a total plate failure (#3051, reported by @tdavis75).

**Virtual printer, install and diagnostics:**

- Two Bambuddy instances could not have their CA certificates trusted at the same time (#3014, reported by @Steven-Pierce) - both signed with an authority named `CN=Virtual Printer CA`, and a slicer's trust store resolves by subject name.
- On Windows and macOS the Virtual Printer's bind dropdown offered one entry per network adapter, not one per IP address (#3121, reported by @SJB-OLVG).
- A macOS native install could silently lose all access to the printer after a system or Homebrew update (#3114, reported by @TheeBobbyDonuts) - macOS grants Local Network permission to a code signature.
- The connection diagnostic told anyone whose LAN was not a /24 that their printer was on a different network (#3092, reported by @cwawak).
- Podman and LXC installs were told they were not running in a container at all (#3092, reported by @cwawak).

**Permissions, finance and notifications:**

- `camera:view` was required to see any image in the app (#3025, reported by @lonix). See the upgrade note above.
- The Finance sidebar entry was hidden from every non-admin, whatever their permissions (#3023, reported by @lonix). Four install flags now come from a new authenticated `GET /settings/ui-flags` instead of `settings:read`, which also grants sight of SMTP, LDAP and MQTT credentials.
- The Finance page showed euros whatever currency the install was set to (#3123).
- ntfy per-event priorities were set, stored, and never sent (#3139, reported by @Thomansky). See the upgrade note above.

**Camera, jog and interface:**

- An external RTSP camera could pass the connection test and still show a black live view (#3082, reported by @M1XZG).
- The jog API pushed an A1's nozzle at the plate when asked for clearance (#1334, reported by @AQU4R1U5).
- Hovering a muted control in the light theme made its label vanish (#1909, reported by @AntonPalmqvist).

**Platform and database:**

- Restoring a backup into a different version of Bambuddy failed, and the failure took the live database with it. The restore's first transaction wipes the database, so a NOT NULL column the running version has and the backup does not left the install with an empty schema, the previous data gone, and the MFA key file already replaced. Such a column is now filled from the model's default, and one that genuinely cannot be filled is refused before anything is touched. SQLite installs were never affected - they restore by copying pages.

**Security (dependencies)**

- Tiptap editor stack to 3.31.1, for a prototype-manipulation advisory in `@tiptap/core` (GHSA-cp6q-959q-f8rh).
- `browserslist` 4.28.1 to 4.28.8 and `@humanfs/node`, for three development-dependency advisories (GHSA-73wf-gq98-2v4g, GHSA-c83g-rgw3-j3cx, GHSA-p498-v437-472g).
- `fflate` to 0.8.3, for a denial-of-service advisory reachable through three's compressed-format loaders (GHSA-px8p-9vwx-vf98, #3034).
- Vitest to 4.1.11, for a path-traversal advisory in `@vitest/mocker` (GHSA-82fw-gwwq-j7x9).

**Merged community PRs in this release**

- #2845 by @pascalheidmann - the model-provider refactor of the MakerWorld integration.
- #3062 by @AntonPalmqvist - Swedish (sv) translation.

**Thanks**

To everyone who reported, captured logs, or sat through a diagnosis: @alex-2000-ac-ghetto, @anthonyma94, @AntonPalmqvist, @AQU4R1U5, @bazza2000, @bgrr74, @cwawak, @ddavidebor, @dfrysinger, @frnzzle, @grengojbo, @kielsucks, @kilrah, @Leander-Vh, @lonix, @M1XZG, @marivo, @Niko11111, @Notaseraf, @pascalheidmann, @Sawtaytoes, @SJB-OLVG, @Steven-Pierce, @tdavis75, @TheeBobbyDonuts, @TheUltimateC0der, @Thomansky, @toxxicpickles, @Zib-Astian.

---
**Sponsors**

Bambuddy is sustainable thanks to people who put their money where their use is. If this release saved you time or kept your farm running, the project runs on recurring contributions - there's no paid tier, no telemetry, no upsell, just sustainable maintenance.

- GitHub Sponsors (recurring, 5 tiers from $5/mo to $300/mo) - https://github.com/sponsors/maziggy
- Ko-fi (one-time or recurring) - https://ko-fi.com/maziggy

## 1.2.5.5

**Bambuddy 1.2.5.5 Hotfix**

**What this is**

A hotfix for one regression in 1.2.5.4: on some installs every camera stopped working at once. Nothing else in 1.2.5.4 is changed. If your cameras work, you are not affected and this is an optional update - but read "Are you affected?" below anyway, because the same misconfiguration carries a second, silent risk that has nothing to do with cameras.

Two supporting changes ship alongside the fix so the condition cannot stay hidden on anyone's machine: Bambuddy now says so at startup when it finds itself on the wrong event loop, and the update scripts repair a service file that predates the flag which prevents it.

**Are you affected?**

Symptoms: live view shows "Connection lost" on every RTSP printer at once - X1, X1C, X1E, X2D, H2C, H2D, H2DPRO, H2S, P2S - and Settings > Connection Diagnostic reports "capture_exception" at 0 ms while network reachability passes at 1 ms. Snapshots, timelapse frames and the finish photo fail with it. A1, A1 mini, P1P and P1S use a different camera protocol and were never affected.

That 0 ms is the tell: the failure happened before a socket was opened.

Bambuddy is developed, tested and shipped on Python's own asyncio event loop, and every launch path in this project pins it - the Docker image, install.sh, the systemd unit, the launchd plist, the Windows service and the SpoolBuddy installer. What broke are the installs running a service file Bambuddy's installer did not write:

- The Proxmox VE Helper-Scripts LXC composes its own service file with no loop pinned. That is the reported case.
- Native installs created before 2026-07-05, when the flag was added. Updating has never rewritten an existing service file, so those installs never received it no matter how many times they were updated.

Docker is unaffected - the image pins the flag itself. Windows is unaffected in every case, because the alternative loop is never installed there.

To check a native install:

    systemctl show bambuddy --property=ExecStart --value | grep -o -- '--loop [a-z]*'

No output means no loop is pinned. Updating to 1.2.5.5 through update.sh adds it for you.

**Why it matters beyond cameras**

The same condition is what #1896 was about: on that loop, a Virtual Printer FTP upload can be silently truncated, acked as successful, archived and forwarded to the printer as a corrupt file. There is a backstop for that - since 0.2.5b2 a received 3MF is validated as a complete ZIP before it is accepted - but a backstop is not a reason to keep running the loop that needs it. Losing every camera at once is loud. A truncated upload is not, and shows up much later as a print failing from a file that was already corrupt when it arrived.

That is why 1.2.5.5 does not stop at the camera fix.

**Docker**

    docker compose pull
    docker compose up -d

**Native install - recommended path**

    sudo BRANCH=main /opt/bambuddy/install/update.sh

This is the path that also repairs the service file. It backs the file up first and inserts nothing but the missing flag.

**Native install - manual path**

    sudo systemctl stop bambuddy
    cd /opt/bambuddy
    sudo -u bambuddy git fetch --prune --tags --force origin
    sudo -u bambuddy git checkout main
    sudo -u bambuddy git reset --hard origin/main
    sudo /opt/bambuddy/venv/bin/pip install -r requirements.txt
    cd frontend && sudo npm i
    sudo systemctl start bambuddy

The manual path does not touch your service file. If the check above printed nothing, add "--loop asyncio" to the uvicorn command in /etc/systemd/system/bambuddy.service, then run "sudo systemctl daemon-reload" before starting.

**Proxmox VE Helper-Scripts LXC**

The community script writes its own service file and will not gain the flag from a Bambuddy update. Update Bambuddy as usual - the camera fix applies either way and your cameras will work again. To also close the upload risk, edit /etc/systemd/system/bambuddy.service, append "--loop asyncio" to the ExecStart line, then:

    systemctl daemon-reload
    systemctl restart bambuddy

**Windows install**

Download bambuddy-1.2.5.5-windows-x64-setup.exe from this release page (or the unversioned bambuddy-windows-x64-setup.exe alias). Existing Windows installs upgrade in place via the in-app Install Update flow. Windows was not affected by this regression.

**Fixed**

- Every camera stopped working on 1.2.5.4 (#3001) - The RTSPS proxy introduced in 1.2.5.4 finished by attaching its set of live connection handlers to the server object. That is legal on asyncio's server, which accepts new attributes, and an outright error on the alternative loop's server, which does not - so on those installs the proxy raised before it opened a socket and took live view, snapshots, timelapse frames and the diagnostic with it. The handler set now lives beside the server rather than on it, which both loops accept, and is held weakly so a proxy that is abandoned without a clean shutdown retires its own entry instead of leaking one. External RTSPS cameras were never affected: they caught the error and fell back to a direct connection. Reported by @Jieper001, confirmed by @JmanB52D and @hikingthunder, who also posted the first working patch.

- Two external-camera shutdown paths could leave connection handlers running past the server that owned them - introduced with the shared teardown helper in 1.2.5.4 and missed at those two call sites.

**Changed**

- Bambuddy warns at startup when it is running on the wrong event loop - one line in the log naming the loop, what it risks, and the exact flag to add. A warning and not a refusal: by the time any Bambuddy code runs the loop has already been chosen, and a server that answers requests is better than one that will not start.

- update.sh and update_macos.sh repair a service file written before the flag existed - the systemd unit or the launchd plist, while the service is stopped, so it takes effect on the same restart. The file is copied to a timestamped backup first and nothing but the flag is inserted; a hand-edited port, extra hardening and everything else stay exactly as they were. Anything that is not a plain single-line uvicorn service is described rather than edited - a wrapper script, a command split across lines, a read-only file, or a service carrying systemd drop-ins. A loop you pinned deliberately is left alone.

**Notes for anyone who patched this by hand**

If you edited camera.py yourself from the issue thread, the update overwrites it with the shipped fix and nothing is left behind. The shipped version differs in one respect worth knowing: it keys the handler registry weakly by server rather than by object id, because object ids are recycled and a stale entry could otherwise be handed to an unrelated server later on.
