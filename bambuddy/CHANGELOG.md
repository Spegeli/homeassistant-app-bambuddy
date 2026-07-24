## 1.2.5

**Bambuddy 1.2.5**

**⚠ Upgrade Notes — Read Before Updating**

**About the version number.** This is the successor to **0.2.4.9** — the first digit moved from **0** to **1** (0.2.5 became 1.2.5). It is a normal next release on the same code base, not a rewrite; the jump in the leading digit is only a versioning-scheme change. The in-app Apply Update button in Settings → System → Updates works for Docker and for any native install already on the 0.2.x line.

1.2.5 folds in the whole beta cycle, so it is a large release. There are no breaking schema changes beyond auto-migrated column additions (dialect-branched for SQLite and Postgres), and every migration was run against both engines.

**Behaviour-change callouts to know about before you upgrade:**

- **Bed levelling, flow calibration, and nozzle-offset calibration are now three-way Off / Auto / On, and new prints default to Auto.** This matches Bambu Studio (Auto lets the printer skip a calibration it did recently). Your existing queued prints and saved workflow defaults are migrated automatically — anything that was "on" becomes "On (force)", anything "off" stays "Off" — so nothing changes for in-flight jobs until you opt into Auto.

- **Docker now shuts down gracefully.** Previously every docker stop / restart / image update was a SIGKILL after the full grace period — no WAL checkpoint, no MQTT disconnect, no clean teardown. That is fixed (uvicorn is now PID 1 and receives the signal). To also pick up the raised stop grace period, refresh your docker-compose.yml (it now sets stop_grace_period: 30s). systemd/launchd/Windows launchers get the equivalent timeout automatically via the installer.

- **Multi-printer farms dispatch far faster.** Uploads to different printers now run concurrently (new Settings → Workflow → Queue & Dispatch → Concurrent Uploads, default 4, up to 16 — set it to 1 for the old strictly-serial behaviour), and the scheduler re-ticks within seconds after a productive pass instead of waiting a fixed 30 s. A stuck printer is now failed after three attempts instead of retried forever.

- **PostgreSQL pool defaults raised and made configurable.** The pool is now 20 + 80 (100) by default with DB_POOL_SIZE / DB_MAX_OVERFLOW / DB_POOL_TIMEOUT / DB_POOL_RECYCLE overrides, plus a GET /api/v1/system/db-pool gauge. If you run a large farm on Postgres, review your server's max_connections headroom — see the PostgreSQL wiki page.

- **Bambu Cloud sign-in state is now honest.** A lapsed token is properly detected instead of showing "Connected" forever, and a single stray 401 no longer signs you out. If you linked your Bambu account before enabling authentication (or crossed an auth on/off transition on an older build), you may need to re-link once from the Profiles page.

- **Manual jog safety (Bambu firmware bug).** Bambu firmware does not enforce its soft endstops on G-code received over MQTT, so manual jog can overrun a travel limit. Bambuddy no longer disables the endstops globally around a jog (which previously also broke the touchscreen's limits until a power-cycle) and now shows a prominent warning on the jog panel. If your printer currently overruns even from its own touchscreen, power-cycle it once to restore the endstops an older Bambuddy build disabled.

- **P1S / P1P AMS drying is screen-only.** P1 firmware acks drying commands and discards them, so Bambuddy no longer offers Start/Stop for P1 drying — the flame button stays visible but disabled with an explanation. A cycle started at the printer still shows its live countdown.

- **REST smart-plug energy (Shelly users).** If your Energy JSON Path points at a cumulative lifetime counter (anything from a Shelly does), move it to the new Energy JSON Path (lifetime) field so Today/Yesterday/Total populate correctly.

- **Re-take your backups after upgrading.** A Postgres → SQLite backup export previously dropped NOT NULL / DEFAULT / FK / UNIQUE; that is fixed, but backups taken on an older build still carry the degraded schema.

- **Stats.** Reconciled-after-reconnect prints no longer inflate Total Print Time by hundreds of hours. Rows already inflated by the old bug are not auto-corrected (they're indistinguishable from real cancellations) — repair them by hand if needed.

Make a backup before upgrading via Settings → Backup → Create Backup. Native install with update.sh snapshots the database automatically and rolls back on failure. Docker and fully-manual paths don't.

**Docker**

    docker compose pull
    docker compose up -d

Refresh docker-compose.yml if you want the new stop_grace_period: 30s (recommended, so a slow teardown on a Pi isn't clipped).

**Native install — recommended path**

    sudo BRANCH=main /opt/bambuddy/install/update.sh

Snapshots the database first and rolls back on failure. Also carries any custom ReadWritePaths you added (e.g. for NAS backups) forward into the new systemd unit.

**Native install — manual path**

    sudo systemctl stop bambuddy
    cd /opt/bambuddy
    sudo -u bambuddy git fetch --prune --tags --force origin
    sudo -u bambuddy git checkout main
    sudo -u bambuddy git reset --hard origin/main
    sudo /opt/bambuddy/venv/bin/pip install -r requirements.txt
    cd frontend && sudo npm i
    sudo systemctl start bambuddy

**Windows install**

Download bambuddy-1.2.5-windows-x64-setup.exe from this release page (or the unversioned bambuddy-windows-x64-setup.exe alias for an always-latest link). Existing Windows installs upgrade in place via the in-app Install Update flow.

---

**Highlights**

1.2.5 is a big release that lands several long-requested features on top of a large stability and farm-scale correctness pass.

**New surfaces:**

- **Slicer Pipelines** — save a printer/process/filament/bed-type bundle once and dispatch it with a click. Full production-batch semantics: multi-copy runs, printer-class targeting, three fan-out strategies (max parallel / round robin / fill one first), a runs dashboard with cancel and retry-failed, and live updates (#1425).

- **Cam Wall** — a full-page grid of live camera tiles on the Printers page, with a per-tile print-status overlay, a bookmarkable /camwall URL, and a purpose-built read-only kiosk token for a lobby TV that exposes no serial, IP, or filename (#2531).

- **HMS error actions** — the error dialog goes from read-only to actionable: Resume / Stop / Ignore / Check Assistant and the rest now send the matching command to the printer, so you no longer have to walk to the machine to clear a pause (#1743, #1830).

- **AMS Filament Backup** — read and toggle the printer's auto-switch-to-a-second-spool state right from the card, and a paused runout now names the exact physical slot the printer is waiting for (#2587).

**Farm and stability:**

- Prints on a multi-printer farm no longer start one-by-one up to an hour apart — uploads run concurrently and the scheduler re-ticks as printers free up (#2555).

- A sustained session-hygiene and pool-sizing pass stops PostgreSQL connection-pool exhaustion on large farms, where camera streams, FTP work, and 3MF parsing had been holding DB connections across slow I/O (#2572, #2573).

- Docker finally shuts down cleanly instead of being SIGKILLed on every stop, and a run of multi-plate dispatch bugs that could map the wrong filament, log the wrong plate, or split a dispatch across two printers are fixed (#2551, #2552, #2603, #2614, #2615).

**Smaller-but-useful:** batch/mass edit on the Filament tab (#1795), structured storage-location and user-tag catalogs plus recursive search and per-folder README panels in the File Manager (#1505, #1268), continue-drying-while-printing on capable hardware, a dedicated AI Failure Detection notification event (#1794), sort Printers by ETA
(#1609), admin-configurable session lifetime (#1706), a full Russian translation (#2608, 11 languages total), and much more below.

---

**New Features**

Slicer Pipelines (#1425):
- Save and reuse a preset bundle in one click from the Slice modal (PR A).
- Run a pipeline on a file (library or archive) with one click, with pre-flight eligibility and a progress toast (PR B).
- Multi-copy batches, printer-class targeting, three fan-out strategies, a runs dashboard with cancel/retry-failed, and live WebSocket updates (PR C — completes the v3 design).

Cam Wall (#2531):
- Cam Wall view on the Printers page — a responsive grid of live camera tiles with on-screen/live-budget scheduling so it stays sustainable on a Pi.
- Per-tile print/printer status overlay (Off / Compact / Full).
- Bookmarkable /camwall URL plus a purpose-built read-only kiosk token that serves only what a tile draws — no serial, IP, access code, or filename.

Printer control and status:
- HMS error actions on the dashboard — Resume / Stop / Check Assistant etc. now send the matching MQTT command (#1743, contributed by @Ichicoro).
- AMS Filament Backup status + control on the printer card, read from the print.cfg bit and toggled over MQTT.
- A paused AMS runout now names the physical slot the printer is actually waiting for, with a pulsing highlight on the AMS graphic (#2587).
- AMS drying badge shows the active cycle's filament and target temperature.
- Live print progress for Virtual Printers in Bambu Studio / OrcaSlicer while keeping the Send button enabled (#1887).

Inventory:
- Batch / mass edit on the Filament tab — bulk edit / print labels / reset usage / archive / delete across both built-in and Spoolman modes (#1795).
- Structured storage-locations catalog (shelves, drawers, dryboxes) with Spoolman parity (#1505, closing #1004, contributed by @Poltavtcev).
- By-tag spool lookup readable with a Manage-Inventory API key, for scanner-driven integrations (#1700 closing #1663, contributed by @bambuman).
- Spoolman weight tracking for no-3MF "Untitled" prints, closing a parity gap with built-in inventory (#1820).

File Manager (#1268):
- User-authored tags for cross-cutting file filtering, independent of folders.
- Recursive search inside the selected folder, and a per-folder markdown README panel (collapsible right-hand rail).
- Page-wide drag-and-drop upload (#1510), and sort the folder tree by recent activity (#1770).

Drying:
- Continue auto-drying while a print is running, on capable hardware (opt-in, temperature-capped).

Notifications:
- Dedicated "AI Failure Detection" notification event so Obico detections stop riding the multiplexed Printer Error toggle (#1794).
- Inline finish-photo embed in failure-event emails via the {finish_photo_url} template variable, plus user_print_* template disambiguation (#1792).

Accounts, API keys, and layout:
- QR code on API-key creation that encodes server URL + key together for one-scan mobile setup (#1677, contributed by @bambuman).
- Admin-configurable session lifetime (24h / 7d / 30d, default 24h) (#1706).
- Centralised sidebar layout with per-page hide toggles and an admin default order (#1673, contributed by @EdwardChamberlain).
- Per-VP G-code injection toggle for Studio Send / FTP uploads (#1516, contributed by @phieb).

Other:
- Slice as designed — keep a MakerWorld author's own embedded settings when slicing server-side, when your printer matches the design's target (#2611).
- Sort the Printers page by ETA (#1609).
- Unified print dispatch through the queue scheduler, so every print is queueable, cancellable, and attributable (#1625, by @EdwardChamberlain).
- Sticky upload-progress toast restored for scheduler-driven dispatch (#1625 follow-up).
- Sponsor surfaces now ask a print farm (5+ printers) a commercial question instead of the hobbyist donation ask.
- Russian (Русский) UI translation — 11 languages total (#2608, contributed by @pterodaktil02).
- Appliance endpoints for NTP-gate state and locale/hostname/timezone defaults.

---

**Fixed**

Dispatch, scheduler, and farm scale:
- Prints on a multi-printer farm started one-by-one, up to an hour apart — uploads now run concurrently (#2555).
- A printer that accepted a file but never started was retried forever — now failed after three attempts (#2555).
- Every job waited up to 30 s after a printer freed up — the scheduler now re-ticks fast after a productive pass (#2555).
- PostgreSQL connection-pool exhaustion on large farms, plus a sustained session-hygiene pass so camera streams, cover/snapshot/timelapse, the print-start and finish-photo handlers, notification snapshots, FTP helpers, and SMTP no longer hold a DB connection across slow I/O (#2572).
- Startup connected printers serially (~100 s to first response on a 93-printer farm) — now concurrent (#2572).
- Queue polling re-parsed every 3MF on each poll — now a single combined parse cached by file revision (#2573).
- Large prints uploaded twice at once and never landed — deadline now scales with file size and actually cancels a too-slow transfer, with a per-printer upload lock (#2529).
- queue_max_concurrent_uploads behaved as a per-batch cap instead of a refillable pool (#2602).
- Reassigning a queue item mid-dispatch split it across two printers (#2615), a start dispatched to an already-busy printer could cancel the running job (#2598), and an unresolved AMS mapping silently dispatched to the empty external spool (#2589).

Multi-plate and filament mapping:
- Skip Objects listed the wrong plate's objects (#2522), and single-plate object lists could crash dispatch.
- Queueing several plates of one file mapped them all through the first plate's filaments (#2551), Filament Override vanished for a multi-plate selection (#2552), and Force color match made every plate wait for every colour (#2551).
- A single plate of a multi-plate 3MF recorded the whole file's filament in statistics (#2614), and multi-plate queue prints lost the selected plate in Print History (#2603).
- A print mapped to a different filament than it was sliced for was logged under the sliced material, not the one used (#2563).
- Multi-nozzle prints no longer collapse all filaments onto one nozzle (#1825), and nozzle sizes other than 0.4 mm are fully supported in the AMS slot picker + a pre-dispatch guard (#1899).

AMS and filament:
- A2L "AMS Lite" slots showed empty and never deducted filament (unit id 16 normalisation).
- The HT-A (AMS-HT) spool vanished a few seconds after power-on (#2594).
- External spool kept its old inventory filament after a type change (#2575), and configuring a built-in/generic filament reverted a moment later (#2604).
- An AMS slot with a non-Bambu (no-RFID) spool showed "Empty" instead of "?" (#2527), and the drying "Rotate spool" toggle is no longer offered when a tray is threaded out.

Camera:
- P1/A1 camera stayed black on load until a ~20-minute self-heal — late-subscriber priming + teardown discipline (#2521, #2521 follow-ups).
- Cam Wall no longer kills shared streams when one viewer closes, and offline tiles show OFF rather than LIVE.
- P2S RTSP timeout could leave the fan-out stream permanently stalled (#2580, diagnosed by @ronaldheft, fix shape from PR #2581).

Cloud, MakerWorld, and connectivity:
- Bambu Cloud dropped to "sign-in expired" and forced constant re-logins (any-401 now narrowed to the documented token-expiry response) (#2530-related, and the #2562 follow-up).
- Enabling authentication silently disconnected Bambu Cloud — the token now migrates onto the admin (and back) across the auth transition (#2530).
- "Please login." during MakerWorld import while showing Connected — cloud status is now authoritative.
- MakerWorld import on Windows failed with a certificate error (S3 hop now verifies against certifi) (#2562).
- MakerWorld import/resolve/status failed under API-key auth even with a valid owner cloud login (#1777).
- H2C prints intermittently recorded no filament — the H2C now gets the TLS 1.2 FTP profile (#2582), and H2C prints now deduct from inventory (#2582).

Shutdown and launchers:
- Docker never shut down gracefully — every stop/restart/update was a SIGKILL (exec uvicorn as PID 1).
- systemctl restart could hang 90 s and end in SIGKILL when a camera stream was open — every launcher now bounds the graceful-shutdown wait.

Smart plugs and energy:
- Energy Summary stuck at zero for Yesterday and Total on REST smart plugs, plus the whole smart-plug subsystem was broken on Postgres (naive-vs-aware datetimes) (#2539).
- Switching off an accessory smart plug at print end knocked the printer into "Unknown" and stalled the queue — plugs now carry a "Powers the printer" flag (#2629).

Other fixes:
- Reconnect/restart inflated Stats → Total Print Time by hundreds of hours (#2592).
- Scheduled backups to a NAS failed with EROFS because of our own systemd ProtectSystem sandbox — installers now carry custom ReadWritePaths forward and the UI diagnoses the real cause (#2544).
- Postgres → SQLite backup dropped NOT NULL / DEFAULT / FK / UNIQUE (#2526).
- Every SpoolBuddy screen crashed when a text field was focused (CJS interop) (#2616).
- The streaming overlay (/overlay) was blank in OBS with login enabled — now a token-authenticated kiosk surface (#2613).
- The AMS slot popup covered the filament dialog it opened, on touch devices (#2631).
- Slicing a single plate failed on a filament slot the plate doesn't use, and a profile could be auto-picked for a printer it doesn't belong to (#2628 and follow-up).
- Pushover Emergency priority (2) was rejected by the API (#2586); progress notification ran off-screen in the iPhone PWA (#2612).
- "Remember Me" appeared broken — an authenticated visit to /login now redirects (#1889).
- Packaging floors that permitted un-runnable resolutions: FastAPI < 0.116 204-route crash, sqlalchemy floor raised to 2.0.38, ruff pinned exactly; printer FTPS/MQTT now declare a TLS 1.2 floor explicitly.

(This is a condensed list — see CHANGELOG.md for the full detail on every entry, including tests and scope.)

---

**Security**

- Bumped linkify-it and dompurify to their patched releases (both build/production-tree hygiene; neither reachable path was exposed).
- Raised the Docker image's pip floor to 26.1.2 (PYSEC-2026-196) — build tooling only.
- Bumped two frontend dev-tooling dependencies (brace-expansion, js-yaml) with denial-of-service advisories — lint/build-time only, not in the shipped app.

---

**Merged community PRs in this release**

Thank you to everyone who contributed:

- #1625 @EdwardChamberlain — Unify print dispatch through the scheduler
- #1743 @Ichicoro — HMS error actions
- #1673 @EdwardChamberlain — Centralised sidebar ordering + page visibility
- #1516 @phieb — Per-VP G-code injection toggle
- #1700 @bambuman — By-tag spool lookup for Manage-Inventory keys (#1663)
- #1677 @bambuman — QR code on API-key creation
- #1505 @Poltavtcev — Structured storage locations catalog (#1004)
- #2608 @pterodaktil02 — Russian localization
- #2596 @Sawtaytoes — Virtual Printer "Any [model]" dispatch diagnosis (#2595)
- #2581 @ronaldheft — P2S RTSP stream-timeout fix shape (#2580)

---
**Sponsors**

Bambuddy is sustainable thanks to people who put their money where their use is. If this release saved you time or kept your farm running, the project runs on recurring contributions — there's no paid tier, no telemetry, no upsell, just sustainable maintenance.

- GitHub Sponsors (recurring, 5 tiers from $5/mo to $300/mo) — https://github.com/sponsors/maziggy
- Ko-fi (one-time or recurring) — https://ko-fi.com/maziggy

