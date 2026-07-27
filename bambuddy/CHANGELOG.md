## 1.2.5.1

**Bambuddy 1.2.5.1**

**What this is**

A follow-up to 1.2.5 with a round of fixes that didn't make it into that release. No new features, no breaking changes. Upgrading from 1.2.5 is safe and quick; one small database column addition (file modification times, #2680) is applied automatically on both SQLite and PostgreSQL.

If you are coming from 0.2.4.9 or earlier, read the 1.2.5 release notes first — all of its upgrade callouts (version-scheme change, tri-state calibration, Docker graceful shutdown, Postgres pool defaults) apply to you as well.

**Docker**

docker compose pull
docker compose up -d

**Native install — recommended path**

sudo BRANCH=main /opt/bambuddy/install/update.sh

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

Download bambuddy-1.2.5.1-windows-x64-setup.exe from this release page (or the unversioned bambuddy-windows-x64-setup.exe alias). Existing Windows installs upgrade in place via the in-app Install Update flow.

---
**Fixes**

**Dispatch and scheduling:**

- A printer's nozzle size could be overwritten to a wrong value (often 0.8mm) by a K-profile response, and since 1.2.5 that wrong value made the nozzle-mismatch guard refuse to dispatch — "sliced for 0.4mm, printer has 0.8mm" on a printer that really has a 0.4 (#2663, reporter @huykent). The K-profile path can no longer clobber the detected nozzle.
- Force color match dispatched onto the wrong PLA variant — a White PLA Matte job went to printers holding White PLA Basic or Silk, and to the wrong AMS slot on a printer holding two same-colour variants. Variant is now matched and the chosen slot pinned (#2650, reporter @MartinNYHC).

**AMS and filament:**

- An AMS-HT slot kept showing the removed filament and never cleared — the HT's presence bit lives at a different position in tray_exist_bits than regular AMS units; it is now read from the right place (#2670, reporter @needo37; follow-up to the #2594 fix in 1.2.5).
- The spool PA-Profil picker only ever offered the 0.4mm K-profile, hiding nozzle-specific profiles for the same filament on multi-nozzle printers. It now queries every installed nozzle and labels each profile with its nozzle diameter (#2618).
- The print dialog clipped the per-filament gram usage when the material name was long, especially on mobile (#2669, reporter @apizz).

**Queue:**

- The Print Queue's History tab showed a count of all prints but only ever displayed the first 50 — it now paginates with Show more (#2682, reporter @pchulpjoost).
- The queue couldn't be reordered on a phone: portrait hid the controls entirely and touch-drag didn't work in landscape. Mobile gets tap-to-reorder with up/down arrows (#2667, reporter @aporlebeke).

**Slicing and library:**

- A broken slicer sidecar behind a reverse proxy silently produced tiny corrupt files that were queued and printed anyway; invalid sidecar output is now rejected with a real error, and a proxy 413 explains itself (#2671, reporter @Austinzveare).
- 3D Preview plate thumbnails returned 401 in the File Manager when login was enabled (#2661, reporter @fbordonaro).
- File Manager "sort by recent activity" didn't match ls -t on external/NAS folders — sorting now uses the real filesystem mtime, recursively, and the file pane shows the modified date (#2680, reporter @Kingbuzz0; adds the auto-applied column mentioned above).
- Print-archive backups to a Gitea/Forgejo instance hosted under a URL path prefix (https://host/gitea/owner/repo) could not be configured — subpath repository URLs now parse (#2642, reporter @M1ndHunteR).

**Camera and privacy:**

- An external USB camera could stay locked (LED on) after closing the live view, blocking reopen — leaked ffmpeg processes are now reaped and /dev/videoN released (#2675, reporter @bitbarista).
- LDAP Distinguished Names (which carry the user's real name) are now redacted from the support bundle and bug reports, like emails already were (#2681, reporter @MaxBareiss).

**Security (dependencies)**

- Patched two build-time frontend dependencies flagged by npm audit: postcss 8.5.23 (source-map path traversal) and brace-expansion via the existing overrides block (GHSA-r28c-9q8g-f849, GHSA-mh99-v99m-4gvg).
- Pinned react-router to the most-patched 7.x (7.18.1), clearing 14 advisories carried by older 7.x releases. The one advisory still flagging 7.18.1 (a CSRF bypass) applies only to RSC mode, which Bambuddy does not use — it is documented as a fail-closed exception in the CI audit gate and drops automatically the moment a non-major fix ships.

---
**Sponsors**

Bambuddy is sustainable thanks to people who put their money where their use is. If this release saved you time or kept your farm running, the project runs on recurring contributions — there's no paid tier, no telemetry, no upsell, just sustainable maintenance.

- GitHub Sponsors (recurring, 5 tiers from $5/mo to $300/mo) — https://github.com/sponsors/maziggy
- Ko-fi (one-time or recurring) — https://ko-fi.com/maziggy

