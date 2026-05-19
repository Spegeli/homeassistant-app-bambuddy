## 0.2.4.2

  **Bambuddy 0.2.4.2 — Release Notes**

  **A note on the 0.2.4 train going forward**

I've decided not to add any further features to the 0.2.4. train.* Everything between now and 0.2.5 will be bug fixes, security patches, and stability work only. The goal is to get this train as rock-solid as it can be before the next feature wave lands in 0.2.5. New features that arrive in the meantime queue up against the 0.2.5 milestone — not 0.2.4.x.

(The handful of feat: items below were already merged into the 0.2.4.x branch before this decision and are shipping with the release. Starting now, only fix:, security:, and chore: go in.)

  ---
  **Highlights**

- FTP reliability: two long-standing flakes finally pinned down — the silent-success-on-426 upload bug (#1401) and the transient-426-on-already-uploaded-file (#1417 follow-up). Combined, these were the largest single source of "print sometimes won't start" reports.

- Virtual Printer queue / immediate / review modes: AMS no longer flickers or disappears in BambuStudio against P1S/A1 targets between pushalls (#1387). And VP-queue dispatched prints now inherit timelapse/bed-leveling/flow-cali/vibration-cali/layer-inspect from the slicer instead of always reverting to defaults (#1403).

- Stats page: the post-0.2.4.1 stats rewrite left Filament Used / By Time / Success Rate misaligned with Total Consumed and Total Prints (#1390). Fixed, plus the pre-upgrade Filament Cost = 0 / empty Time Accuracy regression in Quick Stats.

- H2S without AMS: the H2S was misclassified as dual-nozzle and refused to start prints when no AMS was attached (#1386). Fixed.

- Spoolman parity: editing a spool no longer mints duplicate filaments in the Spoolman catalogue (#1357 follow-up); Color Name edits now persist (Spoolman has no filament.color_name, so it lives in spool.extra now); "Reset usage to 0" and "Print labels…" both work in Spoolman mode; Settings → Filament now shows the same Spool Catalog UI in both modes.

- Self-signed CA support (Docker): opt-in via USE_SYSTEM_TRUST_STORE=1 + mounting your CA into /usr/local/share/ca-certificates. The Debian system bundle stays alongside your CA — so api.github.com, MakerWorld, and Bambu Cloud keep working. Default-off, fail-fast on misconfig. (#1431, contributed by @WizBangCrash, requested in #1289)

- Security: urllib3 bumped to clear CVE-2026-44431 / CVE-2026-44432; ws dev-dep bumped (#1433); GitHub backup now refuses to save against a non-private repository.

  ---
  **Added**

- Docker: opt-in system trust store for self-signed CAs (#1431, @WizBangCrash, req. in #1289)

- Inventory: Storage Location filter chip (#1400, req. by @pgladel)

- Inventory: "Reset usage to 0" — per-spool and across all active spools, in both internal and Spoolman modes (#1390 follow-up, req. by @IndividualGhost1905)

- Inventory: spool ID surfaced in edit modal and AMS hover card (#1385, contributed by @chanakyan-arivumani in #1402, reported by @pgladel)

- Print labels: sort by colour as an alternative to spool-ID order (#1410, req. by @elit3ge)

- Smart plugs: auto-off after AMS drying completes (#1349, req. by @Kyobinoyo)

- Camera: in-app diagnostic for "Connection lost" (#1395 follow-up)

  **Changed**

- AMS Filament Label Holder presets fixed and split into "small" and "large" variants (#1426, @bsaunder). The incorrect 30×15 mm preset is replaced.

- Archives → Print Log: filename column expands to fit available width and wraps long names instead of clipping at 200 px (#1406, req. by @daFreeMan)

- Bulk & scheduled archive purge now honour the soft / hard delete choice that single-archive delete already exposes (#1390 follow-up)

- Cloud login: corrected the access-token hint to reflect that Bambu Lab no longer surfaces the token in any UI; called out the China-region MakerWorld cookie path explicitly (#1396)

- Settings → Filament: Spool Catalog now shows the same UI in Spoolman mode as in internal-inventory mode

- GitHub backup: save-failure messages render inline on the card instead of as a toast

  **Fixed**

  **FTP / upload**

- FTP upload no longer silently treats 426 Failure reading network stream as success (#1401 root cause #2, @iitazz)

- FTP: tolerate transient 426 when the file is actually intact on the SD card (#1417 follow-up, @enjoylifenow)

- Upload validation rejects unprintable 3MF / raw-gcode files at the upload step instead of letting them fail at the printer (#1401, @iitazz)

  **Virtual Printer**

- AMS data flickering / disappearing in BambuStudio between pushalls on P1S/A1 targets (#1387)

- VP-queue dispatched prints inherit timelapse / bed-leveling / flow-cali / vibration-cali / layer-inspect from the slicer (#1403, @pwostran)

- Archives: "Scan for timelapse" no longer permanently disabled on VP-queue-dispatched prints (#1403 follow-up, @pwostran, @enjoylifenow)

  **Inventory / Spoolman**

- Spoolman edit-spool no longer mints duplicate filaments in the catalogue (#1357 follow-up, @pgladel)

- Spoolman: Color Name edits now persist via spool.extra (#1357)

- "Reset usage to 0" no longer inflates remaining weight back to label_weight (#1390 follow-up, @IndividualGhost1905)

- "Total Consumed" now includes archived spools' usage, and the eraser works on archived too (#1390 follow-up, @IndividualGhost1905)

- Add Spool modal: hex colour field can be typed into character-by-character again (#1407, @anthonyma94)

  **Stats**

- Filament Used / By Time / Success Rate now agree with Total Consumed and Total Prints after the 0.2.4.1 stats rewrite (#1390 follow-up, @IndividualGhost1905)

- Backfilled PrintLogEntry.cost / energy / archive_id for pre-#1378 rows so Quick Stats no longer shows Filament Cost = 0 / empty Time Accuracy (#1390)

- Per-event data now powers every widget, not just Quick Stats (#1390)

  **Camera / printer / AMS**

- P2S camera: relaxed ffmpeg probe so the RTSP stream actually locks (#1395 follow-up, @Tschipel)

- Per-model camera profile registry (#1395)

- AMS physically-empty slots now consistently report state=9 and render distinctly from reset slots (#1322 follow-up, @RosdasHH)

- H2S without AMS could not start prints — was misclassified as dual-nozzle (#1386)

- Adding a printer with a wrong access code (or unreachable IP) no longer creates an empty card

- Assign Spool: printer card refreshes immediately without needing Force-refresh (#1414 follow-up, @snozzlebert)

- VP cache: deep-merge AMS on bridge cache so P1S/A1 partial pushes don't nuke AMS (#1387)

  **SpoolBuddy**

- NFC reader works again on Raspberry Pi 5 — tolerate SPI_NO_CS rejection (#1424, @flom89)

  **Other**

- Library "Open in Slicer": works when the display name lacks .3mf or contains / \ ? # (#1413, contributed by @benhalverson in #1416, reported by @ddingg)

- Cover thumbnails: stop hammering FTP and GitHub when a print's 3MF isn't on the printer; negative-cache covers 404s, GitHub rate-limit backoff added (#1420)

- Archives: assign printer_id when reusing VP-queue archives in print-start (#1403 follow-up)

- Add Smart Plug (HA mode): entity search bypassed the schema's domain whitelist (#1388)

  **Security**

- GitHub backup refuses to save against a non-private repository

- urllib3 pinned to >=2.7.0 to clear CVE-2026-44431 / CVE-2026-44432

- ws dev-dep bumped (#1433)

- verify=False suppressions in support.py switched to bandit nosec syntax for cleaner static-analysis output

  ---
  **Upgrade notes**

- Container image: the Dockerfile now installs ca-certificates (~250 KB). No behaviour change unless you opt into USE_SYSTEM_TRUST_STORE.

- Database: no schema migrations required from 0.2.4.1.

- Compose template: the shipped template now contains a commented-out example block for the self-signed CA mount + env var. Existing compose files are unaffected.

  **Thanks**

Reporters and contributors who made this release: @WizBangCrash, @benhalverson, @chanakyan-arivumani, @IndividualGhost1905, @pgladel, @iitazz, @enjoylifenow, @pwostran, @Tschipel, @RosdasHH, @anthonyma94, @snozzlebert, @daFreeMan, @bsaunder, @elit3ge, @Kyobinoyo, @flom89, @ddingg, @anthonyma94. Plus everyone who reported the empty-card / wrong-access-code class of issues that didn't get a single issue number.

