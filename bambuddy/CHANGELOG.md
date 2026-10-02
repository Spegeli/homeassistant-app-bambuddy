## 1.2.5.7

**Bambuddy 1.2.5.7**

**What this is**

A feature release on top of 1.2.5.6. 25 new features, four changes, 40 fixes and four dependency advisories closed. 29 community PRs were merged, and 28 people are credited.

The headline is **post-print outcome confirmation**. Until now a print that completed counted as a success, even if the part was warped or the wrong colour. A print can now ask whether it came out good, and the answer can come from the web UI, the printer card, a notification, or a 👍 / 👎 on the Telegram message. The File Manager gets the most new features: a Column view, larger previews with zoom and fullscreen, image previews, PDF thumbnails made on the server, notes, links and photos on library files, and **Combine to 3MF** for putting several STLs on one plate. Inventory gains material numbers and a managed supplier list. SSO logins can keep Bambuddy groups in step with the identity provider. Other applications can now sign people in with their Bambuddy account and send messages through your notification channels. Bambuddy itself can now show announcements from the maintainers.

Several of the fixes are notifications that had a toggle but never fired: Low Filament, Reorder Alert and Stock Break Alert all send now. Read **Before you update** below: some alerts will fire right after the upgrade.

New tables and columns are added automatically on both SQLite and PostgreSQL. There are no breaking API changes, but HMS fault `severity` values change; see below.

If you are coming from 1.2.5.5 or earlier, read the 1.2.5.6 release notes too. If you are coming from 1.2.5 or earlier, read the 1.2.5 notes first; all of their upgrade callouts apply to you as well.

**Before you update**

These change behaviour you may rely on. None of them needs action unless it applies to your setup.

- **Notifications that never fired now do.** Low Filament (#2913), Reorder Alert and Stock Break Alert (#2955) had toggles on every provider, but nothing ever sent them. If you switched Low Filament on in the past, expect one alert for each assigned spool that is already low right after updating, and again after each restart while it stays low. Stock alerts fire once per SKU when it reaches its reorder point or will run out before a reorder could arrive.

- **HMS faults use the printer's own level (#2728).** The status response, WebSocket, Camera Wall and MQTT relay carry the new `severity` values, so anything that reads `severity` will see different numbers for the same fault. Printer-error notifications now also go out for `hms[]` faults that have a description, which almost never happened before, so you may get more of them.

- **The queue starts jobs in the order the queue page shows (#3200).** Jobs pinned to a printer and jobs queued for "Any <model>" used to be ordered separately, and which one won a printer depended on the database. If your queue mixes both, jobs may now start in a different order than you are used to, namely the one on screen.

- **Spoolman: each spool's own size is used (#3194).** Editing **Label Weight** now changes only that spool, not its filament. **Cost per kg** is converted at the spool's size, both ways. For 1000 g spools nothing changes. Spools that an earlier version reset with **Reset usage to 0** had their remaining weight overwritten in Spoolman and need re-weighing once (#2906).

- **Announcements from the maintainers.** Bambuddy now fetches one signed file from the public `maziggy/bambuddy-notifications` repo on GitHub, at startup and every 6 hours. Nothing about your install is sent. Administrators see them by default. **Settings → General → Updates** can show them to every user, or turn them off entirely, in which case nothing is fetched.

- **PostgreSQL: the default connection pool is now 80 instead of 100.** A stock PostgreSQL allows 97, so every install without its own `DB_POOL_SIZE` / `DB_MAX_OVERFLOW` logged a warning at startup. If you raised the server's `max_connections` and want the old ceiling, set `DB_MAX_OVERFLOW=80`.

- **Telegram reactions need a bot of their own (#3129).** If you choose **Reaction (👍 / 👎)** as a Telegram provider's verdict mode, Bambuddy polls that bot for reactions. Another app polling the same bot, such as Home Assistant's Telegram integration, stops receiving its messages. In a group, the bot must be an admin to see reactions.

- **A printer added by discovery with the wrong model keeps it.** The P-series code table was shifted, so a discovered P1S was saved as a P1P, a P1P as a P1S, and an X1E as a P2S. New printers are saved correctly. For one already saved wrong, pick the right model under **Model** in **Edit** from the printer card's menu.

- **Native installs get one new Python dependency**, `pypdfium2`, for PDF thumbnails. The update script and the manual `pip install -r requirements.txt` below install it; it bundles its own binary, so no system package is needed.

---

**How to update**

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

Download `bambuddy-1.2.5.7-windows-x64-setup.exe` from this release page (or the unversioned `bambuddy-windows-x64-setup.exe` alias). Existing Windows installs upgrade in place via the in-app Install Update flow.

---

**New**

**Print outcome:**

- **Post-print outcome confirmation** (#1898, requested by @FedericoPuntelli, contributed by @Thomansky in #3047) - turn on **Ask for Outcome** in the print dialog, or as a default under Settings → Workflow, and Bambuddy asks "How did your print come out?" with the finish photo and **Good** / **Reject**. You can answer in the web UI, on the printer card, or from a notification: ntfy and Telegram get buttons, every other channel a link. A reject takes an optional reason and offers **Print again**. Unanswered prints get an **outcome?** badge and an **Unconfirmed** filter on the Archives page.
- **Answer the outcome prompt with a Telegram reaction** (#3046, requested and contributed by @Thomansky in #3129) - a 👍 or 👎 on the message records the verdict. The phone only talks to Telegram, so it works away from home and needs no external URL. See **Before you update**.

**File Manager:**

- **Column view** (#3020, requested and contributed by @Thomansky in #3190) - a third view mode next to Grid and List, as in the macOS Finder: one column per folder level, with full keyboard navigation and the same actions as the list view.
- **Larger previews with zoom and fullscreen, and image previews** (#2976, requested and contributed by @Thomansky in #2990) - PDF, spreadsheet and 3D previews share one large window with a fullscreen button. PDFs zoom with Ctrl/⌘ + wheel, pinch or keys. PNG, JPG, GIF, WebP and BMP get a preview with zoom and pan. Double-click a file to open its preview.
- **PDF thumbnails as soon as the file arrives** (#2976) - page one is rendered on the server on upload, from ZIPs and from external folders. **Generate Thumbnails** backfills existing PDFs.
- **External link, notes and photos on library files** (#3077, requested by @SergioFuchs, contributed by @Thomansky in #3128) - **File details** opens the file's facts, an editable notes field, a link and a photo gallery.
- **Combine several STLs, or several copies of one, onto one plate** (#2999, requested by @Markus98, contributed by @adman234 in #3162) - select STLs, click **Combine to 3MF**, set the copies, and Bambuddy saves one 3MF with every object on one plate, optionally opening the Slice dialog with auto-arrange on.

**Inventory and spools:**

- **Material numbers** (#2870, requested and contributed by @Thomansky in #2994) - your own number per product, such as `15` for Bambu Lab PLA Basic, filled in automatically for new spools of the same product, with a column, filter, Bulk Edit and a **By Material Number** statistics widget.
- **Suppliers as a managed list** (#2988, requested and contributed by @Thomansky in #2996) - assign any number of suppliers to a spool, each with an article number and a quoted price per kg, mark where it was bought, and see consumption and cost **By Supplier** in Statistics.
- **Find a spool by its label number, and assign it to a slot from the spool** (#2978, requested and contributed by @pd81 in #2998) - `#3` finds only spool 3, and a spool without a slot has an **Assign Spool** button, which is also where scanning its QR code lands.
- **Choose what goes on a spool label, preview it, and save labels as PNG** (#2981, requested by @apizz) - a checkbox per line, a live preview, and PNG output at 203, 300 or 600 dpi for label printer software.
- **Ambient drying can wait for sustained humidity** (#2518, requested by @ryansouza, contributed by @M2ABRAMSTANK in #2895) - opening the AMS lid no longer starts a drying cycle of up to 12 hours. Off by default; 15 minutes when switched on.

**Queue and printing:**

- **Queue cards show the filament each job will print with** (#3132, requested and contributed by @bgrr74 in #3184) - colour swatches and names, the mapped slot and spool, and a yellow warning when a mapped slot has been emptied since.
- **Colour swatches for printer slots in the Print / Schedule dialog** (#3159, requested by @frantiseklorenc) - each slot shows its actual colour and hex, so a real colour mismatch can be told apart from two names for the same colour.
- **A batch can record the external order it fulfils** - `external_source` and `external_ref` on `POST /queue/batches`, unique together, so an integration that retries can't queue the same order twice.

**Notifications and camera:**

- **Camera snapshots reach more notifications and more providers** (#3089, requested and contributed by @bbbenji in #3199) - Plate Not Empty and AI Failure Detection carry a photo; Home Assistant, Bark and Slack-format webhooks get photos too, with an **Attach Photo** switch per provider.
- **Other applications can send messages through your notification channels** - a per-provider **Messages from connected apps** switch, off by default, and an API key with the new **Send Notifications** permission.
- **The streaming overlay can show the printer model** (#3080, requested and contributed by @adamspicedev in #3099 and #3134).
- **A second streaming overlay design, for portrait and landscape sources** (#3177, requested and contributed by @adamspicedev in #3183) - **Artwork: Version 2**; Classic stays the default.

**Accounts, integrations and the app itself:**

- **SSO group sync** (#3107, requested and contributed by @willuhmjs in #3122) - each OIDC provider gains a **Group Claim** and a **Group Mapping**, and the mapped Bambuddy groups follow the identity provider on every login, the same rule as LDAP group mapping.
- **Connected apps** - other applications can sign people in with their Bambuddy account (OAuth 2.0 authorization code with PKCE), registered under Settings → API Keys → Connected Apps. Requires authentication to be enabled.
- **Announcements from the Bambuddy maintainers, inside Bambuddy** - security fixes, breaking changes, releases and calls for testers, signed and fetched from GitHub. See **Before you update**.
- **An app shown in the sidebar can match Bambuddy's theme, and open a Bambuddy page in place** - the framed page is told the theme, and can ask Bambuddy to open one of its own pages. Both only for the link's own origin.
- **The API-key printer status carries layers, the job id, HMS faults and the serial** (#2919, requested by @simplytoast1) - additive; existing fields are unchanged.

**Changed**

- **The Slice dialog uses more of a large screen** - up to 1536 px wide, with a left column that grows with it.
- **A STEP preview says it is converting, and for how long** (#2976) - a large STEP file can take over a minute in the browser, and now shows a running counter instead of a spinner that looked stuck.
- **Leftover Web Push code and the unused `pywebpush` dependency are gone** (#3171).
- **The frontend build no longer warns about `path` and `crypto` for the STEP previewer** (#2976).

**Fixes**

**AMS slots, K profiles and drying:**

- AMS slots that lost their K profile after a printer restart stayed on the default K, and queued jobs printed with it (#3219). Bambuddy now restores a lost selection while the printer is idle and checks again right before a queued job is sent.
- A slot that read empty for one status update lost its spool assignment for good (#3186, reported by @Sawtaytoes).
- Orca Cloud filaments assigned to an AMS slot showed up in OrcaSlicer as Generic (#3216, reported by @mrnoisytiger).
- A drying command the AMS never started showed as an active cycle and could hold the queue forever (#2896, contributed by @M2ABRAMSTANK in #3096).
- Re-reading a slot's RFID reported success when the printer refused, and older firmware now gets the command it understands (#3206, reported by @Sawtaytoes).
- Filament printed from the external spool was deducted from an AMS spool (#3166; also #2880).

**Spools, inventory, Spoolman and SpoolBuddy:**

- In Spoolman mode, a spool's own size was ignored in favour of its filament's, so a 250 g spool was charged as if it held 1000 g (#3194, reported by @worried-networking).
- In Spoolman mode, weighing ignored the vendor's empty spool weight (#3195, reported by @worried-networking).
- A Spoolman spool's own empty spool weight was never saved (#2908, contributed by @ojimpo in #3011).
- "Reset usage to 0" on a Spoolman spool set it back to full (#2906, contributed by @ojimpo in #2939).
- A new Bambu Lab roll in Spoolman mode was linked to another product line of the same colour (#2907, contributed by @ojimpo in #2944).
- SpoolBuddy showed multi-colour and effect spools as one flat colour (#3033, reported by @Sawtaytoes).
- "Print labels…" ignored the spools you had ticked (#2980, reported by @apizz).

**Queue and dispatch:**

- A printer that refused uploads emptied the print queue: one P2S failed 43 jobs in ten minutes (#3210, reported by @Leander-Vh). Those jobs now stay queued and the printer is retried with a growing wait.
- The queue did not start jobs in the order shown when pinned and "Any <model>" jobs were mixed (#3200, reported by @bgrr74).
- A queued file whose only plate isn't plate 1 hung the printer (#2947, contributed by @sgiffhorn in #2951).

**Notifications and HMS:**

- The Reorder Alert and Stock Break Alert notifications were never sent (#2955, contributed by @ojimpo in #3196), and their toggles could never be turned on (#2945, regression tests contributed by @ojimpo in #2956).
- The Low Filament notification never fired (#2913, contributed by @ojimpo in #2940).
- Progress milestones sent 75% at the start of a print, and then never sent 25% or 50% (#3211, reported by @BurgerKerman).
- The `{finish_photo_url}` link in a notification failed when authentication was on.
- HMS faults now show Bambu's own description and the right level, and faults without published text no longer vanish (#2728, reported by @gzimbric).
- A print the printer's AI camera stopped for spaghetti was archived with no failure reason (#2946, contributed by @ojimpo in #2954).

**Camera and stream overlay:**

- A built-in camera could show the same old picture for hours while reporting a healthy stream (#3218, reported by @adamspicedev; also #3189, reported by @Sawtaytoes).
- A live camera view stopped for good after about half an hour on X1, H2 and P2 printers.
- The stream overlay's camera stayed frozen until its browser source was refreshed (#3205, contributed by @adamspicedev in #3213).
- Stream overlay and Cam Wall links stopped working after a reload, and signed the browser out (#3204, contributed by @adamspicedev in #3212).

**Login and directory:**

- LDAP group mapping found no groups on lldap and OpenLDAP, and StartTLS never worked with Active Directory or Samba AD (#3197, reported by @TOFM).
- Remember Me disappeared from the login page when only SSO sign-in was allowed (#2784, contributed by @vuthanhtrung2010 in #3117).

**File Manager and interface:**

- PDF previews failed on any browser older than Chrome 145 or Firefox 144 (#2976).
- The File Manager stopped 64 px short of the bottom of the window (#3215, reported by @koder-guy).
- Number fields could not be cleared and retyped (#3182, reported by @Carter3DP).
- Settings tabs lost their icons when a label was long (#3191, contributed by @Thomansky in #3192).
- Reading a 3MF's details loaded all of its geometry into memory.

**Install, platform and database:**

- Installing or updating ran out of memory on 2 GB machines, such as a standard Proxmox LXC or a 2 GB Raspberry Pi (#3181, reported by @PhilippeP62).
- PostgreSQL installs warned at every start that the connection pool may exceed the server. See **Before you update**.
- Turning off "Check printer firmware" did not stop every firmware lookup.
- Saving an empty value for a number setting through the API broke the Settings page until the database was fixed by hand. An affected install now recovers on its own.
- A P1P, P1S or X1E added by discovery was saved as the wrong printer.
- A connection check that overran in the support bundle discarded everything it had found (#3164).

**Security (dependencies)**

- `PyJWT` to 2.15.1 and `urllib3` to 2.8.0. Bambuddy's session tokens and SSO sign-in were not open to the PyJWT issues; the fixes for malformed tokens and key sets do reach SSO sign-in.
- `dompurify` to 3.4.16, for a low-severity advisory in a mode Bambuddy does not use.
- `js-yaml` to 5.4.2 and `brace-expansion` to 5.0.12, both development-only; neither is in the shipped image.

**Merged community PRs in this release**

- #2895 by @M2ABRAMSTANK - sustained humidity for ambient drying.
- #2939, #2940, #2944, #2954, #2956, #3011, #3196 by @ojimpo - Spoolman reset, empty-weight and product-line fixes, Low Filament and stock alerts, AI spaghetti failure reason.
- #2951 by @sgiffhorn - queued files whose only plate isn't plate 1.
- #2990, #2994, #2996, #3047, #3128, #3129, #3190, #3192 by @Thomansky - File Manager previews, material numbers, suppliers, outcome confirmation, library file details, Telegram reactions, Column view, Settings tabs.
- #2998 by @pd81 - spool ID search and assignment from the spool.
- #3096 by @M2ABRAMSTANK - parked AMS drying commands.
- #3099, #3134, #3183, #3212, #3213 by @adamspicedev - printer model and Version 2 design for the stream overlay, overlay links and camera recovery.
- #3117 by @vuthanhtrung2010 - Remember Me with SSO-only login.
- #3122 by @willuhmjs - SSO group sync.
- #3162 by @adman234 - Combine to 3MF.
- #3184 by @bgrr74 - filament on queue cards.
- #3199 by @bbbenji - camera snapshots for more notifications.

**Thanks**

To everyone who requested, reported, captured logs, or contributed: @adamspicedev, @adman234, @apizz, @bbbenji, @bgrr74, @BurgerKerman, @Carter3DP, @FedericoPuntelli, @frantiseklorenc, @gzimbric, @koder-guy, @Leander-Vh, @M2ABRAMSTANK, @Markus98, @mrnoisytiger, @ojimpo, @pd81, @PhilippeP62, @ryansouza, @Sawtaytoes, @SergioFuchs, @sgiffhorn, @simplytoast1, @Thomansky, @TOFM, @vuthanhtrung2010, @willuhmjs, @worried-networking.

---
**Sponsors**

Bambuddy is sustainable thanks to people who put their money where their use is. If this release saved you time or kept your farm running, the project runs on recurring contributions - there's no paid tier, no telemetry, no upsell, just sustainable maintenance.

- GitHub Sponsors (recurring, 5 tiers from $5/mo to $300/mo) - https://github.com/sponsors/maziggy
- Ko-fi (one-time or recurring) - https://ko-fi.com/maziggy

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
