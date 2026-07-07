## 0.2.4.9

**Bambuddy 0.2.4.9**

**⚠ Upgrade Notes — Read Before Updating**

0.2.4.9 is a fix-and-polish release on the same 0.2.4 code base — no schema breaks beyond auto-migrated column additions (dialect-branched for SQLite and Postgres), no Docker entrypoint changes. The in-app Apply Update button in Settings → System → Updates works for Docker and for any native install already on 0.2.4.x.

**Four behaviour-change callouts to know about before you upgrade:**

- Plate-clear confirmation now correctly defaults to OFF (#1865, reported by @PurseChicken). On installs that never explicitly saved the "Require plate-clear confirmation" setting, the scheduler was still enforcing the plate-clear gate even though the toggle and the printer card showed it disabled — so a queued print could sit "Waiting" forever on a FINISH-state printer with no UI control to release it. The scheduler now reads the setting with the same default the schema and UI use, so a finished printer dispatches the next queued job automatically. If you were relying on that gate to hold the queue until you physically clear the bed, explicitly turn on Require plate-clear confirmation after upgrading — the "Mark plate as cleared" button and plate badge reappear on the card when it's on.
- File Manager "All Files" now scopes to your own uploads. The sidebar's All Files entry now shows the files you uploaded; a new "External" entry holds the combined linked-folder view that used to be mixed in. If you were used to seeing linked-folder content under All Files, it's now one entry down under External — no data moved, just the sidebar grouping.
- Slicer sidecar now ships as pre-built images (#1657). The slicer-API sidecar is now published on GHCR and Docker Hub, so it runs on QNAP / Synology / Container Station out of the box without a local build. If you run the sidecar, pull the published image instead of building; the wiki sidecar instructions are updated.
- Light theme contrast overhaul (#1909, reported by @AntonPalmqvist). If you run the light theme, a large number of previously washed-out status banners, badges, and form fields are now readable. Dark theme is pixel-identical.

Make a backup before upgrading via Settings → Backup → Create Backup. Native install with update.sh snapshots the database automatically and rolls back on failure. Docker and fully-manual paths don't.

Docker

docker compose pull
docker compose up -d

docker-compose.yml doesn't need refreshing for 0.2.4.9.

Native install — recommended path

sudo BRANCH=main /opt/bambuddy/install/update.sh

Snapshots the database first and rolls back on failure.

Native install — manual path

sudo systemctl stop bambuddy
cd /opt/bambuddy
sudo -u bambuddy git fetch --prune --tags --force origin
sudo -u bambuddy git checkout main
sudo -u bambuddy git reset --hard origin/main
sudo /opt/bambuddy/venv/bin/pip install -r requirements.txt
cd frontend && sudo npm i
sudo systemctl start bambuddy

Windows install

Download bambuddy-0.2.4.9-windows-x64-setup.exe from this release page (or the unversioned bambuddy-windows-x64-setup.exe alias for an always-latest link). This release fixes a fresh-install failure where the service reported "running" but nothing listened on port 8000 (#2474) — a missing C++ runtime DLL that greenlet needs is now bundled. Existing Windows installs upgrade in place via the in-app "Install Update" flow.

---
**Highlights**

0.2.4.9 is a stabilisation release — the headline is install robustness on Windows and macOS, a light-theme contrast pass, and a scheduler fix that could silently freeze queues.

The plate-clear scheduler fix (#1865, reported by @PurseChicken) is the one to know about: on installs that never explicitly saved the setting, a FINISH-state printer would never dispatch the next queued job even though the "Require plate-clear confirmation" toggle showed as off — see Upgrade Notes.

Install paths got hardened on both new platforms: the Windows .exe no longer starts a dead service on a clean Win10 box (#2474, @fangme), and the macOS native install is now fully rootless (no more Homebrew/venv permission failures) with a fixed Virtual Printer bind-interface list.

Smaller-but-useful: native CSV import / export on the inventory page (#1576, PR by @samedyuksel), custom-subnet printer scan for printers behind a different L3 segment (#1564, @MartinNYHC), thermal-printer-friendly spool-label QR codes with a black-and-white monochrome option (#1870, @fireboyff / @Geoff-S), and a finish photo that no longer catches the bed already dropping away (#1397).

---
**New Features**

- Inventory page now supports native CSV import / export (#1576, PR #1659 by @samedyuksel).
- Spool labels: scannable QR on 203 dpi thermal printers + monochrome mode for black-and-white printers (#1870, reported by @fireboyff, monochrome requested by @Geoff-S).
- Add Printer: scan a custom subnet for printers behind a router on a different L3 segment (#1564, reported by @MartinNYHC).
- Orca Cloud profile sync — end-to-end integration with the slicer + SpoolBuddy surfaces.
- Finish photo no longer shows the bed already dropped (#1397, reported by @rtadams89, @Jeff-GebhartCA, @MA2ZAK).
- Connection diagnostic now verifies the printer is actually publishing on its report topic (#1622).
- Virtual Printer MQTT bridge now surfaces why a net.info[].ip rewrite didn't arm (#1429, defensive diagnostics).

---
**Changes**

- Slicer sidecar now ships as pre-built images on GHCR + Docker Hub — install works on QNAP / Synology / Container Station without a local build (#1657). See Upgrade Notes.
- File Manager sidebar: "All Files" now scopes to your own uploaded files; a new "External" entry holds the combined linked-folder view. See Upgrade Notes.
- Empty AMS units no longer trigger hourly humidity / temperature notifications (#1619).
- AMS drying now enabled for H2C starting at firmware 01.02.00.00.
- Virtual Printer access code is now auto-derived from the target printer in non-proxy modes.
- Inventory: /reset-usage renamed to /reset-consumed-counter; the UI label is now "Reset counter".
- docker-compose.yml: added a bridge-mode warning about the 1001-port FTP passive range + docker-proxy RAM footprint (#1646).

---
**Fixed**

Print queue + scheduler

- Queued prints never dispatched to FINISH-state printers when "Require plate-clear confirmation" was disabled (#1865, reported by @PurseChicken). See Upgrade Notes.

Connection / camera

- External camera "connection lost" when the snapshot URL serves a non-JPEG image — snapshots are now transcoded to JPEG (#1902).
- Virtual Printer "bind interface" dropdown was empty on macOS — interface enumeration now routes non-Linux platforms through psutil.

Install / backup

- Windows installer: fresh install failed to start ("connection refused", nothing on port 8000) — the C++ runtime DLL greenlet needs is now bundled (#2474, reported by @fangme).
- Native install script failed on macOS with Homebrew/venv permission errors — the macOS path is now fully rootless.
- PostgreSQL restore from a SQLite backup no longer deadlocks against the print scheduler.

UI / rendering

- Light theme: low-contrast washed-out text on status/warning banners, badges, and form fields, app-wide (#1909, reported by @AntonPalmqvist).
- Sponsor toast ignored its 14-day cooldown and re-fired on every fresh browser session (#2477, reported by @pchulpjoost).

---
**Security**

- idna: bumped to >=3.15 to clear CVE-2026-45409 (ReDoS in idna.encode() with crafted Unicode input).

---
**Contributors**

External code contributors with merged PRs in this release: @samedyuksel (#1659 — native CSV import / export on the inventory page). Thank you!

The reporters who drove the fixes in this release are credited inline next to each entry above.

---
**Sponsors**

Bambuddy is sustainable thanks to people who put their money where their use is. If this release saved you time or kept your farm running, the project runs on recurring contributions — there's no paid tier, no telemetry, no upsell, just sustainable maintenance.

- GitHub Sponsors (recurring, 5 tiers from $5/mo to $300/mo) — https://github.com/sponsors/maziggy
- Ko-fi (one-time or recurring) — https://ko-fi.com/maziggy

