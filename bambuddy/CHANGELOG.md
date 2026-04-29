## 0.2.4b1

**Bambuddy v0.2.4b1**

First beta of the 0.2.4 cycle. The headline is two long-running gaps closed at once: server-side slicing means you can now slice STL/3MF files inside Bambuddy without a desktop slicer installed, and a full MakerWorld integration means you can browse, search, and one-click "Import & Print" any MakerWorld model directly from the app. Together they remove the last reasons many LAN-only users kept the Bambu Handy app installed.

**Upgrade Notes — Read Before Updating**

⚠ **Native install users on 0.2.3.x: the in-app *Apply Update* button cannot install 0.2.4b1.** The 0.2.3.x updater is hardcoded to `git fetch origin main && git reset --hard origin/main`, but 0.2.4b1 lives on its own branch — main is still at 0.2.3.2 — so clicking *Apply Update* appears to succeed while actually leaving you on 0.2.3.2. Use one of the explicit branch-aware paths below instead. **0.2.4b1 itself fixes this**: once you're on 0.2.4b1, the in-app updater resolves the target tag from the GitHub releases API (respecting `include_beta_updates`), fetches it with `--tags`, and resets to the tag — so future betas will be installable directly from the GUI.

Make a backup before upgrading via Settings → Backup → Create Backup. Native install with `update.sh` snapshots the database automatically and rolls back on failure.

**Docker**

Make sure your `docker-compose.yml` `image:` line points at `:0.2.4b1` (or `:beta` for the rolling beta tag).

```
docker compose pull
docker compose up -d
```

**Native install — recommended path (branch override on `update.sh`)**

```
sudo BRANCH=0.2.4b1 /opt/bambuddy/install/update.sh
```

The `BRANCH=` env var tells `update.sh` to pull `origin/0.2.4b1` instead of `origin/main`. The script handles backup, service stop/start, pip install, and frontend build with the correct working directory.

**Native install — manual path (if `update.sh` isn't available)**

```
sudo systemctl stop bambuddy
cd /opt/bambuddy
sudo -u bambuddy git fetch origin
sudo -u bambuddy git checkout 0.2.4b1
sudo /opt/bambuddy/venv/bin/pip install -r requirements.txt
sudo systemctl start bambuddy
```

The new Slicer API sidecar is **opt-in** — if you don't run the `slicer-api/` Compose stack, the existing "open in desktop slicer" flow is unchanged. See the wiki for setup.

---

**Highlights**

- **Server-side slicing via OrcaSlicer / Bambu Studio sidecar** — Bring up the optional `slicer-api/` Compose stack and the new *Slice* button in File Manager, Archives, and MakerWorld dispatches a background slice job whose result lands as a new `.gcode.3mf` with embedded thumbnail. Multi-plate 3MFs open a plate picker first; multi-color plates render one filament dropdown per AMS slot, each pre-picked against your imported / cloud / standard presets by type and colour match. Live progress in a persistent toast that follows you across pages. Falls back to embedded settings when the CLI's `--load-settings` path misbehaves (notably OrcaSlicer + H2D). Works alongside — does not replace — the existing desktop-slicer integration.
- **MakerWorld Integration** — Paste any MakerWorld model URL or search the catalog and one-click *Import to Library* or *Print Now*. Per-plate picker with *Save* or *Save & Slice*, *Import all plates* for multi-plate models, image lightbox, Recent imports sidebar, and per-plate delete. Reuses your existing Bambu Cloud login — no separate account, no companion browser extension, no cookie paste. HTML descriptions are sanitised via DOMPurify and CDN images are proxied through Bambuddy so your IP stays private.
- **Tailscale integration for virtual printers** (builds on [#1070](https://github.com/maziggy/bambuddy/issues/1070) by @legend813) — Opt-in per virtual printer: bring each VP into your tailnet for private remote access over WireGuard without port forwarding. Docker image now ships the Tailscale CLI pre-installed. Per-VP FQDN, copy-button, status indicator, opt-out toggle.
- **Slicer presets unified across Cloud, imported, and bundled tiers** — The new Slice modal's preset dropdowns merge presets from Bambu Cloud (cloud-synced), local imports (`.orca_filament`, `.bbscfg`, `.bbsflmt`, `.zip`, `.json`), and the slicer's own bundled `BBL/` profiles into one ranked list, pre-selected by type and colour match. Cloud-only and local-only setups both work.
- **Enhanced filament colour handling: multi-colour gradients, transparency, visual effects** ([#1154](https://github.com/maziggy/bambuddy/issues/1154)) — The Spool form's *Colour* section now accepts a paste of up to 8 comma-separated hex stops (e.g. `EC984C,#6CD4BC,A66EB9,D87694` from 3dfilamentprofiles.com) and renders them as a CSS gradient on every swatch site. New *Effect* dropdown (Sparkle / Wood / Marble / Glow / Matte / Silk / Galaxy / Rainbow / Metal / Translucent / Gradient / Dual Color / Tri Color / Multicolor). Transparency is now actually visible — alpha < `0xFF` shows through a checkerboard layer beneath the colour layer. Multicolor subtype renders as a colour-wheel pie. Same fields are editable on the Color Catalog admin.

**New Features**

- **Library Trash Bin + Admin Bulk Purge + Auto-Purge** ([#1008](https://github.com/maziggy/bambuddy/issues/1008)) — Deleted library files now move to a trash bin with a configurable retention window (default 30 days) before a background sweeper permanently removes them. Admins also get a *Purge old* bulk action with a live preview (count + total size freed + sample filenames) and an opt-in *Auto-purge* schedule that runs once per 24 h. Gated by a new `library:purge` permission.
- **Long-lived camera-stream tokens for HA / Frigate / kiosks** ([#1108](https://github.com/maziggy/bambuddy/issues/1108)) — Generate a stable, long-lived token in Settings → Cameras and wire it into Home Assistant, Frigate, or any wall-mounted kiosk without dealing with rotating session cookies.
- **Per-spool category + low-stock threshold override** ([#729](https://github.com/maziggy/bambuddy/issues/729)) — Tag any spool with a custom category (e.g. *prototyping* / *production*) and override the global low-stock threshold per spool.
- **Per-event ntfy priority** ([#990](https://github.com/maziggy/bambuddy/issues/990)) — Configure ntfy priority headers per event type so print-failure pings come through with a louder alert than print-finished.
- **Project URL + cover photo** ([#1155](https://github.com/maziggy/bambuddy/issues/1155)) — Paste a MakerWorld / Printables / Thingiverse link and upload a hero image so each project card is visually identifiable; the URL renders as a one-click external-link button beside the project name.
- **"Not Printed" / "Printed" collections on the Archives page** ([#1153](https://github.com/maziggy/bambuddy/issues/1153)) — Quick filter chips at the top of the Archives view to triage uploaded-but-never-printed files vs the printed catalog.
- **Virtual-printer archive name source toggle** ([#1152](https://github.com/maziggy/bambuddy/issues/1152)) — Choose whether VP-received prints use the embedded 3MF metadata title or the original filename for archive naming.
- **Per-request trace IDs in logs + `X-Trace-Id` response header** — Every HTTP request gets a unique trace ID written across the access log, all application log lines for that request, and an `X-Trace-Id` response header. Makes diagnosing rogue server-state changes and cross-component bugs significantly easier.
- **OIDC Azure Entra ID support — configurable email claim & verification + Remember Me** ([#1126](https://github.com/maziggy/bambuddy/issues/1126), contributed by @netscout2001) — Configurable `email_claim` for SSO providers that don't use the standard claim, optional `require_email_verified` enforcement, and a Remember Me toggle for persistent login.
- **MakerWorld URL-paste resolver shows printer per plate instance** — Plate picker now shows which printer each plate was sliced for so you don't accidentally pick an X1C plate on a P1S.

**Improved**

- **AMS slot "Assign to inventory spool" picker now lists every spool, including RFID-tagged Bambu Lab ones** ([#1133](https://github.com/maziggy/bambuddy/issues/1133)) — Previously the picker hid RFID-matched spools as "already assigned"; it now lists every spool with a clear assignment-state indicator.
- **Inventory: "Delete Tag" button renamed to "Clear RFID Tag"** ([#729](https://github.com/maziggy/bambuddy/issues/729) follow-up) — Less ambiguous than "Delete".
- **Nozzle icon on the dual-nozzle status card** ([#1115](https://github.com/maziggy/bambuddy/issues/1115)) — Visual indicator when a printer has two nozzles configured.
- **Settings page is now permission-gated, not admin-only** — Granular permissions can grant individual settings sections without granting full admin.
- **Background-dispatch toast no longer reads as "frozen at 100 %" for fast uploads** — Progress bar handles sub-second uploads without leaving a misleading "stuck" state.
- **SpoolBuddy kiosk: "Plate ready" pills under the printer status badges** — At-a-glance signal that a plate needs clearing.
- **SpoolBuddy kiosk no longer surfaces main-app toasts** — Operator notifications stay in the main app where they belong.

**Fixed**

- **In-app upgrade clobbered SSH `origin` on developer checkouts** — The updater unconditionally rewrote `origin` to HTTPS before fetching, on the assumption that systemd service users wouldn't have SSH keys. That assumption clobbered any developer's SSH origin the moment they tested the upgrade flow against their own checkout, and the next `git push` would prompt for HTTPS credentials. The updater now reads the current origin first and only rewrites if it doesn't already point at `maziggy/bambuddy` (parsing both SSH and HTTPS forms with or without `.git`). Native installs with no remote set, or origins pointing at a fork, still get reset to the canonical HTTPS URL.
- **Native-install in-app upgrade silently skipped `pip install`** — On a native install, the in-app *Apply Update* button got the new code in via `git reset --hard origin/main` but then logged `Could not open requirements file: 'requirements.txt'` and continued without installing the new deps. Pip was running with `cwd=settings.base_dir`, which on a native install resolves to the data dir (e.g. `/opt/bambuddy/data`), not the source-code dir; pip doesn't walk up like git does. New `settings.app_dir` points at the source tree, and the pip + npm steps now run from there. Docker is unaffected (it doesn't use the in-app updater).
- **Postgres restore from a SQLite Local Backup aborted with `cannot drop table printers`** — Settings → Backup → Restore on a Bambuddy running against external Postgres failed when the live database held orphan tables from removed features (e.g. legacy `spoolman_slot_assignments` / `spoolman_k_profile` whose `*_printer_id_fkey` constraints still pointed at `printers`). The restore path now uses `DROP TABLE … CASCADE` on every public-schema table before recreating from the ORM metadata, so orphan tables and their constraints get cleaned up alongside the ORM schema instead of blocking the restore. SQLite restores are unaffected.
- **H2D Pro multi-plate dispatch double-/triple-fire** ([#1157](https://github.com/maziggy/bambuddy/issues/1157)) — A post-dispatch hold prevents the scheduler from re-dispatching the same plate when H2D Pro firmware takes longer than expected to acknowledge.
- **OIDC `auto_link_existing_accounts` now works with custom email claims (Azure Entra ID)** ([#1142](https://github.com/maziggy/bambuddy/issues/1142), contributed by @netscout2001) — Auto-linking of existing Bambuddy accounts now respects the configured `email_claim` instead of defaulting to `email`.
- **P1P print dispatch failed with `0500_4003 "can't parse print file"` when the printer was slow to acknowledge** ([#1150](https://github.com/maziggy/bambuddy/issues/1150), reported by @d3ni3) — Watchdog no longer reconnects MQTT mid-dispatch when the project file is already on the printer.
- **3MF profile-driven slicing silently produced wrong-printer output** — Every 3MF slice was falling back to the source's embedded printer regardless of the picked profile, because the CLI's `--load-settings` parser silently rejected the supplied JSON when the `type` field was missing. Now correct.
- **Auto-Print G-code Injection: start snippet landed before printer startup, and `{placeholder}` substitution was silently broken** ([#422](https://github.com/maziggy/bambuddy/issues/422) follow-up) — Start snippet now runs after the printer is ready; placeholders substitute correctly.
- **Reprint-from-archive failed with `0500_4003` SD R/W errors after a stuck dispatch, fixable only by restarting the container** ([#1136](https://github.com/maziggy/bambuddy/issues/1136)) — MQTT state cleanup correctly clears the stuck-dispatch marker.
- **Background-dispatch reported "Print started successfully" when the printer never actually transitioned** ([#1134](https://github.com/maziggy/bambuddy/issues/1134), follow-up to [#1042](https://github.com/maziggy/bambuddy/issues/1042)) — Watchdog now propagates a timeout as a failed dispatch instead of falsely reporting success.
- **User-cancelled prints surfaced as "1 problem" on the printer card AND were archived as "Layer shift" failures** — Cancellation is now correctly distinguished from a real failure.
- **Camera stream second viewer fails / kicks the first off** ([#1089](https://github.com/maziggy/bambuddy/issues/1089)) — Multiple simultaneous camera viewers are now fanned out from a single upstream connection.
- **Bambu RFID auto-match created duplicate inventory rows for Quick-Add and non-Bambu-branded spools** ([#918](https://github.com/maziggy/bambuddy/issues/918)) — Auto-match now correctly handles Quick-Add spools and rejects non-Bambu brands.
- **Project picker UX in archives** ([#1151](https://github.com/maziggy/bambuddy/issues/1151)) — Scroll, sort, and search now work in the project-picker dropdown.
- **Uploads to writable external folders silently landed in internal storage** ([#1112](https://github.com/maziggy/bambuddy/issues/1112)) — Cross-boundary file move actually relocates bytes to the mounted folder.
- **Queue: batch (quantity > 1) double-dispatched onto the same printer** — A whole-batch lock prevents double-dispatch when the queue picks an ASAP batch.
- **Queue item stuck at "printing" when print failed before reaching RUNNING** ([#1111](https://github.com/maziggy/bambuddy/issues/1111)) — Pre-RUNNING failures now correctly advance the queue item.
- **Queue: active-item progress bar flashed 100 % before dropping to 0 %** — Progress bar resets cleanly between batch items.
- **H2C dual-nozzle detection missed post-2026 serial batches** ([#1105](https://github.com/maziggy/bambuddy/issues/1105)) — Newer H2C units are now correctly detected as dual-nozzle.
- **Spoolman iframe silently blank on HTTPS Bambuddy with HTTP Spoolman** ([#1096](https://github.com/maziggy/bambuddy/issues/1096)) — CSP allows mixed-content iframes for self-hosted LAN Spoolman instances.
- **Reprint-from-Archive left `created_by_id` as `NULL`** ([#730](https://github.com/maziggy/bambuddy/issues/730) follow-up) — Reprints are now correctly attributed.
- **Plate-clear button stayed visible after the API cleared `awaiting_plate_clear` outside the printer-card click path** ([#1128](https://github.com/maziggy/bambuddy/issues/1128)) — WebSocket broadcasts the flag flip end-to-end.
- **"Open in Slicer" fails on Windows / Linux for any filename containing spaces or special characters** ([#1059](https://github.com/maziggy/bambuddy/issues/1059)) — Filenames are now correctly URL-encoded in the slicer protocol handler.
- **Camera page ignored `?fps=N` URL parameter** ([#1131](https://github.com/maziggy/bambuddy/issues/1131) diagnostic) — FPS override now honoured on `/camera/<id>`.
- **Spool auto-assign hit `IntegrityError` on Postgres when AMS pushes arrived in quick succession** — Auto-assign now serialises per printer.
- **Tailscale cert-renewal restart silently failed mid-way** (follow-up to [#1070](https://github.com/maziggy/bambuddy/issues/1070)) — Renewal restart sequence is now atomic.
- **Settings table filled with duplicate rows on legacy SQLite installs** — Idempotent migration de-duplicates on startup.
- **Install script failed for first-time users** — First-run path now correctly initialises the venv and database.
- **`bambuddy.log` filling with `WinError 10054` / `Exception terminating connection ... CancelledError` cascades** ([#1112](https://github.com/maziggy/bambuddy/issues/1112) follow-up, surfaced by @Carter3DP's support package) — Cancel-safe `get_db` plus silenced Windows asyncio Proactor cleanup-RST noise.
- **Settings: failed-save toast looped forever when the user lacked `settings:update`** — Permission-denied responses now break the retry loop.
- **Groups: edits to custom-group permissions appeared lost on reopen** ([#1083](https://github.com/maziggy/bambuddy/issues/1083)) — Custom-group permissions persist across modal reopens.
- **Setup: re-enabling auth could 422 on a password the form no longer needs** — Re-enable flow no longer requires the field it just hid.

**Security**

- **postcss bumped to 8.5.12 to clear GHSA-qx2v-qp2m-jg93** — Transitive dev-dependency advisory; no runtime impact for users on a published image.

**Contributors**

Thank you to the contributors who helped make this release possible:

- @netscout2001 — OIDC Azure Entra ID support, configurable email claim & verification, Remember Me ([#1126](https://github.com/maziggy/bambuddy/issues/1126), [#1142](https://github.com/maziggy/bambuddy/issues/1142))
- @legend813 — Tailscale opt-out toggle for virtual printers ([#1070](https://github.com/maziggy/bambuddy/issues/1070))


