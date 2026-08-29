## 1.2.5.4

**Bambuddy 1.2.5.4**

**What this is**

A fix-heavy release on top of 1.2.5.3, with one substantial feature running through it: a spool now carries a different filament preset per printer model and a K profile per hotend, and every path that configures an AMS slot honours both. Around that sit scheduled AMS drying, Filament Track Switch support, Dutch as the fourteenth interface language, Home Assistant sensors bound to storage locations, and roughly 90 fixes - the heaviest runs on AMS and K profiles, on archives from prints Bambuddy did not dispatch, and on Spoolman cost attribution. Seven of the changes come from outside contributors. No breaking changes. Three new tables, one new column and six one-shot repair passes are applied automatically on both SQLite and PostgreSQL.

If you are coming from 1.2.5 or earlier, read the 1.2.5 release notes first - all of its upgrade callouts apply to you as well.

**Docker**

docker compose pull
docker compose up -d

**Native install - recommended path**

sudo BRANCH=main /opt/bambuddy/install/update.sh

**Native install - manual path**

sudo systemctl stop bambuddy
cd /opt/bambuddy
sudo -u bambuddy git fetch --prune --tags --force origin
sudo -u bambuddy git checkout main
sudo -u bambuddy git reset --hard origin/main
sudo /opt/bambuddy/venv/bin/pip install -r requirements.txt
cd frontend && sudo npm i
sudo systemctl start bambuddy

**Windows install**

Download bambuddy-1.2.5.4-windows-x64-setup.exe from this release page (or the unversioned bambuddy-windows-x64-setup.exe alias). Existing Windows installs upgrade in place via the in-app Install Update flow.

**New**

- A spool carries a filament preset per printer model, and a K profile per hotend - A slicer preset is bound to a printer model: `Bambu PLA Basic @BBL X1C` is not the same preset as `@BBL H2C`. A spool stored exactly one, which was right until you used that spool on a second machine - the AMS slot on the other printer was then configured with a preset it has no profile for. The spool form's PA Profile tab becomes a **Printers** tab holding both halves: a model list on the left, and on the right that model's presets and the K profiles for each of its hotends. K profiles also distinguish High Flow from Standard nozzles, because a printer files each calibration under a nozzle id like `HH00-0.4` or `HS00-0.4` and can hold both for one diameter - a maintainer's H2D carries 102 high-flow entries and 6 standard, and the same filament reads a different K through each. A stored profile is no longer applied when the fitted nozzle disagrees; the picker marks it rather than letting it look configured while quietly doing nothing. Every path that configures a slot respects both: manual assign in either inventory mode, RFID auto-assign, the Spoolman tag link, the re-fire when a slot goes from empty to loaded, the re-apply after a calibration-table refresh, and the re-selection when a Filament Track Switch moves an AMS to the other nozzle.

- Filament Track Switch: the inlet each AMS feeds, and K profiles that follow it - With a switch fitted an AMS is not wired to a nozzle. It is plumbed into one of the swi
tch's two inlets and reaches both hotends through it, so every unit reports its extruder as "not fixed" and `ams_extruder_map` comes back empty. Bambuddy had nothing to fall back on but the AMS unit number, so AMS-A was badged R and AMS-B was badged L purely because their ids are 0 and 1, a third unit got no badge at all, and every one of those labels was wrong. The inlet is now read from the switch, and a print asks which nozzle to feed rather than guessing.

- Scheduled AMS drying (#2703) - A drying run can start now, after a delay, or at a chosen time, and the printer's queue is held while it runs. The delayed dispatch goes through the same preflight the immediate button does, so a run the button would refuse is never silently published by the schedule; the blocking firmware reason is chosen by one shared rule, so a blocked AMS no longer reads two different ways depending on which control you pressed. A completed or cancelled run releases the printer - without that, a nightly off-peak dry with no printing in between worked on night one and silently did not on every night after. Pending and failed runs are shown on the printer card.

- Dutch (nl) is now a supported interface language (#2891, requested and contributed by @Igiegel) - the fourteenth locale, listed as "Nederlands" in the language picker.

- Home Assistant sensors can be bound to a storage location, so a drybox reports its own humidity (#2824) - the sensor readings you already surface on a printer card can now be attached to a shelf, drawer or drybox instead.

- An Avery sheet can start at the first unused position (#2879, requested and contributed by @whitigol in #2918) - label PDFs always began in the top-left slot, so printing two labels onto a part-used 30-slot sheet meant spending the whole sheet or nothing. A **Starting label position** field says which slot to begin at, counted the way the sheet reads.

- A fault's description is in the status response (#2926, proposed and analysed by @sadontsev) - `HMS_ERROR_DESCRIPTIONS` has been in the backend all along and the status response never carried it, so every consumer that wanted to tell a user *why* a print halted kept its own copy of the same 853 codes: this repo's Python table, the frontend modal's, and at least one third-party iOS client whose catalogue exists purely because the server would not say.

- A virtual printer can be told which address to advertise (#2930, reported and diagnosed by @sebimarkgraf) - `VIRTUAL_PRINTER_ADVERTISE_ADDRESS` sets the address written into the MQTT status that slicers read their FTP upload destination from. On Docker bridge networking the virtual printer is reached on the host's LAN IP but binds something like `172.24.0.2`, and that private address was what the slicer got.

- Printer file downloads can be selected in ranges, and print-history videos downloaded (#2850, requested and contributed by @logikal in #2853) - large selections are prepared on the app data volume rather than buffered in server and browser memory, with per-file compression, progress, cancellation and partial results.

- The K value is on the AMS slot itself, not only in the popover (#2532, requested and contributed by @gyrene2083) - checking whether a calibration took across four slots was four hovers, and comparing two of them side by side was not possible at all.

- Bambuddy asks a printer that refuses FTPS what it actually said (#2780, measured by @grolmus) - Python reports `[SSL: WRONG_VERSION_NUMBER]` and the bytes that caused it are gone, consumed by the TLS layer. The client now opens one plain connection straight after and logs the printer's own words, so a refusal like `421 Too many connections` identifies the fault outright.

**Changed**

- The spool form is wider, and colour, weight and cost move to their own **Color & Cost** tab.
- Home Assistant sensors get their own settings tab instead of sharing the Smart Plugs one (#2824), and storage locations sort the way they are named rather than putting "Drybox 10" between "Drybox 1" and "Drybox 2".
- Camera view mode is picked at the camera button, per printer, instead of one global dropdown in Settings.
- A file dropped on a busy or offline printer is queued instead of refused (#2849, reporter @abraha2d).
- An archive that arrives with only a name now says what to do about it (#2843, reporter @gyrene2083).
- Generated thumbnails are lit, so one model no longer looks like the next (#2816, requested by @NaegeliJ, contributed by @sadontsev in #2861).
- The Watchtower we recommend for daily builds is the maintained fork (#2917, reported by @CamelT0E).
- The Windows installer build is split in two so a signing request can wait for a human (SignPath Foundation).

**Fixes**

**AMS slots, K profiles and the Filament Track Switch:**

- A K profile could be saved against the wrong hotend and applied to the wrong one; RFID auto-assign picked one without checking which hotend it was calibrated on; and moving an AMS to the other nozzle re-selected for the wrong one.
- Swapping a spool left the previous spool's preset name on the AMS slot card - the stored preset is fetched over REST while the tray arrives on the socket, and the card trusted the cached row over live telemetry.
- The K value on a slot card went blank after a while and came back only after a backend restart (#2854); a slot could show the other nozzle's K value; a nozzle swapped out could keep showing its own; and a fresh install showed no K values at all until someone opened the Profiles page.
- Reading a printer's calibration table could stall for 20 seconds.
- Configure Slot could bind the default K value for a profile the picker was visibly showing.
- Load and Unload in the AMS slot menu did nothing on a printer with a Filament Track Switch.
- A manual K-profile calibration left a print in your archive - the automatic run was already filtered, the hand-started one was not, in either of its two shapes.
- Automatic flow-dynamics calibration left an archive and two notifications behind.
- An AMS slot could name the wrong white - `#FFFFFF` is Jade White in PLA Basic, Ivory White in PLA Matte and plain White in six other materials (#2875).
- One ASA spool parked in the AMS added 20 minutes to every PLA print (#2886, reported by @FirstRulez).
- Linking a Spoolman spool by tag configured the slot as generic filament.

**Spools, inventory and Spoolman:**

- A spool you assigned to an AMS slot unassigned itself seconds later, and the slot's colour changed with it (#2987, reported by @frethop).
- Spoolman reset your renamed extra fields on every restart (#2983, reported by @ngreatorex).
- Turning Spoolman mode on deleted every built-in slot assignment, and turning it back off did not restore them (#2812).
- The first AMS sync after enabling Spoolman from Settings failed on every slot (#2903, diagnosed by @ojimpo), and the connection status described Bambuddy's memory rather than Spoolman.
- Every Bambu RFID spool was added with the wrong empty-spool weight (#2909, reported and fixed by @ojimpo in #2923); existing rows are corrected on upgrade.
- A clear spool synced to Spoolman as pure black (#2912, reported and contributed by @ojimpo in #2924), and translucent spools showed as an empty circle or solid black in four more places.
- An AMS slot card showed a multi-colour spool as one flat band (#2967, reported by @NeighborGeek), and a wood, silk or gradient roll the AMS added for you was drawn as a flat disc.
- An AMS slot assigned a PLA+ spool became unusable for PLA (#2902, reported by @doncaruana), and a wood-filled spool was named as plain PLA on its slot.
- AMS slots were offered as places to store a spool.
- The print dialog named an AMS slot after the wrong spool.

**Cost and charging:**

- Print cost ignored the linked Spoolman spool's price and always used the default rate (#2591, reported by @khaosdoctor), and a rescan or recalculation quietly replaced a Spoolman-derived cost with a default-rate one.
- A print sent from Bambu Studio charged the wrong Spoolman spool and rewrote the archive to match (#2953, reported by @bitelvl1).
- A print with no 3MF borrowed another model's filament and cost (#2843, reporter @gyrene2083), and one that could not debit a spool said nothing about it (#2812). Such a print can now be given its filament weight by hand (#1820, reported by @ojimpo).

**Archives, uploads and printer connection:**

- A print that could not fetch its own 3MF could be charged another plate's filament (#2957, reported by @doncaruana) - a same-named 3MF from the library or an earlier archive was accepted on filename alone, and Bambu Studio writes the printer-side name from the project title, so every plate of a project arrives under one name. Alongside it: a slow-but-healthy download was cut off at 30 seconds, two heavy FTPS transfers could run against one printer at once, and the cover thumbnail re-downloaded a 3MF another part of Bambuddy had just fetched.
- A print archived without its 3MF never got its timelapse, and on a short print could be given somebody else's (#2957 follow-up, reported by @doncaruana).
- A print started from the printer's own screen swept every FTP path, archived blank, and then blamed a slicer setting (#1820).
- A print that started during an FTPS pause was archived empty forever, even after Bambuddy downloaded the file (#2957).
- Some archived 3MFs lost their G-code when re-imported into the File Manager (#2993) - nothing was lost from the file; the Archives card judged it by what it holds while the library judged it by its filename, so a sliced 3MF stored as `Foo.3mf` came back as a source-only project with no Print button. Both now read the zip, and files already in your library are re-checked once on the next start.
- Every print archived from a Bambu slice had no bed temperature, so preheat guessed one (#2989, reported by @senguendk); existing archives are repaired on upgrade.
- A reprint of a file already on the printer lost its thumbnail (#2780 regression), and a printer that keeps its files on the card was written off as internal-storage-only (#2856, reporter @aishlai).
- A failed upload told you to check the SD card, whatever had actually gone wrong (#2899, reported by @grolmus), and one handshake failure took out three queued jobs and every retry they had (#2898).
- The connection diagnostic mistook a slicer's print for one of Bambuddy's own (#2843 follow-up).
- Archive metadata could describe a plate that was never printed, and the archives API never reported which plate was printed (#2796, contributed by @sgiffhorn).
- One unexplained disconnect could stop a printer reporting slicer print mappings for good.

**Slicing:**

- Everything the internal slicer produced was Bambu green, whatever filament was picked (#2977, reported by @fadudba), and a preset the slicer could not resolve was sliced as PLA at 200 C without saying so.
- The internal slicer picked PETG for a PLA plate and an A1 process for a P1S (#2982, reported by @Igiegel); every slice that didn't name its own process quietly got the slowest one the slicer ships; and an H2D Pro classified every bundled preset as another printer's.
- The slice dialog took settings from the file with "Use the file's built-in settings" switched off (#2942, reported by @zevulos), and slicing could ignore the process preset you picked.

**Camera and timelapse:**

- A camera snapshot occasionally logged an asyncio ERROR with a traceback into the camera code (#2968, reported by @ceasley).
- Deleting a print with no 3MF left its timelapse and its uploaded source on disk (#2968).
- Every ffmpeg failure logged its build banner instead of the error (#2968).

**Queue, projects and batches:**

- A batch order whose queued runs were deleted became a card that could neither be queued nor closed (#2960).
- A queued job switched on printers that could never have printed it (#2876).
- Archived projects crowded out the live ones in every project picker (#2888, reported by @e77).
- Skip Objects went dead for the rest of a print if Bambuddy restarted while it was running.
- The build plate of a powered-down printer can be cleared again (#2864, reported by @bryanmahin).

**Interface:**

- Every page was a blank white screen on iOS 16.0-16.3 (#2971, reported by @zevulos).
- Card and row actions were unreachable on phones and tablets (#2865, reported by @aishlai).
- The full-page G-code preview grew without limit and never drew anything (#2887, reported by @ojimpo).
- Picking a spool near the bottom of the label dialog could scroll the dialog itself out of view, and a fully transparent spool printed a label with no QR code (#2918, found and fixed by @whitigol).
- The File Manager's card menu no longer loses its top entry (#2846).
- Closing the bug-report panel no longer throws the capture away and leaves the logs running (#2847).
- A colour mismatch was reported between two filaments the app itself called "Blue" (#2941).
- A printer card said "Unknown stage (72)" where it now says "Preparing".

**Notifications, sensors and energy:**

- Every notification provider vanished from the list after the inventory toggles were wired up (#2827), and two inventory toggles could never be turned on, so stock alerts have never been able to fire.
- One Home Assistant sensor reporting a long text state could stop every printer sensor from updating.
- The AMS temperature alarm fired hourly on ambient room heat, and silencing it cost the colour band (#2905, reported and contributed by @ojimpo in #2943); it also fired for the whole of a drying cycle (#1802, reporter @apizz).
- Energy tracking stopped as soon as a second plug was linked to a printer (#2859).
- A printer whose failure detection was not working showed a green "Safe" badge (#2952).

**Platform and database:**

- Bambuddy could not start against a PostgreSQL server whose messages are not in English (#2949, reported and diagnosed by @dvb6666).
- Timestamps hours ahead of themselves on PostgreSQL in a non-UTC zone (#2855, reporter @Tolga-Unal).
- A failure reason the backend derived and the same reason a user picked counted as two different reasons (#2974, reported by @ojimpo); existing rows are converted to one vocabulary.
- A print that failed on an `hms[]` fault recorded an unlookupable error code.
- Statistics forgot the name of a printer that was deleted with its history kept (#2873, reported by @rembomy).
- The bundled chamber-preheat table was unreadable to the code that reads it.

---
**Sponsors**

Bambuddy is sustainable thanks to people who put their money where their use is. If this release saved you time or kept your farm running, the project runs on recurring contributions - there's no paid tier, no telemetry, no upsell, just sustainable maintenance.

- GitHub Sponsors (recurring, 5 tiers from $5/mo to $300/mo) - https://github.com/sponsors/maziggy
- Ko-fi (one-time or recurring) - https://ko-fi.com/maziggy

