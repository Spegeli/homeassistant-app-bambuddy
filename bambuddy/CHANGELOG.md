## 1.2.5.3

**Bambuddy 1.2.5.3**

**What this is**

A feature-and-fix release on top of 1.2.5.2, with four things carrying most of it: the slice dialog gains OrcaSlicer's full process-parameter set, the G-code and model previews are rebuilt on the slicer's own renderer, the H2C's six-hotend nozzle rack can finally be aimed rather than guessed at, and selected categories can be restored from a Git backup commit. Around it are 39 fixes, a heavy run of them on AMS drying, slicing and the queue. Five of the features come from outside contributors. No breaking changes. Several table and column additions are applied automatically on both SQLite and PostgreSQL.

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

Download bambuddy-1.2.5.3-windows-x64-setup.exe from this release page (or the unversioned bambuddy-windows-x64-setup.exe alias). Existing Windows installs upgrade in place via the in-app Install Update flow.

**New**

- Billing and cost centres, with per-print charging and budgets (#1448, contributor @behrinml) — Bambuddy could tell you what a print cost but could not hold anyone to it. There is now a finance layer behind the print flow: cost centres with budgets, per-user wallets, and a transaction for every print. A cost centre can be picked in the print dialog, travels with the queue item and the archive, and is reserved against before the job is dispatched rather than after it finishes, so a print that would take a budget past its limit does not start. Charges settle on real filament usage at completion, and a print that aborts part-way is charged for the part that ran instead of being written off or billed in full. Every user gets a personal cost centre and wallet on first sign-in, including the first sign-in through LDAP, so a directory-backed install does not need them created by hand. A monthly reset day and timezone decide when budgets roll over. The whole feature is behind a billing toggle and is off by default, and an optional printer kill switch stops dispatch entirely once a budget is exhausted. Cost-centre management has its own permissions rather than riding on the settings ones, so a farm can let someone spend against a budget without letting them change it. Ships with a Finance page, migrations for both SQLite and PostgreSQL, and translations in all locales.

- One queue item, several printer models — whichever frees up first (#671, reporter @brainomite; also delivers most of #2570, reporter @NeighborGeek) — With an H2S and an H2C, a job you don't care which machine runs still had to be queued twice: the two printers need different slices, a queue item held exactly one file, and "any H2S" and "any H2C" were separate jobs competing for the same plastic. Whichever started first, you deleted the other by hand. Select both sliced files in the File Manager and press **Print** and you now get **one** queue item carrying both — the scheduler walks them in the order you arranged and takes the first whose model has an idle printer. The many-to-many never leaves the scheduler's selection loop: the moment a candidate wins, its file, plate and nozzle mapping are folded onto the queue row, so the upload, archive creation, print history and reprint all see an ordinary single-file job and behave exactly as they always have. Order is yours to set, because "both are free right now" has to resolve the same way every time rather than following whichever match the matcher happened to see first. Candidates are otherwise tried least-attempted first, so a printer that accepts the file and never starts hands the job to the other machine on the next lap instead of spending the item's whole retry budget on the one that is wedged. The set is validated as a set: one file per printer model (two slices for the same machine are not alternatives, and picking between them arbitrarily would look like a bug the first time it chose your draft profile), every file gated against the model it is offered as, and at least one model that actually has a printer — grouping the H2C slice before the H2C arrives is fine, queueing a job nothing can ever run is not. A cross-model item deliberately holds no file of its own, so deleting one alternative leaves the job and its sibling intact; deleting or trashing every candidate holds it with an explanation instead of failing deep in the upload. Filament overrides offer everything loaded across **all** the candidate models rather than just the first — a spool loaded on only one of them is still a legitimate choice, it simply narrows which candidates can match — while AMS slot mapping is absent exactly as it is on an ordinary "Any [model]" job, because no printer has been picked yet and the scheduler derives the mapping against whichever one it takes. In the queue the job reads **Any H2D / X1C**, naming every model it is waiting on rather than filing itself under one it may never run on, and its waiting reason is given per model (`H2D: Busy: H2D-1; X1C: No matching material/color`), collapsing to a plain busy message — and no notification — when every model is merely printing. The alternatives are fixed once queued: the schedule, quantity and print options stay editable, but assigning a specific printer or narrowing to one model is refused by both the dialog and the API, since an item holding alternatives *and* a printer would dispatch down the fixed-printer path with no file to send. Cancel and re-queue to change the set. Files can also be grouped permanently with **Group as versions**, after which printing any one of them offers the others without re-selecting — this is the grouping and the print-time file matching asked for in #2570, minus its nested File Manager listing. An existing library arrives with its groups already built, from slice provenance Bambuddy has been recording since the Slice button shipped and had never read back. Translated in all locales; wiki updated. Covered by backend and frontend tests.

- Batch orders: a quantity per plate, and an order that knows what it still owes (#342, reporter @cimdDev) — Printing a multi-plate file in different quantities per plate meant queueing each plate separately and tracking the counts yourself, because one shared **Quantity** field cannot say "plate 1 once, plate 2 twice, plate 3 three times". Each selected plate of a multi-plate file now carries its own quantity, and the submission becomes a **batch order** on a new **Batches** tab of the Print Queue page. What that buys is the distinction the old batch could not express: the order records how many runs of each plate were *wanted*, separately from what was queued. A run that fails, is cancelled or is skipped does not satisfy a target, so the order goes on saying it owes a print instead of quietly under-delivering — and a **Queue remaining** action re-queues exactly what is missing, for the whole order or one plate. Those new items are copied from the most recent run of that plate, so they inherit the printer or model target, AMS mapping, filament overrides and print options already chosen, and they are appended to the end of the relevant printer's queue rather than jumping ahead of work already lined up. Orders show progress against target, per-plate breakdown, and cost. Cost is measured rather than estimated: each finished run's material and energy are attributed through the queue item that produced them, so an unrelated reprint of the same file never lands in an order's total, and a multi-plate order gets each plate's own cost rather than the whole file's. Before any run has completed there is no honest figure, so cost reads as unknown instead of a fabricated `0.00`. An order becomes **completed** the moment its last run lands rather than whenever someone next opens the page, and raising a target on a finished order reopens it. Targets stay editable while the order runs, since production requirements change mid-job. The default flow is unchanged — creating an order still queues all of it immediately, and a single-plate file still has one Quantity field. Batches created before this release keep working and are labelled **Grouping only**: they only ever knew what was queued, not what was wanted, so they report progress but have nothing to dispatch. They also get closed out on the first start after upgrading — `completed` was not a reachable status before now, so every batch created since grouping shipped is still marked active however long ago its last print finished, and without that pass the new tab would open on months of accumulated history. Only batches with nothing queued or printing are touched: those whose runs all completed become completed, and groupings whose items were all cancelled become cancelled, which is what they are — calling them completed would claim output that never happened. Batches with neither queue items nor targets are no longer listed at all; those are empty shells left behind when a grouping's items were deleted with their source archive. Translated in all locales; wiki upd
ated. Covered by backend and frontend tests.

- Nest projects under a master project and roll their figures up (#1264) — Projects were flat. The `parent_id` column and the sub-project list already existed but nothing outside the API could set a parent, and a master project's statistics only ever covered its own prints. The project dialog now has a parent picker, and a project with sub-projects gets a second card covering the whole tree: jobs, parts, time, filament, cost, and progress against every target in the tree added together. That card is deliberately separate from the project's own stats, which keep their existing meaning — widening them would have restated the figures of anyone who had already nested projects over the API. Each listed sub-project carries its own branch's roll-up, so the rows add up to the card above them. On the Projects page a sub-project is drawn inside its parent's group rather than as another card in the grid, because two cards columns apart cannot show that they belong together whatever the caption says. Translated in all locales; wiki updated.

- Keep the chamber warm between prints and skip a soak that is not needed (#2727, contributor @ticfinack) — Back-to-back prints in chamber-heated materials — ASA, ABS, PA, PC — each paid a full heat soak from cold, even when the print that just finished had left the chamber at temperature. Two changes remove that cost. While a printer sits in FINISH waiting for plate-clear and the next queued item needs chamber heat, the bed is held hot so the chamber does not cool during the bed-clearing window. The bed is the chamber's heating element here rather than a print surface, so the hold runs at the new **Keep-warm bed temperature** (90 °C by default, which also satisfies the aftermarket chamber heaters that trigger off a bed threshold) and rises to the item's own bed temperature when that is higher. It is gated on the keep-warm setting, on plate-clear being required, and on the next item actually needing the heat, and it is capped by a maximum duration so a queue that stalls does not leave a bed hot indefinitely. A follow-up closed the two dispatch exits that could drop the hold without releasing it — a claim failure returns before the rollback opens, and a vanished row left the printer id unset, which the rollback guards on — either of which left a bed hot with nothing tracking it, reachable whenever a cancel or delete landed between selection and the claim.
- Restore selected categories from a Git backup commit — Bambuddy has pushed backups to GitHub, GitLab, Gitea and Forgejo for a while; now it can read one back. Pick a commit, preview what it holds, choose which categories to restore (#2656, contributor @jmoore-skild).
- Edit the full print-parameter set from the slice dialog — the dialog now carries OrcaSlicer's own process tree, with its pages, groups, tooltips and ranges, and evaluates the slicer's own enable/disable rules. Slicing no longer means taking a preset exactly as it comes.
- A new G-code and model preview — the vendored PrettyGCode iframe is gone, replaced by libvgcode, the renderer OrcaSlicer draws its own preview with. Real occlusion instead of screen-space lines, and it is themed and translated like the rest of the app. The model preview was rebuilt alongside it, with proper framing and lighting.
- Choose which rack nozzle each filament prints from on an H2C (#1784) — the Vortek rack holds six hotends and the choice is not recorded in the 3MF, so plates went out with no assignment and the printer picked for itself. Every rack-bound filament now has a position picker showing all six and the nozzle each holds.
- Home Assistant sensors on the printer card, with an optional print interlock (#1148, reporter @bsaunder; #448, reporter @baudneo) — surface HA entities on the card, and optionally block a print from starting when one of them says not to.
- The Print Log shows how much filament a run used, and lets you choose its columns (#2636, reporter @ajbastien).
- Auto-orient and auto-arrange when slicing server-side (#2548, reporter @ceokingcobra).
- Open a File Manager model in your desktop slicer, and pick which one from the 3D preview (#2725, contributor @pascalheidmann).
- Server-side slicing on an ARM64 host (#1900, contributor Felix Reissmann) — an override pins the sidecar to amd64 and runs it under emulation, with the binfmt requirement and the three-to-six-times slowdown stated up front. A separate x86_64 machine is still the recommendation.
- Temperatures on the streaming overlay, and a builder for its URL (#1422, reporter @SMAW).
- Open a multi-plate sliced file on the plate you asked for — the viewer gains a plate switcher and keeps the choice in its URL, and filament colours follow it instead of always coming from the first plate.
- Show the plug that actually powers the printer in the card's Power row (#2830) — which plug filled that row was previously decided by nothing at all, so it could land on an enclosure fan and offer to switch the printer off by cutting it.
- The Printers page remembers its status and location filters (#2833) — the only two preferences on that page that were not persisted.
- The external spool can be hidden from the printer card (#1782, reporter @Arn0uDz).
- Uploaded archives can be named after the filename you sent (#2610, contributor @Person2099).
- The chamber temperature limit is raised from 60 to 65 °C (reported on Discord).
- The Spool Inventory can be sorted by colour rather than by colour name (#2729, reporter @macwhiz).
- API keys can read and run slicer pipelines (#1425) — every pipeline endpoint answered 403 to a key whatever scopes it carried. Running a pipeline requires the queue and library-manage flags together, and a 403 now names every flag the key is short of.
- API clients can resolve user ids to names (#1894) — archives, the queue and statistics report ownership as a numeric id, and nothing let a key discover whose id was whose without an admin listing.
- Forgejo tokens scoped to a single repository are accepted (#2775) — a repository-scoped v15 token was rejected for failing a user lookup it does not need to pass.
- The MQTT debug log records the commands sent to a printer, not only what it reports back.
- Queue items created from the Library's bulk Add to queue and through the webhook API now record who created them, so own-work permissions can see them.

**Fixes**

**H2C and multi-nozzle:**

- An H2C levelled on one hotend and printed with another, several millimetres above the plate (#2800). A print command names the rack nozzle by physical position rather than by extruder index, and Bambuddy only ever had that position for jobs arriving through the Virtual Printer — everything else omitted the field and let the firmware choose. Two hardware-derived values were then corrected by the reporter's own A/B on real hardware, and the fixed/rack carriage assignment turned out to be inverted.
- An H2C refused a multi-colour print outright with HMS 0500-4047, a hotend mismatch: on a rack machine the slicer writes a filament group per nozzle rather than per carriage, so a three-group plate lost a filament against a two-entry map.
- The H2C nozzle rack card sizes itself to its contents instead of claiming several hundred pixels and leaving them empty, numbers its slots 1 to 6, and scales its chips with the card size.

**AMS, drying and filament:**

- AMS drying was torn down and restarted once per scheduler tick while a plate sat unacknowledged — about 2000 state changes over ten days, with no cycle ever running long enough to remove moisture, and hand-started cycles on other units of the same printer torn down with them (#2801).
- Auto-drying re-armed into a threshold it could never reach (#2770) — an AMS reads a higher humidity warm than cold, so the reading at the moment a cycle ended always armed the next one. Five twelve-hour cycles inside four hours.
- A drying cycle the printer abandons now says so, and says what the printer reported (#2770, reporter @tchavei).
- A drying cycle no longer reports itself finished a minute after it starts (#2759).
- The drying badge invented a temperature on a uniformly loaded AMS, showing the spools' RFID recommendation rather than the temperature that was picked (#2759 follow-up).
- The drying popover no longer starts a cycle under a material you did not pick (#2774).
- The nearest filament colour is picked instead of the first eligible one in tray order, and the ranking is perceptual — RGB distance overweights blue badly enough to invert the answer (#2804, #2823, contributor @grolmus). Filament type matching also agrees between the interface and the scheduler now.
- Spoolman no longer charges a Bambu Studio print to the wrong spool (#2768).
- "Any X2D" works on a printer that feeds from external spools instead of an AMS (#2771, reporter @Nick-C130).
- AMS Filament Backup no longer charges a whole print to the substitute spool — everything needed to split the filament across the trays it actually came from lived only in memory, so a print that outlived a restart lost it.
- The print dialog pools AMS Filament Backup spools in its filament check, instead of refusing a job against one slot while an identical full spool sat in the next one.
- A refused AMS filament setting now says so in the log (#2756, reporter @Jostxxl).
- Configuring an AMS slot shows up on the printer card straight away, without a page reload.

**Queue and dispatch:**

- A completion for one print closed another print's queue item, marking it completed while the printer was still working and stranding the rest of its batch (#2829). The check that fixes it also had to learn that the printer rewrites the name it echoes back, which had left queues stopped until someone cancelled by hand.
- Deleting a library file destroyed the jobs queued against it — silently on PostgreSQL, and as "Library file not found" days later on SQLite (#2819).
- A library-backed job was dispatched onto a spool that could not finish it: 20.5 g needed, 9 g loaded, no deficit reported (#2779). Slicer pipeline jobs and everything from the Library's bulk add were affected.
- A job queued to a printer class never powered a printer on, while the same file pinned to a specific printer did (#2786).
- A print that never starts now says AMS drying was running, instead of blaming the SD card (#2758).

**Slicing and previews:**

- A slice failed on a model whose name contains a slash — a MakerWorld title arrives with its punctuation and was used verbatim as a folder name (#2832).
- A slice of a file on a network share was written to managed storage instead, showing up in the right folder in the interface and never reaching the share (#2810).
- A 3MF no longer switches off supports its process preset turned on (#2820) — the carry that lets a project's support configuration survive was running in both directions.
- An oversized model reads as an oversized model, not a slicer crash (#2802). The advice to update the sidecar was wrong too: it named a bare compose pull, which skips the profile-gated sidecar silently.
- A preview slice no longer gives up on custom G-code the sidecar cannot parse — the silent fallback to guessing from painted faces was dropping a whole filament slot.
- Bundled presets resolved their start G-code to a generic block: all 56 instantiable BBL machine presets, producing a print that heats the bed, moves the toolhead and extrudes nothing.
- The process-settings panel shows the preset's own values instead of the compiled-in defaults, and names which of four causes applied when it cannot read them.
- Server-side slicing is no longer offered for STEP files, which neither slicer can load from its command line. Open in Slicer still hands them to the desktop application.

**Printers, archives and connection:**

- Archives arrived empty from printers whose file service could not answer (#2780). Two faults: H2-series and P2S firmware can keep the sliced file on internal storage, which port 990 cannot reach — the print command says which, and we discarded it and swept anyway, around 110 doomed connections per print. And a printer whose FTPS handshake wedges now gets a five-minute cool-off instead of being retried hundreds of times a minute; one reporter's log carried 1813 identical failures, another's 3511.
- Photos and filament accounting on archives that arrive without a 3MF, which on an H2S is any job started from the printer's own library (#1820). Photos were written in one place and looked for in another, and the fallback that stands in for a missing 3MF could charge nothing without a word.
- The printer card thumbnail is back after navigating away and returning (#2826) — a cache hit raced the mount effect, which is why it reproduced every time for the reporter and never here.
- Live updates stopped arriving while the Bambuddy tab was in the background (#2754, reporter @mic4rd).
- A print stage Bambuddy cannot name is now logged at INFO, once per stage number per session, with the context needed to name it afterwards.

**Interface:**

- Interactive controls show a pointer cursor again (#2791) — Tailwind v4 dropped the base rule and only 15 of 934 buttons had it written by hand.
- The Spool Inventory header no longer scrolls the whole page sideways on a phone (#2813).
- The Virtual Printer card header wraps instead of painting outside its border (#2808).
- A refused frame no longer leaves the browser's own error page inside Bambuddy's layout, and says which header blocked it (#2787).
- Form controls follow the page's colour scheme — steppers, calendar buttons, dropdowns and scrollbars were drawn light on every theme.
- The L and XL printer cards scale their text and icons, not just their width (#1848, reporter @misterff1).
- The bug-report button no longer covers the controls in the bottom-right corner (#2750, reporter @goodjaltman).
- Error and warning toasts stay up twice as long.
- The Print Log is reachable again once you have no archives, and its cost and energy figures reach the browser at all.
- The Docker update command is copyable, and knows where your compose file lives (#2664, reporter @pchulpjoost).
- The Slicer Bundles notice is gone from Settings — bundle import was withdrawn in 0.2.5 and the panel had been sitting there since, unactionable.

**Login, deployment and integrations:**

- LDAP login works again on directories that define no POSIX group class (#2769, reporter @peterskotte).
- A hand-written systemd service left the Virtual Printer unable to start, with nothing obvious to blame (#2549, reporter @Ru3ck3).
- Bambu Cloud's anti-robot challenge is explained instead of repeated back as a bare error with nothing to click (#2790).
- Home Assistant notifications carry nested data through unchanged (#1441).

**Security (dependencies)**

- Cleared every remaining npm audit and pip-audit finding. react-router and react-router-dom move to 7.18.2, which retires the documented CSRF exception in the CI audit gate — upstream backported the fix, so the exemption lapsed on its own and the allowlist is now empty. dompurify moves to 3.4.13 (shipped, but on a path this app never reaches: no hooks registered, in-place mode unused). js-yaml and nanoid are overridden, both development-only via eslint and postcss.
- Patched two build-time frontend dependencies flagged by npm audit (GHSA-r28c-9q8g-f849, GHSA-mh99-v99m-4gvg, GHSA-rgw5-rvv9-x895).

---
**Sponsors**

Bambuddy is sustainable thanks to people who put their money where their use is. If this release saved you time or kept your farm running, the project runs on recurring contributions — there's no paid tier, no telemetry, no upsell, just sustainable maintenance.

- GitHub Sponsors (recurring, 5 tiers from $5/mo to $300/mo) — https://github.com/sponsors/maziggy
- Ko-fi (one-time or recurring) — https://ko-fi.com/maziggy

