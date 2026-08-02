## 1.2.5.2

**Bambuddy 1.2.5.2**

**What this is**

A maintenance release on top of 1.2.5.1, with a heavy focus on the camera, timelapse and finish-photo pipeline, plus the K-profile / Flow Dynamics screens. It also carries seven smaller features, five of them from outside contributors. No breaking changes. Two column additions (a per-VP AMS-mapping flag and a timelapse baseline on print archives) are applied automatically on both SQLite and PostgreSQL.

If you are coming from 1.2.5 or earlier, read the 1.2.5 release notes first — all of its upgrade callouts apply to you as well.

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

Download bambuddy-1.2.5.2-windows-x64-setup.exe from this release page (or the unversioned bambuddy-windows-x64-setup.exe alias). Existing Windows installs upgrade in place via the in-app Install Update flow.

**New**

- The print queue shows when each job would finish — a queue row carried the print duration but not the clock time it maps to. Rows that could actually start now show an if-started-now completion time, which updates as the clock moves (#2736, contributor @mpl1337).
- Keep the AMS slots the slicer picked — Bambu Studio and OrcaSlicer resolve which physical tray feeds each filament before sending, and Bambuddy threw that away and re-derived it at dispatch. A per-VP toggle now preserves the slicer's choice, and re-prints reuse it (#2700, contributor @Striker72rus).
- P2S / X2D accessory fans — the left auxiliary part cooling fan and the chamber exhaust fan now have tiles and controls (#2691, contributor @gzimbric, requested in #2660).
- Live print progress in the browser tab — enable Print progress in tab under Settings → Appearance and the tab title carries the running percentage (#2693, contributor @Chachigo, requested in #1041).
- Telegram notifications can target a forum topic — groups with Topics enabled no longer force everything into General; set a topic per provider (#1518, reporter @vmhomelab).
- Support bundles record Bambuddy's own memory, threads and child processes — the one thing a bundle never described was the process it came from, which made "memory climbs over days" reports impossible to act on after the fact (#2734).
- File Manager folder rows show last activity — the folder tree was sorting on a timestamp it never displayed (#2680 follow-up, reporter @cadtoolbox).

**Fixes**

**Camera, timelapse and finish photos:**

- External-camera timelapses and finish photos came out empty whenever the live view was open (#2707, reporter @bitbarista).
- A long-running camera stream could stall itself with nothing in the log, because ffmpeg's error output was only ever read after something had already gone wrong — so a full pipe blocked the process indefinitely (#2707).
- Reopening a camera quickly could leave the new stream running but unregistered, invisible to Bambuddy's own bookkeeping (#2707).
- Closing a camera held the printer's single camera connection for four more seconds and then logged an error that wasn't true (#2707).
- Two snapshots taken at the same moment opened two competing connections to firmware that allows exactly one (#2705, reporter @gzimbric); the same collision on external cameras, with no viewer attached, is fixed too (#2707 follow-up, reporter @bitbarista).
- A crash or restart mid-print left layer-timelapse frames behind forever — 38MB accumulated over routine test restarts (#2709, reporter @bitbarista).
- The orphaned-timelapse sweep could delete a timelapse while ffmpeg was still stitching it; the sweep margin and the stitch timeout were both 300 seconds, tied with no headroom (#2722, contributor @bitbarista).
- Camera credentials could reach the log and the support bundle from external-camera capture, and Test connection could report success for a frame it never fetched (#2721, contributor @bitbarista).
- Finish photos came out upside-down when a camera rotation was set — and, once that was fixed, double-rotated on the path that firmware without stg_cur=22 actually uses. The archived timelapse video is the printer's own file and is not re-encoded, so it still plays at the camera's native orientation (#2723, contributor @bitbarista).
- The print-complete photo caught the toolhead still printing, up to three minutes before the print ended (#2547, reporter @anthonyma94).
- Timelapses that never got attached, and a Scan for Timelapse button that could not find them. Measured across 247 support bundles, only 262 of 457 automatic scans ever attached a video (#2704).
- P1-series archives kept the worse finish photo when the timelapse arrived after the 60-second wait (#2704 follow-up).

**K-profiles and calibration:**

- Every K-profile reported 0.4mm and a flow type nobody set, on any printer running a different nozzle, and the same profile disagreed with itself between the list and the edit dialog (#1748, reporters @Liquidmasl and @jmoore-skild).
- Fetching profiles for two nozzle sizes at once made the first request time out, even though the printer answered both correctly (#1748).
- A rejected K-profile write reported success — the command was fire-and-forget, and the printer's refusal was received, matched and discarded (#2718, reporter @jmoore-skild).
- A printer with no K-profiles could not be given its first one: the Filament dropdown was built from profiles already on the printer, so the required field was impossible to satisfy (#2719, reporter @jmoore-skild).
- A slot on Generic PLA offered one K profile however many the printer held — nine, in the reported case (#2710, reporter @tommyboy180).
- The Flow Type field is a real choice again instead of an unsaveable "Not reported by printer".
- The AMS slot and K-Profile dialogs no longer act after they have closed.

**Printers, connection and dispatch:**

- A printer refusing every control command looked healthy: the HMS code carrying "MQTT command verification failed" collapsed to a form that matched no catalog entry and was filtered out, while the Developer Mode probe read a non-answer as confirmation. The queue then failed with advice about SD cards (#2732, reporter @hennischd).
- A printer that lost its MQTT session to a keep-alive timeout could stay offline indefinitely — nine hours, in the reported bundle, with the UI open throughout (#2732, reporter @hennischd).
- A printer refusing Bambuddy's access code now says so, instead of reconnecting silently forever behind a warning indistinguishable from a powered-off printer (#2698, reporter @djepsylon).
- The layer count stayed empty for a whole print and First Layer Complete notifications read 1/0 on P1S jobs started from Archives or the Virtual Printer (#2702, reporter @sn8key).
- A non-numeric layer number from a printer could drop its connection entirely (#2702 follow-up).
- A database hiccup mid-dispatch could leave a queue item stuck and file the next print of that file under the wrong archive.

**Slicing and projects:**

- A heavy model failed after five minutes with "Slicer sidecar unreachable" — the timeout bounded total slicing time rather than silence (#2730, reporter @kpp39).
- A model sliced for PETG printed as PLA, and the print dialog then refused to match PETG (#2712, reporter @kpp39).
- One finished slice produced a dozen "Sliced ..." notifications, one every 1.5 seconds for up to twenty seconds.
- Deleted prints stayed in their project as cards with broken previews, with no way to remove them (#2731, reporter @sroesner).

**Settings, backup and API:**

- The Settings page reverted settings changed anywhere else — a second tab, another user, a backup restore — writing its page-load copy back over all 77 settings it manages, and showing Settings saved while doing it (#2716, reporter @jmoore-skild).
- Git backup with Cloud Profiles enabled wrote nothing at all (#2717, reporter @jmoore-skild).
- PUT /settings/spoolman returned a 500 for the natural JSON form of a switch. Only affected scripted callers and Home Assistant rest_command users; the shipped UI always sends strings.
- Support bundles could contain a printer-status file no tool could open (#2702).

**Cloud, Virtual Printer and interface:**

- Bambu Cloud sign-in with a TOTP account always failed with "Invalid code" — Bambu Lab added CSRF protection to the web origin and the endpoint refused the request before evaluating the code at all (#2696, reporter @cmerkle).
- A2L AMS filament showed as "?" in Bambu Studio through the Virtual Printer, and manual filament picks reverted once a second (#2697, reporter @qoatzelcoat).
- Auto-matched filament showed a green tick when the colour was plainly wrong — dark red matched against Dark Green (#2687, reporter @pchulpjoost).
- Ukrainian is listed after Russian in the language picker.

**-Sponsors**

Bambuddy is sustainable thanks to people who put their money where their use is. If this release saved you time or kept your farm running, the project runs on recurring contributions — there's no paid tier, no telemetry, no upsell, just sustainable maintenance.

- GitHub Sponsors (recurring, 5 tiers from $5/mo to $300/mo) — https://github.com/sponsors/maziggy
- Ko-fi (one-time or recurring) — https://ko-fi.com/maziggy

