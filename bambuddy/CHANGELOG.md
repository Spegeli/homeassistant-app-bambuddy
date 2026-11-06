## 1.3.0

**Bambuddy 1.3.0**

**What this is**

The largest Bambuddy release so far, on top of 1.2.5.7: 40 new features, 11 changes, 320 fixes and three dependency advisories closed. 24 community PRs went in, and 83 people are credited.

The headline is **archives that hold every print of a file**. An archive used to show only its latest print; it now opens with each plate, every print of it, and each print's own photos, timelapse, note and outcome, and the calendar, Print Log and filters work per print. Reprinting a file from the File Manager adds a run to its archive instead of a duplicate. **Groups can be limited to some printers**, and **jobs can wait for staff review** before they print, for shared and school farms. Failure detection gets a second provider, **OctoEverywhere**, next to Obico. Notifications gain **Notify!** with iOS Live Activities, and **Gotify**. The File Manager can move folders, and users who see only their own files now see only their own folders. **Manyfold** joins MakerWorld under **Model Sources**. Printer cameras open from any page. The interface is available in **Polish**, and downloads about 70% less on each new version.

Most of the 320 fixes come from a review of the whole code base: queue and dispatch, inventory and Spoolman charges, archives, costs, permissions and the database layer on both SQLite and PostgreSQL. Read **Before you update** below: this release changes more defaults and API answers than usual.

New tables and columns are added automatically on both SQLite and PostgreSQL. Some API routes and settings fields were removed; see below.

If you are coming from 1.2.5.6 or earlier, read the 1.2.5.7 release notes too. If you are coming from 1.2.5 or earlier, read the 1.2.5 notes first; all of their upgrade callouts apply to you as well.

**Before you update**

These change behaviour you may rely on. Most need no action unless they apply to your setup.

- **The plate now moves after a print for the finish photo (#3240).** **Restore plate for finish photo** is on by default and now really moves the bed. Turn it off under **Settings > General** to keep the old behaviour.

- **Queued jobs wait instead of printing on the wrong filament (#2799, #3280).** A job whose filament can't be matched to a loaded tray is held for a manual start; **Start** offers **Print Anyway** for the old behaviour. With **Force color match**, a job waits for a spool of the exact colour and variant, and two slots asking for the same filament need two spools of it. A stored AMS mapping that doesn't fit the printer is recomputed.

- **A printer that refuses the upload no longer fails the job (#3409).** SD card, USB and access-code refusals keep the job queued and retry the printer with a growing wait. They send **Job Waiting** instead of **Job Failed**, and "Any <model>" jobs go back to the pool.

- **Groups can be limited to some printers (#1727).** API keys, camera stream links, Cam Wall and overlay tokens now reach only the printers of whoever created them, and a key limited to some printers can't queue to "Any <model>". Nothing changes until an admin limits a group.

- **New permissions are granted once on upgrade, so nothing changes until you remove them.** **Print Without Review** (#1620) goes to every group that could queue, start or run jobs. The Manyfold permissions (#1471) go to groups with the matching MakerWorld permissions. Permissions taken away from a group no longer come back on every restart (#3238).

- **Users who see only their own library files now see only their own folders (#3201).** On upgrade, a folder whose files all belong to one user becomes theirs; every other existing folder is shared with everyone, so it stays visible.

- **Archives count prints, not files.** Reprinting a File Manager or project file from the queue adds a run to its archive instead of a new archive, so scripts that count archives per print will see fewer. Aborted prints now count as failed. The CSV/Excel export has one row per print with new columns; spreadsheets built on the old layout need checking.

- **Costs can change for past prints.** Energy is now costed per hour at that hour's price, and a price change no longer re-costs history, so **Total consumption** figures can differ (#1251). **Recalculate Costs** now reprices past usage from current spool prices (#3414). Cancelled prints are charged each filament's slicer weight times the share fed (#3317). Running prints are priced from their spools at start and marked `~` until they finish (#3261).

- **Obico scores like Obico (#3459).** **Pause print** and **Pause and cut power** need a clearly stronger signal than before, **Notify only** fires at Obico's alert level, and a resumed print is not paused again.

- **Inventory slot assignments.** Spools on an AMS that stays unplugged for more than two minutes are unassigned; RFID spools come back on their own (#3356). Spoolman mode no longer shows built-in inventory slot assignments (#3430). Reading a spool's tag in one slot removes it from any other slot (#3427). Archiving a spool unassigns it.

- **The sidebar's MakerWorld entry is now Model Sources (#1471).** Old `/makerworld` links still work. Camera tokens and the Streaming Overlay builder moved from **API Keys** to the new **Camera** settings tab; old links redirect.

- **Streaming overlay (#3185).** The Classic design no longer adds its own "Printer is idle" / "Printer offline" line. A Classic URL whose `show=` list leaves out `status` shows no idle or offline text; add `status` to get it back.

- **Password Reset email template.** `{password}` and `{login_url}` are gone and the reset link is appended automatically. An untouched template is updated on upgrade; an edited one needs rewording for a link.

- **Built-in calibration on an A1, A1 Mini, P1 or A2L is no longer archived as a print.** The printer kill switch still stops it on these models; switch the kill switch off to calibrate.

- **API, webhook and MQTT changes.**
  - Removed: `POST /printers/test`, `POST /printers/{id}/debug/simulate-print-complete`, `GET /printers/{id}/runtime-debug`, `POST /spoolbuddy/devices/{id}/update-status` and the global virtual printer fields of `GET /settings` and `/settings/virtual-printer`. Use `PUT /virtual-printers/{id}`.
  - `null` for a non-nullable field on PATCH/PUT leaves it unchanged instead of answering 500.
  - Bambu Cloud failures answer 502, and an API key that can't be checked answers 503 instead of "Invalid API key". A K-profile read the printer doesn't answer returns 504 instead of an empty list (#3404).
  - Queue `target_model` is matched case-insensitively and stored in the printers' spelling, and batches can have status **failed**.
  - Archive and statistics date filters take a `tz` parameter; without it, dates are days in Bambuddy's own `TZ` instead of UTC.
  - MQTT relay: `smart_plugs/energy` is published once a minute, `maintenance/alert` carries real values and a `unit` field, and there are new `offline`, `online` and `filament/low` topics.

- **Databases.** PostgreSQL 13 or newer is required (Bambuddy never started on 12 or older). On SQLite, the database is converted once at the first start so ids are never reused, deletes cascade like PostgreSQL, and old leftovers are repaired. The SQLite pool shrinks from 20 + 200 to 10 + 90 connections (#2883); a large SQLite farm may need `DB_MAX_OVERFLOW` or PostgreSQL.

- **Native installs need Python 3.11 or newer**, and Python dependencies are now pinned in `requirements.lock`, which Docker, the installers and the update scripts install. The update scripts stop on an older Python and link to the migration steps. Docker and Windows ship Python 3.13.

- **Update the slicer sidecar image** for the new filament lists, preset fixes and renamed printer presets (#3234, #3250). Some plates get a different automatic filament pick, for example `Generic PA` instead of `Bambu Support For PA/PET`.

- **Update the SpoolBuddy daemon** on the kiosk (**Settings > Updates**) for the spool ID fix (#984). In Spoolman mode, the spool ID replaces the tag UID as the spool's tag.

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
sudo /opt/bambuddy/venv/bin/pip install -r requirements.lock
cd frontend && sudo npm i
sudo systemctl start bambuddy
```

**Windows install**

Download `bambuddy-1.3.0-windows-x64-setup.exe` from this release page (or the unversioned `bambuddy-windows-x64-setup.exe` alias). Existing Windows installs upgrade in place via the in-app Install Update flow.

---

**New**

**Print outcome and archives:**

- **Each archive opens with all its prints** - a click on an archive card or its name opens the archive at `/archives/<id>`: the file, each plate with its estimate, photos and timelapse, and a table of every print of it. Each print has its own photos, video, note and outcome, with **Reprint this print**. The calendar, Print Log and the printer and **Failed Prints** filters now work per print.
- **Wear cost per printing hour** (#694, requested by @wreuel) - an optional rate under **Edit printer** adds the printer's own wear to each print's cost, failed and cancelled prints included. It shows on the archive card, in a **Wear Cost** column in the Print Log, in Quick Stats, projects and batch orders; billing stays filament only.

**File Manager:**

- **Move a folder** (#3305, requested and contributed by @rojosinalma in #3306) - **Move folder...** in a folder's menu, or drag and drop, moves a folder to the root or into another folder. External folders can't be moved, and nothing can be moved into one.
- **Users who see only their own files now see only their own folders** (#3201, requested by @Minebuddy, reported by @lonix) - folders now have an owner, and an admin can mark a folder **Share with everyone**. Uploads and imports go only into your own folders, shared ones and the top level, and folder counts no longer reveal other users' files. See **Before you update**.
- **Browse and import from your Manyfold library** (#1471, requested by @hibikipr) - the **MakerWorld** sidebar entry is now **Model Sources**, with a new **Manyfold** tab to search models and import their 3MF, STL or STEP files, one at a time or in bulk. Bambuddy only reads from Manyfold, and two new permissions control the tab.

**Inventory and spools:**

- **Custom label sheets and saved label templates** (#3296, requested and contributed by @koshilki in #3385) - **Print spool labels** gets a **Custom sheet...** entry with page, label size, columns, rows, margins and gaps, drawn to scale. Custom sheets can be saved under a name and shared by everyone on the install, in both inventory modes.
- **Add a scanned Bambu spool in SpoolBuddy in one tap** (#2685, requested by @BenBBSLA, contributed by @hibikipr in #3389 and #3390) - an unknown Bambu Lab spool on the reader shows the material, colour and weight from its RFID tag, and Quick Add creates the spool with them, tray UUID and tare included.
- **Assign a spool by scanning its QR label** (#1574, requested and contributed by @samedyuksel in #1606) - **Assign by QR** on the **Inventory** page and in SpoolBuddy puts the scanned spool into an AMS slot or a storage location, and the **Assign Spool** dialog gets **Scan a spool QR**. The live camera view needs HTTPS; over HTTP, **Take photo** uses the phone's camera.
- **New spools start with their product's presets and K profiles** (#1326, requested by @mithkr) - tick **Save as default for new ... spools** on a spool's Printers tab, and every new spool of that product starts with its presets and K profiles, however it is added. **Settings > Filament > Profile defaults** lists them and can apply them to existing spools.
- **Spoolman mode uses Spoolman 0.27's native tags** (#3168, requested and contributed by @Niko11111 in #3252) - on Spoolman 0.27 or later a spool can hold several tags, scans look the tag up directly and are faster, and **Settings > Filament** can copy existing tags over. Older Spoolman versions behave as before.
- **Each spool remembers when it was last dried** (#2863, requested by @USER19464727) - a finished AMS drying run marks every spool in that AMS with the date, temperature and duration, shown in a **Last dried** column and on the spool card. It can also be set by hand for an external dryer.

**Queue and printing:**

- **Time to the next pause, and a heads-up before it** (#2984, requested by @apizz) - the printer card shows the time until the next pause added in the slicer, e.g. "20m to pause - 20:27". A new **Pause Coming Up** notification is sent a set number of minutes before, off until turned on.
- **Larger queue thumbnails on hover** (#3313, requested by @humplemann) - hovering a job's thumbnail on a **Queue** card shows it at 256x256, as in **History** (now also 256x256).
- **The queue says when a job printed in a colour the file didn't ask for** (#3279, requested by @Lioncat55) - an amber line per slot on the queue row and in **History**, e.g. "Slot 1 printed in Black, the file asks for Silver". Turn on **Force color match** to have the queue wait instead.
- **Jobs can wait for staff review before they print** (#1620, requested by @ImNanou) - users without the new **Print Without Review** permission can still queue, but their jobs wait with a **Waiting for review** badge until a reviewer starts them. It covers every way a job is queued, including API keys and the webhook.

**Slicing and profiles:**

- **Slice dialog: sorted presets, search, stock presets listed once** (#3386, contributed by @pleasantone in #3393) - preset groups are sorted, every preset dropdown has a search, and a Bambu stock preset that both Bambu Cloud and the bundled Standard profiles list appears once, as the Bambu Cloud copy.
- **OrcaSlicer's third-party filaments and every brand-folder filament in the Slice dialog** (#3234, requested by @nvx) - Elegoo, PolyLite, COEX, SUNLU and many more are now listed, the automatic pick prefers Bambu's own presets and real filament over support material, and custom presets based on brand or P1P filaments now slice with all their inherited settings. Needs the updated slicer sidecar image.
- **Show only printers that are online and spools that are loaded** (#3172, requested by @wolfrage76) - two checkboxes in the Slice dialog narrow the printer and filament lists to what is connected and loaded right now, and a **Pick** button per filament row opens the loaded spools laid out like the AMS. Off until you turn them on.

**Printers, AMS and calibration:**

- **P2S printers show a P2S picture** (#3366, requested and contributed by @andy-sorge in #3369) - instead of the P1S picture.
- **A page for managing printer locations** (#2962, requested and contributed by @SVAN19 in #2995) - create, rename, colour and delete locations and move printers between them, one or many at a time. Renaming a location also updates queued jobs that target it.

**Notifications and camera:**

- **Notify! notification provider with iOS Live Activities and Lock Screen widgets** (#2919, requested and contributed by @simplytoast1 in #3265) - Bambuddy talks to Notify! directly, without the companion container: alerts with photos, a Lock Screen tile per running print with a countdown and problems, and Lock Screen widgets per printer. See **Before you update**.
- **Gotify notification provider** (#2743, requested by @MrCrunshy) - notifications to your own Gotify server, with a priority per event, and the camera photo when External URL is set.
- **Printer cameras from any page** (#2737, requested by @apizz) - camera overlays stay open as you move around Bambuddy. A camera button in the sidebar, or the **C** key, opens one, and an overlay can pop out into its own window and back.
- **USB cameras are picked from a list** - with **USB Camera (V4L2)**, **Settings > Camera** lists the video devices the server sees by name and path, with a refresh button. **Enter path manually** still works.
- **Resize Cam Wall tiles with S / M / L / XL** (#2735, requested by @cmerkle) - from one tile across the full width to five per row, remembered separately from the card size. A kiosk `/camwall` URL can set it with `size=`.
- **Chamber light on whenever the camera is used** (#1655, requested by @dadino) - Settings → Camera can turn the light on for the live view, camera wall, overlay and notification photos, for all or selected printers, and off again 15 seconds after the last use. Off by default; a light you switched on yourself is left alone.

**Failure detection:**

- **OctoEverywhere AI failure detection** (#3169, requested and contributed by @QuinnDamerell in #3428) - a second provider next to self-hosted Obico, using OctoEverywhere's cloud AI with a free Gadget API key and no ML container to run. Pick it under **Settings > Failure Detection > Provider**; it notifies, pauses or powers off as Obico does.
- **Failure detection can send Obico a different Bambuddy address** (#3235, requested and contributed by @chrisbennight in #3255) - an optional **Bambuddy Internal URL** under **Settings > Failure Detection**, used only for the ML server's snapshots, for when External URL sits behind a login. Empty keeps using External URL.

**Streaming overlay:**

- **Your own logo and progress colours, and a see-through Version 2 background** (#3104, requested and contributed by @adamspicedev in #3208) - upload a PNG or WebP logo, set a from/to colour for the progress bar, and fade Version 2's backgrounds so another OBS source shows through.
- **Create an overlay token in the URL builder, or import an existing overlay URL** (#3193, requested and contributed by @adamspicedev in #3207) - **Create overlay token** puts a new token straight into the URL, and **Existing overlay URL** fills in every setting from a URL already in OBS.
- **Portrait overlay URLs for Classic and Version 2** (#3185, requested and contributed by @adamspicedev in #3209) - a new **Layout** choice of Landscape, Portrait or Both, each with its own URL, OBS size and preview. See **Before you update**.

**Accounts, permissions and integrations:**

- **A count on an app's sidebar link** - an app in the sidebar can show a number on its link, as Bambuddy Orders does for its To do, using an API key with **Send notifications**. A count not updated for ten minutes disappears.
- **The MQTT relay publishes printer offline/online and low filament** - new topics `printers/{serial}/offline`, `printers/{serial}/online` and `printers/{serial}/filament/low` for Home Assistant, Node-RED and other subscribers. A short disconnect sends neither offline nor online.
- **Groups can limit their members to some printers** (#1727, requested by @McGagnor) - under Settings → Authentication → Printer access you limit a group to single printers or whole locations, and its members see and control only those printers everywhere in Bambuddy. Nothing changes until a group is limited; admins always see every printer. See **Before you update**.
- **Electricity price from a Home Assistant sensor, costed hour by hour** (#1251, requested by @Roving-Ronin) - for tariffs that change during the day, each hour's energy is now costed at that hour's price, and a new price no longer re-costs past prints or months. See **Before you update**.

**Interface and languages:**

- **Polish** (#3303, requested by @lukg20) - the interface is available in Polish, under **Settings > General > Language**.
- **Remaining time instead of percentage in the browser tab** (#3266, requested and contributed by @bgrr74 in #3283) - **Tab display** under **Settings > Appearance** switches the tab title to the time remaining, e.g. `1h 26m - Bambuddy`. Percentage stays the default.
- **Dominican Peso (DOP) as a currency** (#3388, requested by @rogerabm) - under **Settings > General > Cost Tracking**.
- **Egyptian Pound (EGP) as a currency** (#3334, requested by @aammash) - under **Settings > General > Cost Tracking**.

**Install, platform and database:**

- **`DB_POOL_PRE_PING` to turn off the PostgreSQL connection check** (#3396, requested and contributed by @oh-forf in #3413) - `DB_POOL_PRE_PING=false` skips the check before each pooled session and roughly halves the rolled-back transactions monitoring alerts on. The default stays on; turn it off only for a database on the same host or LAN.

**Changed**

- **A file printed again adds a run to its archive instead of a duplicate** - printing a File Manager or project file from the queue again now joins its existing archive as a new run in the Print Log, with a **Plate** column for multi-plate files. Prints from the slicer, the printer or uploads are unchanged.
- **The archive export has one row per print** - the CSV and Excel export now lists each print as a row, with new **Print ID**, **Printer**, **Plate**, **Outcome** and **Duration (s)** columns. See **Before you update**.
- **Unused API routes and settings removed** - `POST /printers/test`, two printer debug routes, `POST /spoolbuddy/devices/{id}/update-status` and the old global virtual printer settings are gone. See **Before you update**.
- **A grouping that ended in failures is marked failed** - a batch whose jobs all failed or were cancelled, with nothing printed, now shows as **Failed** with its own filter instead of staying active forever. Orders are unchanged.
- **Deleting a custom maintenance type says it applies to every printer** - the confirmation now warns that the type and its history are removed from all printers.
- **The web interface downloads about 70% less on each new version** (#3175, requested by @mason9468) - scripts and styles are now sent compressed and cached until an update brings new ones; the main script drops from 11 MB to 3 MB.
- **The web interface opens faster: pages and languages load when needed** (#3175, requested by @mason9468) - each page and each language now loads on first use, so the login page needs 1.2 MB instead of 11 MB. A tab left open across an update reloads once onto the new version.
- **Notification providers are listed alphabetically** - in the Add Notification Provider dialog, in the app's language.
- **The Streaming Overlay builder remembers your choices** - fields, printer, layout, artwork, colours and the rest are kept in the browser across reloads, with a **Reset choices** link. The token is still never stored.
- **The camera settings stay short on large farms** - **External Cameras** now lists only printers that have one, with **Add external camera** to pick a printer and a bin icon to switch back to the built-in camera.
- **Camera settings have their own tab, and the settings menu is sorted alphabetically** - a new **Camera** tab holds External Cameras, Camera API Tokens and the Streaming Overlay builder; old links open it. **General** stays first, the other tabs follow alphabetically.

**Fixes**

**AMS slots, K profiles and drying:**

- A spool loaded into a slot after a runout and assigned mid-print stayed invisible on the printer card until the print ended (#3434, reported by @0xCyberFortress). The card now shows it with an amber marker until the printer takes it.
- AMS Filament Backup did not pool two rolls of the same filament when one was added by RFID and the other from the preset picker, so Start refused prints the printer could finish with Auto Refill (#1824, reported by @lightmaster). Pooling now follows what the printer reports for each tray.
- A printer that did not answer the K-profile read looked like a printer with no K profiles, and a Git restore then sent every backed-up profile again as a duplicate (#3404, reported by @Spegeli). The page now says the profiles could not be read, and a restore skips that nozzle.
- SUNLU filaments and about thirty P1/X1 presets put the wrong filament into an AMS slot, a Bambu PLA Silk spool went in as PLA Matte when signed in to Bambu Cloud, and Orca Cloud profiles based on SUNLU went in as Generic PLA (#3387, reported by @Spegeli). SUNLU and seven newer Bambu filaments, such as PLA Tough+ and PETG Matte, are now in the catalogue.
- Configuring a slot through the API with a setting id such as `GFSL99` left the slot without colour or type, and auto-unlink dropped its spool (#3444, reported by @Novastorm4332).
- A colour set on the printer's touchscreen got a general name such as "Blue" when its hex was a step off Bambu's, as with Blue Grey (#3279, reported by @Lioncat55). It is now named after the closest Bambu Lab colour in the slot's own range.
- Reset Slot cleared an AMS slot on a single click, even mid-print. It now asks first and is unavailable while a print runs.
- On an H2D, a manual filament load the printer refused could later show the wrong active tray. The refused target is now forgotten after two minutes.
- A printer refusing the K profile re-applied after an RFID read was not logged, which made wrong pressure-advance prints hard to diagnose.
- Opening several pages at once could fetch the Bambu Cloud filament names for K profiles many times over. They now share one fetch.
- Configure Slot reported a typed K value as applied when it could not be sent. It now warns that the filament was set but the K value was not.
- An H2D could keep pointing at the old slot after a filament change, on the printer card and in usage tracking.
- With "Wait for drying to complete" on, queue drying never dried an AMS ahead of a scheduled print. A printer whose job is scheduled for later is now dried ahead of it.
- A Silk spool without a slicer preset could take the Matte preset already in the slot. The finish must now match too, otherwise the slot gets the generic preset for that material and finish.
- Some Bambu Cloud presets showed their raw id instead of their name in the K profile list.
- A K profile picked in Bambu Studio or on the printer's screen was set back to the stored one at the next AMS report. See **Before you update**.
- Saving, deleting or selecting a K profile could change the nozzle size shown for the printer.
- A K profile save, batch save or delete the printer never acknowledged was reported as done. It now says the profile was sent but not confirmed.
- Stopping drying said "Drying stopped" as soon as the command went out. It now says "Stop command sent".
- The "P1 / P2" print labels on AMS slots rarely appeared during a print. They now show, also after a Bambuddy restart.
- "Rotate spool during drying" stayed available on some firmware with filament in the feed tube, and the printer refused the drying start.
- On two-nozzle printers with several AMS, the run-out hint often could not name the slot.
- A regular AMS reporting a single tray was shown as an AMS-HT.
- Load and Unload on an AMS-HT slot were refused or aimed at a unit that does not exist. Loading from the A2L's AMS Lite now also sends the target Bambu Studio sends.
- The K profile picker offered and pre-selected profiles measured on the other nozzle flow type on H2-series printers. They now sit under "Other", and every profile shows [HF] or [S].
- With "Wait for drying to complete" on, an "Any <model>" job could start on a printer whose AMS was drying, and queue auto-drying never dried for such a job.
- The AMS drying button showed as available on a printer that cannot dry until the next live update after a page load.
- A PP, PE, PCTG, PLA Silk or PLA High Speed spool without a slicer preset was sent to its AMS slot with no filament ID, and PVA, HIPS and Bambu support filaments got the wrong setting ID (#3273, reported by @sgiffhorn).
- AMS Filament Backup showed "?" on the P1S, P1P, A1 and A1 Mini (#3259, reported by @HopNotch). The badge now shows the printer's real setting and follows changes made in the slicer.
- H2D, H2D Pro and H2C with several AMS on one extruder briefly marked the wrong tray as loaded on every filament change (#3242, reported by @Thomansky). No wrong spool charge was found, but the wrong tray no longer enters the usage split.

**Spools, inventory, Spoolman and SpoolBuddy:**

- In Spoolman mode, slot assignments kept from the built-in inventory put printer slots on unrelated Spoolman spools that could not be cleared (#3430, reported by @sean3318). Spoolman mode now uses only Spoolman's assignments; the built-in ones are kept for when you switch back.
- A spool whose tag was read in one printer's slot stayed assigned to another printer's slot too, and that printer's prints were charged to it (#3427, reported by @Spegeli).
- In Spoolman mode, a Bambu spool created by AMS sync lost its filament preset, so on the external spool a Bambu PLA Basic became Generic PLA (#3433, reported by @ojimpo).
- Spoolman mode had no per-print usage history, so the spool dialog listed no prints and the stock forecast never reached its Trend rate (#3407, reported by @ojimpo). The forecast's fallback rate in both modes also counted shelf time as use, and now counts only the time a spool was in use.
- In Spoolman mode, the stock forecast used a built-in spool's history when the ids matched, so a spool using 2.5 g a day could show 46 g a day (#3406, reported by @ojimpo).
- The stock forecast left out used-up spools once they were archived, so a SKU in weekly use could show 0.2 g a day and the Reorder and Stock Break alerts came late or never (#3399, reported by @ojimpo). Spools archived in the last 90 days now count towards the rate.
- The stock forecast named a SKU's colour twice, as in "PLA Basic Black Black" (#3400, reported by @ojimpo).
- In Spoolman mode, an external-spool print on an X2D or H2D was charged to the wrong holder, or not at all from the right holder (#3405, reported by @juandelarossa).
- A Spoolman slot change made from another tab or client, such as a filament scale using the API, did not reach open pages without a reload (#3402, reported by @Eifel-Joe).
- SpoolBuddy sometimes read a Bambu tag on the first scan without its tray UUID (#3377, reported and contributed by @hibikipr in #3378).
- SpoolBuddy with a PN5180 reader misread NTAG tags with 7-byte UIDs (#3258, contributed by @Thomansky in #3346). Spools linked with the short form are still found and upgraded on the next scan.
- Bambu PLA Silk+ spools added by RFID arrived without a colour name, in both inventory modes. The update files the seeded Silk+ colours correctly and names the affected spools.
- A spool replaced mid-print after a runout was charged for the whole print (#3325, reported by @HarryCoff2). The filament is now split between the old and new spool at the layer of the swap.
- A print that failed or was cancelled could be charged for more filament than it used, sometimes more than the finished print (#3317, reported by @ojimpo; thanks to @Andrewdlec for the files).
- With Spoolman, writing a SpoolBuddy tag that another spool already carried left it on both spools (#3312, reported by @sgiffhorn).
- A SpoolBuddy kiosk got stuck on the login page until the next reboot when it started while the database was unavailable (#3360, reported by @sargonas). Pages now show "Can't reach Bambuddy. Retrying..." and continue once it answers.
- Searching "#123" in Assign Spool found nothing when that spool's material did not match the slot (#3301). It now shows the spool, or says why it cannot be offered.
- After a printer was deleted, spools still showed as loaded in it for up to 30 seconds.
- In Spoolman mode, writing a SpoolBuddy sticker to a Bambu spool created from the AMS broke its AMS link, so the next sync created a duplicate spool. Such spools are no longer listed as untagged. See **Before you update**.
- SpoolBuddy's Write Tag warned "color_name not set" for every Spoolman spool. It now warns only when the colour name is really missing.
- A SpoolBuddy update reported success when installing its dependencies timed out. A timeout now stops the update with an error, and the time allowed went from 2 to 5 minutes.
- A failed Unassign on the printer card showed no message, and the spool simply stayed assigned.
- The Inventory "Full" column always read "-" and has been removed.
- In Spoolman mode, a print whose 3MF arrived late was charged from the AMS remaining percentage instead of the 3MF.
- The Spoolman AMS syncs could replace a spool assigned by hand, and the Sync buttons in Spoolman settings did not update other open pages or the slot's filament preset.
- Several Spoolman requests misbehaved: a storage location could be deleted while Spoolman was unreachable, labels for an archived spool failed the batch, an archived spool could be assigned to a slot, and resetting "Total Consumed" reported success when it failed.
- A finished print's filament could be charged twice when an AMS update arrived right as the print ended.
- Spool weights and slot assignments written at the same moment could undo each other or fail with a server error on PostgreSQL.
- Inventory views and printer cards did not show deleted spools and new weights until a refresh, and deleting a printer on SQLite left its spools assigned to it.
- Saving the SpoolBuddy backend config said only "Config queued." although it needs a daemon restart. It now says so and offers "Restart Daemon".
- A used weight entered for a new spool was not locked, so the first AMS sync could overwrite it. See **Before you update**.
- Every AMS sync and scale weighing stamped "last used" on Spoolman spools. Only print usage sets it now.
- On the A2L, filament used from the AMS Lite was never charged to its spool, or went to a regular AMS slot of the same number.
- A spool Spoolman created from the AMS for a 250 g refill matched to a 1000 g filament was created as a 1000 g spool showing 75% used.
- An unregistered SpoolBuddy that was still running did not register again on its next heartbeat.
- In Spoolman mode, a failed print that switched to the backup spool charged everything to the spool that ran out, a second copy of the same archive printing at once was never deducted, and unused filament slots could be charged to the external spool.
- Spoolman slot assignments were not checked against what the printer reported back, and Configure AMS Slot opened without the Spoolman spool's slicer preset.
- Archiving or deleting a spool left it in its AMS slots, where it was charged the next print's usage, and "Restore" in an expanded group row did nothing. See **Before you update**.
- "Sync Weights from AMS" counted a running print twice when used mid-print and skipped locked spools for good, and SpoolBuddy scale weights could be overwritten by the AMS sync. See **Before you update**.
- SpoolBuddy's Write Tag page could stay on "Writing tag...", scanned tags failed silently when Spoolman was unavailable, and lookups fell back to the built-in inventory when the Spoolman URL was refused.
- The filament of a print spanning a Bambuddy restart could be counted twice.
- In Spoolman mode, SpoolBuddy could write a hidden built-in spool with the same id to the tag while reporting success, so the Spoolman spool never got its tag. Writing a tag now uses only the inventory in use.
- Deleting a spool deleted its usage history on PostgreSQL, and on SQLite the next new spool could take over a deleted spool's number with its prints and consumption. Usage history now stays, prints keep their spool cost, and spool numbers are never reused.
- On PostgreSQL databases created before v0.2.4.8, reporting usage to Spoolman failed and archives never got the colour, material and cost of their Spoolman spools. The affected columns are converted on the next start.
- SpoolBuddy knew a Bambu Lab spool only by the tag that was scanned, so scanning its other side offered to add it again, and kiosk and AMS spools were not matched to each other (#984, block 9 read from @Keybored02's #1200, measured by @Thomansky and @Sawtaytoes). Update the SpoolBuddy daemon to get the fix; existing spools pick up their spool ID on the next scan.
- In Spoolman mode, lifting a spool off SpoolBuddy while Assign Spool or Add to Inventory was open lost its tag.
- Inventory deducted only the first filament when two filaments of a print came from the same spool (#3230, reported by @Andrewdlec).

**Queue and dispatch:**

- A printer whose SD card or USB drive refused the file, or that rejected the access code, failed one queued job after another: an H2D with a bad USB stick failed seven in an hour (#3409, reported by @simonkreuchauff-oss). The jobs now stay queued, the printer is retried with a growing wait, "Any <model>" jobs can move to another printer, and a file name no card accepts still fails with a request to rename it.
- "Force color match" was never saved on a job for a specific printer, so a part set to black could print in green (#3445, reported by @frnzzle).
- A job with "Force color match" printed on any spool of the same material when the colour was missing (#3280, reported by @Lioncat55). It now waits with "Needs PLA #A4AAAC" until that exact colour, and variant, is loaded.
- A job queued for "Any" model kept returning to a dual-nozzle printer whose filament sat on the wrong nozzle, or to a printer with one spool for two slots of the same material. Such printers are now passed over, and the job waits with the filament it needs.
- Queue prints to a printer without an AMS, such as a P1S on its spool holder, failed with "Failed to get AMS mapping table" (#3356, reported by @dogod3814t). An unplugged AMS also now disappears from the printer card without a restart.
- Opening the Queue page on a large print farm could stall Bambuddy for over a minute. History now loads 50 runs at a time, and Clear History is a single request.
- The queue's "View in File Manager" icon opened an empty page (#3336, reported by @Magical-Penguin). It now opens the file's folder with the file marked, and the archive icon marks its archive.
- A late slicer update through a virtual printer could rewrite a queue job already being sent, so the job and the spool charged could differ from what was printed.
- Saving an edited queue item showed "Queue item updated" twice and closed the dialog twice.
- The queue timeline and history rows showed plate 1 for every plate of a multi-plate file.
- An "Any model" job with a filament override could wait forever for an equivalent filament under another name, preheat heated the bed for the hottest filament of the whole project instead of the plate, and the queue page showed generic colour names.
- Cancelling a pipeline run, or stopping a job on an offline printer, could leave a printer preheating or cost centre budget reserved, and a print start the printer refused was taken as accepted for three minutes. A refused start now goes back to the queue at once.
- Queue jobs added through the API or webhook could miss their printers: a model in lower case was refused, a webhook reprint ignored the slicer's AMS slots, and a multi-plate file queued without a plate waited for every plate's filament. See **Before you update**.
- A queue job edited while the scheduler was working through the queue could lose the edit or be sent to the wrong printer. It now waits for the next round.
- An "Any model" job waiting for a drying printer read "Busy" as if that printer were printing. It now says "(drying)".
- The queue bulk edit showed a neutral, English-only message even when nothing was updated. It now shows an error or a warning.
- A plate printed only from the external spool turned the AMS back on when another plate of the same file used it, and the printer refused the job (also #3087).
- A virtual printer for any printer of a model stored the slicer's AMS on/off with the job, although the slicer could not see the real printer's AMS.
- A nozzle mapping on an "Any model" job was sent unchanged to whichever H2C picked it up instead of that printer's rack positions.
- Jobs added from the File Manager, webhook, virtual printer, pipeline or an order sent no "Job added" notification or MQTT event, and some ignored the default print options. See **Before you update**.
- The filament override picker merged identical left and right external spools on an H2D or X2D without an AMS.
- Prints queued through a virtual printer lost the slicer's nozzle offset calibration, rack nozzles and AMS choices, or took the old printer's nozzle positions to another printer.
- The print dialog had several gaps: **Print Anyway** in a multi-printer print waved through printers that were never checked, an untouched plate dropdown with printer alternatives queued the job with no plate, H2D and H2C matched nozzles from every plate instead of the chosen one, and a sliced 3MF named without `.gcode` could not be dropped on a printer card or picked in **Upload for Print**.
- Orders and groupings whose last job was cancelled, stopped, cleaned up or failed before reaching the printer stayed **active** until the next restart.
- Cancelling a queued job while it was being sent was overwritten when the upload then failed, sending a failure notification and skipping the next dependent job. A stopped job could also be put back in the queue or leave its file on the printer.
- "Only if the previous print succeeded" checked the wrong printer for jobs queued to any printer of a model, so it nearly always let the job through. It now checks the printer it is about to use, takes another of the model if needed, and shows a **Resume after failure** banner when every free one failed last.
- A queued job moved to another printer kept the old printer's AMS mapping, **Print Anyway** and nozzle choice, so it could print the wrong colour or skip filament checks, and **Dispatch remaining** of an order pinned every copy to one printer. These are now worked out again for the new printer.
- A slicer pipeline run stayed **dispatching** forever once a copy's queue entry was deleted, and **Retry failed** could not tell what to retry. Each copy now keeps its final state.
- A printing queue job showed the slot AMS Filament Backup had switched away from as **Empty**. The card now shows the backup spool in use.
- A queue job whose file name started or ended with a space stayed "printing" for five minutes after it finished, holding up the next job (#3241, reported by @Thomansky).
- An "Any model" job waited for filament on one printer while another idle printer of that model had enough (#3137, reported by @RambachTJ). The queue now picks a printer with enough filament.
- A job moved to a location or model could print from an empty external spool on a printer that had the filament in its AMS, stopping with "External filament is missing" (#3239, reported by @hyyz17200).
- A job moved to a location or model could print in the wrong colour from the tray number it had on its original printer (#3239, reported by @hyyz17200). Trays are now matched by material and colour on the printer that runs it, and the job is held when nothing fits.
- A virtual printer with Save AMS mapping lost the slicer's external-spool pick, so the print could stop with 0700-8012 "Failed to get AMS mapping table" (#3237, reported by @erabti).
- One model queued to several printers used the first printer's AMS mapping for all of them and could print in the wrong filament (#2799, reported and contributed by @grolmus in #2803). Each printer is now mapped against its own AMS.
- A job whose filament was not loaded was sent anyway and refused by the printer after the whole upload (#2799, reported and contributed by @grolmus in #2803). It now waits for a manual start and the queue row says which filament it needs.

**Archives, print log and statistics:**

- A print that finished while Bambuddy was restarting was archived as aborted and its queue job cancelled (#3310, reported by @Thomansky). It is now closed as completed, or as failed with the printer's error.
- Printing one plate of a multi-plate file was measured against the whole file, so the card showed +200 % (#3375, reported by @sargonas). Each print is now compared with its own plate's estimate, on the card, in the archive, in statistics and in notifications.
- Reprinting a plate of a multi-plate file from an archive, the outcome dialog or the queue history opened on plate 1 and could print the wrong part (#3395, reported by @Thomansky).
- An old video still on the printer's card could be attached to a new print, deleted from the printer and used for its finish photo, when the card could not be read at print start (#3412, reported by @ojimpo).
- The second plate or a reprint of an archive lost its finish photo. Photos lost this way are restored once at startup if the file is still on disk.
- A late timelapse left two finish photos on an archive.
- An archive printed more than once played only the latest print's video. The button now shows how many videos there are and opens the archive when there is more than one.
- "Change outcome" in an archive's print list opened a dialog with nothing to choose.
- A print started over LAN, from Handy or on the printer was not linked to its archive while it ran, and its print time came out short (#3327, reported by @Andrewdlec).
- "Print again" on the printer's screen produced an empty archive when the project's title differed from its file name (#3307, reported by @elizabethburg).
- A large 3MF that timed out at print start was downloaded a second time, holding the printer's file connection for up to 5 more minutes (#3308, reported by @elizabethburg).
- Statistics' Today, This Week and the other ranges used UTC days, so near midnight they showed the wrong day's prints.
- "Purge old archives" could delete by an age that had not been previewed when you clicked straight after changing it.
- A stray Stop on an idle printer could relabel a later failed print as cancelled by the user.
- A timelapse could go to the wrong print, or none, when the next plate or a reprint started soon after, or when Scan for Timelapse matched another archive's video.
- The Archives page showed a timelapse picked, uploaded, converted or deleted by hand only after a reload.
- Editing an archive while it was being reprinted rewrote the previous print's result in the print log.
- Archives made without their 3MF showed blank colour swatches and got no filament from an AMS-HT. Existing archives are repaired on startup.
- An archive showed the nozzle temperature of the project's first filament instead of the one its plate prints.
- A print stopped while its printer was offline was missing from the print log, and a printer reporting the same end twice logged the run twice.
- A print Bambuddy did not start could be matched to an archive whose name only contained its name, so finishing "Clip" could complete and bill "Cable Clip".
- When the 3MF could not be downloaded directly, print start could archive another file whose name merely contained the print's name.
- The built-in calibration on A1, A1 Mini, P1 and A2L was archived and announced as a print. See **Before you update**.
- The recovery download for a print's 3MF gave up after 90 seconds, so a large file on a slow SD card never made it. The deadline now follows the file size, up to 15 minutes.
- A print stopped by the printer kill switch was archived as failed with no reason. It is now cancelled, with "Stopped by the printer kill switch".
- A queue job stopped while its printer was offline stored an untranslated sentence as its failure reason. It now stores "User cancelled", and existing archives are converted on startup.
- A re-sliced archive showed as printed and counted as a finished print. It now shows as "Not printed" with an estimated cost.
- A reprint of a single-plate archive left the old timelapse behind as an unlinked file.
- Edit Archive saved "Cancelled" as "aborted", opened a cancelled archive as "Completed", and allowed setting "Printing" by hand.
- An archive left on "printing" after a missed end took over the next print of the same file for two hours.
- Print History, usage and thumbnails could describe the wrong plate of a multi-plate file, also after a restart or for prints started outside Bambuddy.
- Reprints had several archive problems: a completed reprint still showed the previous run's failure reason, a queued job whose archive was deleted printed with no archive, notification or usage tracking, and a timelapse deleted during MP4 conversion came back afterwards.
- Deleting an archive for good failed with a server error on PostgreSQL when an inventory spool had been used for it, and **Recalculate costs** could add the spool cost of other prints with the same name to an archive.
- Archiving a virtual-printer upload into a project that does not exist failed after archiving on PostgreSQL or saved a broken link on SQLite. It is now refused up front with "Project not found".
- Deleting a printer could delete the archive of a print starting on it at that moment on PostgreSQL, even with "keep archives" on.
- A printer deleted while its print was starting still got an archive, which showed "printing" forever on SQLite, plus a timelapse and tracking.
- Starting the next plate of a Send All deleted the previous plate's timelapse (#3275, reported by @dovmesiz). A queued print running over 2 hours also lost its plate, AMS mapping and cost centre data.
- A large timelapse could not be attached when it took more than 5 minutes to download (#3272, reported by @dovmesiz).
- Statistics counted a multi-material print priced from spools as one combined material, and the Archives material filter missed such prints (#3262, reported by @ojimpo).
- A print started from the printer's screen took about six seconds longer to archive, and could not be reattached after a Bambuddy restart (#3009, reported by @bdwilson).

**Costs, energy and finance:**

- "Recalculate Costs" ignored changed spool prices and updated nothing (#3414, reported by @BurgerKerman). It now reprices past usage from the spools' current prices, and the Print Log, statistics, projects and orders follow.
- A personal cost centre's budget could not be changed or set to 0 (#3358, reported by @airforceixi).
- A failed or cancelled print's card showed the whole file's cost and grams with no hint (#3318, reported by @ojimpo). A tooltip now says it is one full print's cost and points to the Print Log.
- A print that failed on its first run left the archive costing only the part it printed, so reprints were estimated and billed from that fraction.
- In Spoolman mode, a very short print could end with its estimated cost instead of the real one.
- Editing a transaction to "No cost center" kept the old cost centre.
- In Spoolman mode, the print dialog's cost estimate, budget check and "g left" came from the built-in inventory instead of the Spoolman spool in the slot.
- A Spoolman spool priced only through its filament showed no Cost/kg in the Inventory or on SpoolBuddy, although prints were charged that price. The column now shows it, marked "(filament price)".
- A print's filament and cost could be charged with another plate's or another run's AMS mapping.
- An archive cost set through the API or by Recalculate costs did not reach the statistics, project totals or batch sums. See **Before you update**.
- An archive whose 3MF arrived during the print kept the default filament price instead of being priced from its spools.
- In Spoolman mode, failed or stopped prints were logged with no cost, and queued library files were priced at the default filament cost.
- Recalculate Costs and Rescan gave an archive printed three times the cost of all three, editing an archive's weight did not reprice it, and a spool without a price was charged nothing at completion.
- A print whose dispatch failed left its cost centre behind, and the next print of that archive was charged to it.
- A print without a user kept its budget reservation for good, so the cost centre showed less budget left. Leftover reservations are released at the next start; booked charges don't change.
- Editing a smart plug could save values that broke the smart plug list and the plug with server errors until fixed in the database, and could give a printer a second Tasmota plug. Edits are now checked the same way as adding a plug.
- A print whose user was deleted while it ran was never charged to its cost centre and its budget reservation stayed active. It is now charged and settled, and ledger entries without a user read "No user".
- A running print's cost used the default rate instead of its spools, then changed without notice at completion (#3261, reported by @ojimpo). It is now priced from its spools at start, marked with `~` while it runs.
- A smart plug that reports energy in watt-seconds, such as a myStrom Switch, could not be saved because the multiplier was too small (reported by @CLKRUN in #1251).
- The Statistics energy total stayed at 0 for Shelly and other REST plugs with only a lifetime counter (#3232, reported and contributed by @rojosinalma in #3233).

**Slicing, profiles and 3MF:**

- An unsliced project saved as `.gcode.3mf` was treated as a printable file, and printing it to a cost centre failed with an unrelated error (#3435, reported by @Mounting9612). It is now stored as a project and offered for slicing.
- Orca Cloud processes were hidden for every printer, and a process made for a user printer preset was refused by the slicer (#3380; contributed by @pleasantone in #3381).
- With OrcaSlicer preferred, the Slice dialog could preselect the wrong material for H2C filaments, such as Generic PETG for a PETG-CF slot (#3403, reported by @pleasantone).
- Slicing for the Cool Plate SuperTack, or for the Smooth PEI Plate, failed with "Filaments are not compatible with the plate type" (#3359, reported by @Akaviiii). Saved pipelines with either plate now work without being saved again.
- Slicing a model coloured with the paint tool could turn several filaments into one colour (#3355, reported by @cartman75).
- A slow progress answer from the slicer sidecar was reported as "Slicer sidecar unreachable". It now says the sidecar did not answer in time.
- The Slice dialog hid renamed printer profiles while "Only printers that are online" was on (#3172, reported by @gregspatrick).
- Slicing failed with a renamed printer preset, saying the printer was not compatible with the process preset (#3250, reported by @bobobo1618). Needs the updated slicer sidecar image.

**Printers, MQTT and connection:**

- When a dropped printer connection came back, commands still waiting for an acknowledgement were sent again, and a 4-hour print was cancelled seconds after the reconnect (#3454, reported and diagnosed by @SaadShaya7). A command sent in the seconds before a drop now has to be clicked again.
- On the X2D, the left and right auxiliary fans were swapped on the printer card (#3373, reported by @Spegeli).
- An H2D Pro reported no chamber temperature and refused chamber heating, and queued prints got no chamber preheat or airduct switch; the X1E's chamber heater was not offered either (#3335, reported by @Spegeli).
- An AMS Lite showed no serial number or firmware version on the A1, A1 Mini and A2L (#3348, reported by @Spegeli).
- Firmware could be uploaded to a printer in the middle of a print. Upload is now offered only while the printer is idle.
- The MQTT Debug log showed messages already changed by Bambuddy instead of what the printer sent.
- The cooling/heating mode switched on the printer showed the old mode on the printer card until the next refresh.
- An H2C rack slot's material label disappeared from the printer card until the next refresh.
- Time a printer spent offline mid-print was counted as print time, so hours-based maintenance came due early.
- Two pages could create the same maintenance item twice, and marking it performed could update the hidden copy. Existing duplicates are merged on upgrade.
- The maintenance API answered "performed" in hours for an item set to days.
- Skip Objects and the printer connection diagnostic held a database connection while waiting on the printer.
- An upload the printer never confirmed was not checked. Its size is now read back and a mismatch is logged.
- A skip the printer refused stayed marked as skipped. It is now taken back off the list and logged with the printer's reason.
- A nozzle change, firmware update or developer-mode switch reached the printer card only with the 30-second refresh.
- A print resumed after a Bambuddy restart could lose the plate height the plate restore uses.
- Saving any virtual printer restarted every proxy-mode virtual printer and dropped the slicer's connection. Changing a printer's IP and renaming a virtual printer now restart the right ones.
- With the internet down, every firmware check logged a full error for every Bambu Lab page it tried. The outage is now logged once per site as a warning, with a line when it is reachable again.
- When Bambu Cloud was unreachable, the cloud preset, device and firmware views answered with a server error, and a pasted token, password or email code was reported as wrong. These now say Bambu Cloud is unreachable.
- A printer added after deleting another could take over the deleted printer's running print and its owner, filament tracking, plate-clear prompt, pending notifications, camera picture, Obico verdict and plate detection references, and skipped its own first-connect steps.
- The SD-card cleanup could delete a file the printer was printing right then (#3009, reported by @bdwilson).

**Notifications and HMS:**

- Mail from Bambuddy could be quarantined by strict mail servers because it had no `Date` or `Message-ID` header, and a sender name with accents or a comma broke the From address (#3376, reported by @BenjaminCs).
- The same printer fault could be listed twice when the printer reported it both as a print error and in its HMS list.
- The daily digest was lost when it could not be sent, or when its time fell in quiet hours. See **Before you update**.
- A later print could be attributed to, and emailed to, the user of an earlier queued print of the same name.
- "Print Stopped" after a printer came back online showed the time it was offline as the print's duration. It now shows the sliced estimate.
- The template editor had no variables or preview for the print outcome confirmation, and seven other events had no names.
- A notification channel limited to one printer also received other printers' queue and waiting events. See **Before you update**.
- CallMeBot dropped the "+" from the phone number.
- A print started outside Bambuddy on a printer with auto-archive off could be reported to the owner of the previous queue job. A queue job whose archive couldn't be found now still reaches its owner with the right duration.
- Smart plug Power Alerts were never sent and broke the plug's status request on the printer card. They are now checked in the background, sent once per crossing as **Printer Error** events.
- A printer fault that kept coming and going was notified every time it came back (#3226, reported by @sgiffhorn). It is now notified again only after it has been gone for 10 minutes.

**Camera, stream overlay and failure detection:**

- Obico failure detection added whatever the camera always sees, such as plate texture, to its score, so it acted too early, and it paused a print again after you resumed it (#3459, reported by @jasoncronje). Scoring now matches Obico's, and the pause actions wait for Obico's stronger pause level.
- With "Restore plate for finish photo" on, a tall print could drive the plate past the bottom of its travel, as on a 238 mm print on an H2C. The plate now goes back to where the print's end G-code left it.
- A camera opened from a printer card or the Cam Wall followed you onto every page (#2737). Only cameras opened from the sidebar's Cameras button now show everywhere.
- In the iOS home-screen web app, a camera opened in window mode took over the app with no way back (#3419).
- A camera rotated 90 or 270 degrees was cut off or letterboxed in the floating camera window, on Cam Wall tiles and in the stream overlay (#3362, reported by @BurgerKerman).
- Stitching a layer timelapse could use gigabytes of memory, so a container with a 2 GiB limit was killed at the end of a long print and lost its timelapse (#3292, reported by @fma965). It now peaks around 300 MiB, and ffmpeg no longer keeps running after an error or cancel.
- The timelapse player pushed its controls off screen for a portrait video, and some of its labels were always in English (#3281, reported by @BurgerKerman).
- Saving in the timelapse editor could fail on long videos, and the saved music was always at full volume. Saving now runs in the background with progress and Cancel.
- Escape could be ignored right as the Build Plate Check result appeared, leaving the chamber light on.
- With the camera light setting on, the plate check could switch the chamber light off under a live view.
- A single-client external MJPEG camera made timelapse frames, finish photos and Obico checks fail while someone watched. They now use the live view's frame.
- The X1C live view could stop instead of reconnecting.
- Camera test, diagnose, plate check and plate calibration held a database connection for the whole capture, which could exhaust the pool on a large farm.
- The OBS stream overlay ignored live updates and moved only with its 2-second refresh.
- A plate check that could not run reported an empty plate. It now warns with the reason, and the print still goes ahead.
- A second Bambuddy on the same machine cut the other's live camera every minute.
- A restart with a camera view open logged an ERROR with a full traceback for each stream.
- A layer timelapse of a long print was stopped after 5 minutes and its frames deleted. Stitching now gets up to an hour, and frames are kept for about 24 hours if ffmpeg fails.
- A frozen external RTSP camera kept showing the same picture. It is now reconnected, like the printer's own camera.
- A USB camera could not be watched from several places at once; the second viewer got a blank picture. See **Before you update**.
- Camera snapshots and the camera Test button failed for a USB camera while someone watched the live view. See **Before you update**.
- USB camera finish photos, timelapse frames and snapshots were sometimes killed mid-capture, and other programs' ffmpeg on a USB camera were stopped too.
- The camera Test button read "Camera connected640x480".
- With an external RTSP or USB camera, closing one view of a printer stopped the stream for every other open view.
- A minimized camera window kept its stream open, and the camera window and Camera page left the current stream running after a reconnect, keeping the camera busy and the chamber light on.
- Cam Wall tiles froze on their last frame when the server ended a stream, and a long-running overlay browser source piled up camera connections. Live tiles now reconnect every minute and show "No signal" if the camera stays down.
- The finish photo never raised the plate back into view, on any printer (#3240, reported by @Thomansky). The plate now moves when **Restore plate for finish photo** is on, which is the default.

**Login, users and permissions:**

- API keys of Operators were refused with 403 on their owner's own queue jobs, archives and library files.
- LDAP and SMTP "Test" checked the saved settings instead of what the form held.
- A user's email address could not be removed.
- Clear all on the shopping list, Clear in the Git backup history and removing a linked SSO account acted without asking. An SSO-only account can no longer remove its last SSO link.
- After a 2FA or SSO login, LDAP and OIDC users were offered "Change Password" until the page was reloaded.
- Admins could not remove a locked-out user's 2FA from Edit user. Settings -> Users -> Edit user now has "Disable 2FA".
- Users without **settings:read** got default values for settings many pages need: with billing on, the print dialog hid the cost centre picker and the print was refused, and the queue order, Slice in the File Manager, filament warnings, Spoolman mode, theme and currency were wrong too. These settings now reach every signed-in user, without credentials.
- A project's bill of materials could show the names of archives from printers outside the user's groups.
- Adding archives or queue jobs to a project, or removing them, accepted archives and jobs from printers outside the user's groups and other users' prints. **Assign to project** now reports how many were actually added.
- Editing an archive could move it to a printer outside the user's groups, or link it to a printer or project that does not exist.
- The "Password Reset" email template was never used, and its default text still promised a new password. The reset email is now built from the template with the reset link added at the end.
- Removing live-update or camera permission from a group, a user or an API key did not end open dashboards, camera views, camera links or Cam Wall and Home Assistant camera tokens.
- An open camera view kept showing live video after a password change, deactivation, revoked token, group change or similar. Streams now re-check every 30 seconds that the viewer may still watch.
- Signing a user out everywhere (password change or reset, 2FA removal, deactivation, backup restore) left their open dashboards receiving live updates. Turning authentication on and disabling or expiring an API key now close the dashboards they opened too.
- A deleted API key's open dashboards and camera and WebSocket links passed to the next key created on SQLite.
- With login off, any unexpected error was reported as "Authentication service temporarily unavailable" (503), and with login on a brief database hiccup signed you out. Errors are now reported as 500 and logged, and a hiccup is retried.
- Permissions removed from a group, such as View and Import MakerWorld, came back after a restart (#3238, reported by @Minebuddy).

**File Manager:**

- A large tag catalogue pushed the file list off the page (#3411, reported by @iammenasco). Tags now take up to two rows, with Show all and a tag search.
- The File Manager's toolbar ran past the edge of a phone screen and pushed the page sideways (#3295, reported by @apizz).
- Changing a library file's folder through the API could move it into or out of an external folder without moving the file. See **Before you update**.
- A slow folder listing on the printer showed as "printer unavailable", and every refresh started another listing.
- Printer files written in the evening could be dated a year back on hosts behind UTC, so their camera recordings were not matched to their prints.
- Uploading two files with the same name showed the first file's result on both rows.
- Opening a printer's 3MF in the file browser downloaded the whole file again for the plate list and every plate thumbnail.
- Printer file downloads and previews reported every failure as "File not found", and large files hit a fixed 10-minute limit. They now get the time their size needs, up to 30 minutes.
- A timed-out printer download kept running beside its retry.
- Large STL files froze the web interface and printer updates while their thumbnail was made.
- The File Manager and Archives page loaded every thumbnail at once, slowing down the server. Thumbnails now load as they scroll into view.
- File names could vanish from the File Manager's list view when the folder sidebar left little room (#3105, reported and contributed by @akshayy29 in #3119).

**Interface:**

- The full-page G-code preview stayed black and the scrollbar flickered on wide screens with classic scrollbars (#3371, reported by @Underscan007).
- The print dialog's slot picker was too narrow to read on a phone held upright (#3294, reported by @apizz).
- The Printers page sent hundreds of requests on a print farm, about 550 with 59 printers, so cards took up to 20 seconds to fill. Requests are now combined.
- A bug report was filed as a public GitHub issue the moment debug logging stopped, also on the 5-minute auto-stop (#3363, reported by @choumarin). You now review it before submitting.
- Check Belt Tension on a P1 printer linked to a general maintenance page instead of Bambu Lab's belt guide (#3302).
- Removed the "Save thumbnails" and "Notification Language" settings, which did nothing. See **Before you update**.
- The printer temperature history retention had no setting, and a retention of 0 set through the API wiped all history. See **Before you update**.
- "Max copies per run" and the Docker compose directory were never saved, "Default printer" and "Auto-archive prints" were never used, and "Create Archive Entry When Printing" did nothing. See **Before you update**.
- Importing or creating a project could give it a priority or status the project editor refuses, making it uneditable, and failed on PostgreSQL. Such projects now get **normal** and **active**, also when restoring an older SQLite backup onto PostgreSQL.
- A tab whose live connection was closed by the server froze until reloaded. It now goes to the login page if the session ended, or reconnects.
- A project's timeline stayed empty while one of its jobs was queued or printing.
- Printer cards never showed the last print, nor the Good / Reject prompt for it. The cards now share one request instead of one per card.
- The Printer Locations page had no way back to the Printers page. It now has a "Back to Printers" link.

**Integrations (Home Assistant, MakerWorld, Spoolman, API):**

- Every MakerWorld import, Save and Save & Slice failed with "MakerWorld did not return a download URL" from 3 November on (#3447, reported by @waynem-bris; #3448, reported by @frederic3114).
- Home Assistant's connection test said "Could not connect" when the problem was an untrusted https certificate (#3300). It now names the certificate problem and what to do.
- An API client reading right after a successful write could miss it, and a save that failed at the end was hidden behind a success (#3320, reported by @MorganMLGman).
- The legacy `PUT /settings/virtual-printer` route answered 200 for settings it no longer applies. See **Before you update**.
- `GET /queue?status=pending,printing` with several statuses returned nothing.
- A request with `Infinity` or `NaN` in a field that failed validation ended in a server error instead of 422.
- Home Assistant "Run when printer turns off" scripts ran only when the plug was switched by hand, not on auto-off, schedules or failure detection. See **Before you update**.
- A truncated or broken MakerWorld download was stored as the model's 3MF.
- Unused API pieces were removed and the rest documented. See **Before you update**.
- The archive export's `date_to` left out the whole end day, and an invalid print speed answered 500 instead of 422.
- An id of `0` when queueing, creating a batch or creating a project skipped the existence check, causing a server error on PostgreSQL or a link to nothing on SQLite. `0` now means "none", and batches check their archive or library file.
- A smart plug or virtual printer could be linked to printer `0`. It is now refused with "Printer not found".
- `null` for a field that can't be empty caused a server error on about a dozen PATCH/PUT routes. It now leaves the field unchanged, as on other routes.
- The `/webhook/...` routes answered a database problem while checking the API key with a 500. They now answer 503, and 401 for an invalid key.
- The MQTT relay never sent `smart_plugs/energy`, sent `smart_plugs/on` and `/off` only for manual switching, and `maintenance/alert` always reported 0. All three now match the wiki.
- The webhook endpoints listed in **Settings → API Keys** didn't exist or had the wrong path.
- A valid API key could be refused as invalid during a brief database problem. It now answers 503, which a client can retry.
- Stopping or cancelling a print through the API failed with an error, and `cancel` left the print running. Both now work, count as stopped rather than failed, and `stop` also stops a paused print.

**Install, platform and database:**

- Restoring a Git backup brought back archives without their prints, so statistics and the Print Log were empty. Backups now include prints, and older backups restore as before.
- The connection diagnostic told containers on a Docker macvlan network to switch to host networking (#3417, reported by @ddavidebor). It now recognises macvlan and ipvlan, and warns about ipvlan L3.
- Deleting a local backup failed silently when the server refused it.
- A print running when a Git backup was made came back as a failed print after restore, with a failure notification. It is now restored as cancelled.
- Spools came back from a Git backup restore as never used.
- A Git backup restore brought every reset "Total Consumed" counter back to its full lifetime figure.
- The virtual printers kept running during a backup restore.
- Restoring an old SQLite backup onto PostgreSQL could put some timestamps hours off.
- A GitHub backup restore copied damaged or hand-edited numbers into the totals. Invalid values are now left empty and listed in the restore summary.
- Bug reports kept the reporter's email locally. Stored emails are cleared at startup.
- An in-app update that hung blocked every further update until a restart. Each step now has a time limit.
- The SpoolBuddy installer in full mode, installed under /home, wrote a Bambuddy service that failed with 203/EXEC (also #1685).
- SQLite gave a deleted user's, API key's, printer's, archive's or camera token's id to the next one created. These tables now never reuse an id; existing databases are converted once at start.
- On SQLite, deleting archives, library files, queue jobs, batches or projects left references behind, so a queue job could print a different file and a new project could show a deleted one's files. Deletes now clean up as on PostgreSQL, and each start repairs what earlier deletes left.
- PostgreSQL databases from older versions were missing links a new install has, so deleting an archive, user or library file left their id behind, and 51 columns differed from a new install. They are fixed on the next start.
- Each install or update took whatever Python dependency versions were newest that day. They are now pinned to tested versions.
- Native installs on Python 3.10 failed to start while the installer and docs said 3.10 was enough. Python 3.11 is now required, and the installer picks up `python3.11` on Ubuntu 22.04.
- Every PostgreSQL start logged about 320 errors from migrations that had already run. PostgreSQL 13 or newer is required.
- Shutting Bambuddy down logged an error with a traceback when nothing was wrong (#3243, reported by @Thomansky).
- Running out of file descriptors could corrupt a SQLite database (#2883, reported and contributed by @M2ABRAMSTANK in #2884). Bambuddy now raises its open-file limit at start and uses a smaller SQLite pool.

**Security (dependencies)**

- `dompurify` to 3.4.17, `zod` to 4.6.7 and Vitest to 4.1.12. Bambuddy did not use the affected DOMPurify options; zod and Vitest are development-only and not in the shipped image.
- `virtualenv` to 21.14.9, `filelock` to 4.2.1 and `setuptools` to 84.1.0, all development-only and not in the shipped image.
- `pyasn1` to 0.6.5 and `minimatch` to 11.0.4. pyasn1 ships with LDAP sign-in, where crafted input could cost excessive time or memory; minimatch is development-only.

**Merged community PRs in this release**

- #1606 by @samedyuksel - assign a spool by scanning its QR label.
- #2803 by @grolmus - map each printer against its own AMS, hold jobs whose filament isn't loaded.
- #2884 by @M2ABRAMSTANK - SQLite pool and open-file limit.
- #2995 by @SVAN19 - printer locations page.
- #3119 by @akshayy29 - File Manager list column widths.
- #3207, #3208, #3209 by @adamspicedev - overlay token creation and URL import, logo and progress colours, portrait layouts.
- #3233, #3306 by @rojosinalma - lifetime energy total for REST plugs, moving folders in the File Manager.
- #3252 by @Niko11111 - Spoolman native tags.
- #3255 by @chrisbennight - Bambuddy Internal URL for Obico.
- #3265 by @simplytoast1 - Notify! with Live Activities and Lock Screen widgets.
- #3283 by @bgrr74 - remaining time in the browser tab.
- #3346 by @Thomansky - full tag UIDs on the SpoolBuddy PN5180 reader.
- #3369 by @andy-sorge - P2S printer picture.
- #3378, #3389, #3390 by @hibikipr - reliable Bambu tag reads on SpoolBuddy, Bambu tag data with each scan, Quick Add from a scanned tag.
- #3381, #3393 by @pleasantone - Orca Cloud printer lists, sorted and searchable Slice dialog presets.
- #3385 by @koshilki - custom label sheets and saved templates.
- #3413 by @oh-forf - `DB_POOL_PRE_PING`.
- #3428 by @QuinnDamerell - OctoEverywhere AI failure detection (brought in by hand).

**Thanks**

To everyone who requested, reported, captured logs, or contributed: @0xCyberFortress, @aammash, @adamspicedev, @airforceixi, @Akaviiii, @akshayy29, @Andrewdlec, @andy-sorge, @apizz, @bdwilson, @BenBBSLA, @BenjaminCs, @bgrr74, @bobobo1618, @BurgerKerman, @cartman75, @choumarin, @chrisbennight, @CLKRUN, @cmerkle, @dadino, @ddavidebor, @dogod3814t, @dovmesiz, @Eifel-Joe, @elizabethburg, @erabti, @fma965, @frederic3114, @frnzzle, @gregspatrick, @grolmus, @HarryCoff2, @hibikipr, @HopNotch, @humplemann, @hyyz17200, @iammenasco, @ImNanou, @jasoncronje, @juandelarossa, @Keybored02, @koshilki, @lightmaster, @Lioncat55, @lonix, @lukg20, @M2ABRAMSTANK, @Magical-Penguin, @mason9468, @McGagnor, @Minebuddy, @mithkr, @MorganMLGman, @Mounting9612, @MrCrunshy, @Niko11111, @Novastorm4332, @nvx, @oh-forf, @ojimpo, @pleasantone, @QuinnDamerell, @RambachTJ, @rogerabm, @rojosinalma, @Roving-Ronin, @SaadShaya7, @samedyuksel, @sargonas, @Sawtaytoes, @sean3318, @sgiffhorn, @simonkreuchauff-oss, @simplytoast1, @Spegeli, @SVAN19, @Thomansky, @Underscan007, @USER19464727, @waynem-bris, @wolfrage76, @wreuel.

---
**Sponsors**

Bambuddy is sustainable thanks to people who put their money where their use is. If this release saved you time or kept your farm running, the project runs on recurring contributions - there's no paid tier, no telemetry, no upsell, just sustainable maintenance.

- GitHub Sponsors (recurring, 5 tiers from $5/mo to $300/mo) - https://github.com/sponsors/maziggy
- Ko-fi (one-time or recurring) - https://ko-fi.com/maziggy

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
