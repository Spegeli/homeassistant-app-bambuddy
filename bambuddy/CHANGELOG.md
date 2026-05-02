## 0.2.3.2

  **Bambuddy v0.2.3.2**

  Follow-up release to 0.2.3.1 — fixes the H2D queue-reprint bug, the Clear-Plate button that took up to 5 minutes to appear after a print finished, and a handful of AMS, inventory and UI regressions. Adds an embedded GCode viewer for archived prints, plus a Printers-page touch: multi-plate prints now show the actual plate name on the card.

  **⚠ Upgrade Notes — Read Before Updating**

  The in-app Update button now works normally for users already on 0.2.3.x. If you are still on 0.2.2.x, you must do the one-time migration from the command line — see UPDATING.md.

  **Docker**

  Make sure your docker-compose.yml image: line points at :latest or :0.2.3.2.

  docker compose pull
  docker compose up -d

  Native install (install.sh or manual git clone)

  sudo /opt/bambuddy/install/update.sh

  update.sh snapshots the database automatically and rolls back on failure. Docker and fully-manual paths do not — take a backup first via Settings → Backup → Create Backup.

  Installed from a GitHub ZIP/tarball? Those installs have no .git directory and cannot be upgraded in place. See the UPDATING.md recovery procedure.

  ---

  **New Features**

  - (archives): embedded GCode viewer for archived prints (#963) — Archive cards now expose a "3D Preview" action that opens the sliced GCode of the archived print inside a vendored PrettyGCode viewer — right in the Bambuddy UI, no download step, no external slicer needed. Multi-plate 3MFs prompt a plate picker matching the Queue/Reprint flow.
  Bed size is auto-resolved from the archive's /capabilities data so H2D, X1C, A1 and A1-mini all render at the correct scale. Source-only 3MFs (no embedded GCode) show a toast instead of opening an empty viewer. Reloads in the viewer keep the Bambuddy layout shell via the SPA catch-all. Vendored JS library is AGPL-3.0 compatible with Bambuddy. Contributed by @Soopahfly.

  **Improved**

  - (printers): show plate name on card for multi-plate active prints (#881) — When two printers were running different plates of the same multi-plate 3MF, the Printers page cards displayed the same file name on both and there was no way to tell them apart. The card now resolves the active archive via MQTT subtask_id and renders the actual plate name (or "Plate N" fallback) — only when the source 3MF is multi-plate, so single-plate prints stay noise-free. Plate transitions reflect immediately via WebSocket push instead of waiting 30 s for the next REST poll.
  - (printers): remove redundant in-widget "Clear Plate & Start Next" button (#1079) — In expanded view, the yellow "Next in queue" widget rendered its own Clear Plate & Start Next button on top of the card-level button from #939 — two distinct affordances POSTing to the same endpoint. The widget's duplicate button is gone; the card-level button is now the single entry point. Compact-view (Size S) behaviour is unchanged.

  **Fixed**

- fix(queue): prevent duplicate dispatch and stale progress on batch prints — Two related queue issues surfaced when scheduling an ASAP print with quantity > 1; 
  1. Double-dispatch — both items in the batch ended up in 'printing' status on the same printer. 
  2. Progress bar flashed 100% — immediately after dispatch the queue item's per-row progress bar showed the prior print's final mc_percent for a few seconds, then snapped back to 0% when the new print started ticking
- (scheduler): watchdog falsely reverts slow H2D dispatches, causing reprints of the just-finished job (#1078) — On H2D, clearing the plate and starting the next (and only) queued item caused the printer to re-run the job it had just finished. Root cause: the _watchdog_print_start timer gave up at 45 s on H2D Pro firmware that routinely keeps gcode_state=FINISH for 48–55 s after accepting the command. The watchdog now treats a subtask_id advance as proof the command landed, and the timeout is raised to 90 s.
- (printers): "Clear Plate" button takes 30–300+ s to appear after print completes (#939 follow-up) — The WebSocket printer_status payload was missing awaiting_plate_clear, so only the 30 s HTTP fallback poll surfaced it — and on a chatty printer each WS tick bumped React Query's dataUpdatedAt, pushing the next fetch further out. printer_state_to_dict now emits the flag end-to-end.
- (ui): Change Password modal leaked password affordance onto Printers search field — Opening the Change Password modal rendered the Printers search input as a password field. Password managers were latching onto the unnamed text input as a "username anchor" for the three password fields in the modal. Added a proper hidden username anchor
  and hardened the search input with type="search", autoComplete="off", data-1p-ignore, and data-lpignore.
- (ams): keep PFUS preset id when cloud filament_id is null (#1053 follow-up) — After configuring an AMS slot (HT or regular) with a custom Bambu Cloud preset built on a Bambu base profile, OrcaSlicer's Sync Filaments resolved the slot to the generic base and the custom preset never appeared on the printer's LCD. When cloud returns filament_id: null, the frontend was falling back to the base_id mapping instead of keeping the correct PFUS* setting_id default. Fix removes the buggy base_id branch.
- (ams): HT slot shows "Generic" after configuring custom preset (#1053) — The /slot-presets endpoint, the PrintersPage render, and SpoolBuddy's AMS page all used different, incompatible key formulas for HT slots. All three now use a shared getGlobalTrayId helper.
- (ams): restore Configure/Assign actions on reset slots + relax Assign Spool filtering (#1047) — (1) After resetting an AMS slot from the printer UI, the Bambuddy printer card showed "Empty Slot" with no Configure or Assign Spool actions on hover. The redundant tray?.state === 10 gate from #784 is removed. (2) Assign Spool now surfaces matching inventory spools that have no slicer_filament_name populated via a partial material-match fallback. (3) The "profile mismatch" dialog now strips the @… printer/nozzle qualifier before comparing.
- (inventory): malformed rgba no longer bricks the Filaments page (#1055) — A single legacy spool row with a 7-character rgba value made the entire Filaments page go blank, because SpoolResponse's strict pattern refused to serialize the list. Fixed on three layers: SpoolUpdate.rgba now validates on PATCH, the hex input always emits a fully-formed 8-char RRGGBBAA on every keystroke, and SpoolResponse.rgba is unconstrained — the pattern belongs on request schemas, not responses.
- (dispatch): clean up transient library upload from Direct-Print flow (#730) — The "Print" button on a printer card (and drag-drop-onto-card) was silently uploading the chosen file into the File Manager before printing, leaving an unwanted LibraryFile row and disk file behind. POST /library/files/{id}/print now accepts a cleanup_library_after_dispatch flag; the Printers-page Direct-Print flow sets it and the LibraryFile is staged for deletion in the same transaction as the archive insert.
  External library files and every other print entry point are unaffected.
- (dispatch): forward authenticated user through library-print path (#730 follow-up) — The 0.2.3.1 fix plumbed the user into the background dispatch job but the dispatcher never read it back out, so Direct / File Manager / Library prints kept landing archives with created_by_id = NULL. The dispatcher now forwards the user to both archive_print() and set_current_print_user().
- (csp): allow http: iframes so Spoolman loads on HTTP LAN hosts (#1054) — Commit 53a70e37 (#995) tightened frame-src to 'self' https:, overlooking that self-hosted services on LANs almost always run over plain HTTP. Added http: to frame-src, matching the connect-src 'self' ws: wss: pattern already used for WebSockets. frame-ancestors 'none' still prevents Bambuddy itself from being framed.

  **Security**

  - (deps): floor-pin python-dotenv ≥ 1.2.2 to patch CVE-2026-28684 — python-dotenv 1.2.1 is transitively pulled in by pydantic-settings and is affected by CVE-2026-28684. Added an explicit python-dotenv>=1.2.2 floor in requirements.txt so the resolver can't land on 1.2.1 on fresh installs.

  **Contributors**

  Thank you to the contributors who helped make this release possible:

  - @Soopahfly — Embedded GCode viewer (#963)

