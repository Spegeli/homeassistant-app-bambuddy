## 0.2.4b3

**Bambuddy v0.2.4b3**

  The post-b2 cycle — the headline is two big contributor PRs landing back-to-back. MFA at-rest encryption is now default-on with auto-bootstrap (no env var to set, encryption key generated on first boot, included in backups, with a Settings → Security status panel showing exactly what's protected) — closing #1219. 
The unified Spoolman inventory UI (#1114 + follow-up fixes) replaces the old separate-tab Spoolman flow with a single inventory page that handles AMS slot assignments, NFC tag write, storage location, and Spoolman filament catalog picker — the same UX as local-DB inventory, switching backends becomes invisible to operators. Plus a new Slicer Bundle (.bbscfg) import workflow that lets BambuStudio's "Printer Preset Bundle" export drive every subsequent slice — closes the long tail of preset-resolution corner cases (cloud presets behind login, "from User" sentinels, dangling inherits, etc.) by sidestepping the JSON triplet entirely.

On top of those, ~12 fixes — most notably a tricky slicer "Send to printer" pre-flight failure on P1S/A1 targets (#1228, reported by @rtadams89), a Docker data-volume ownership rewrite via gosu entrypoint (#1211), and a filament-usage double-count that hit anyone whose AMS auto-falls-back to a same-material spool mid-print (#957).

  ---
**Upgrade Notes — Read Before Updating**

  If you're already on 0.2.4b2, the in-app Apply Update button in Settings → System → Updates can install b3 directly. The 0.2.3.x updater can't (it's hardcoded to origin/main), so 0.2.3.x
  → b3 still needs the explicit branch path documented in the b1 release notes.

  Make a backup before upgrading via Settings → Backup → Create Backup. Native install with update.sh snapshots the database automatically and rolls back on failure.

Docker

  Make sure your docker-compose.yml image: line points at :0.2.4b3 (or :beta for the rolling beta tag).

  docker compose pull
  docker compose up -d

  Important — bind-mount ownership: #1211's gosu entrypoint replaces the previous chmod-777 hack. The shipped docker-compose.yml now comments out the
  ./virtual_printer:/app/data/virtual_printer bind mount by default. If you previously had it uncommented, your existing setup keeps working — the entrypoint chowns the host-side dir
  through the bind mount on first start. Add PUID / PGID env vars if you run the container as a uid other than 1000.

Native install — recommended path

  sudo BRANCH=0.2.4b3 /opt/bambuddy/install/update.sh

  The BRANCH= env var tells update.sh to pull origin/0.2.4b3 instead of origin/main. The script handles backup, service stop/start, pip install, and frontend build with the correct working
  directory.

Native install — manual path

  sudo systemctl stop bambuddy
  cd /opt/bambuddy
  sudo -u bambuddy git fetch origin
  sudo -u bambuddy git checkout 0.2.4b3
  sudo /opt/bambuddy/venv/bin/pip install -r requirements.txt
  sudo systemctl start bambuddy

  This release adds two new tables (spoolman_slot_assignments, spoolman_k_profile) and several ALTER TABLE columns; migrations are idempotent and run automatically on startup. The
  .mfa_encryption_key file is auto-generated on first boot under DATA_DIR (mode 0o600) and is included in backup ZIPs — keep your backups safe.

  ---
**Highlights**

- MFA at-rest encryption is now default-on via auto-bootstrap (#1219, via #1231 by @netscout2001) — Default Docker installs ran with MFA_ENCRYPTION_KEY unset, which silently fell back to plaintext storage for OIDC client_secret and TOTP secret rows. The single startup logger.warning was the only signal, and .env.example / docker-compose.yml / Settings UI never mentioned the variable, so any operator who wired up SSO or asked users to enroll in 2FA had to read the warning in the logs to know their secrets were unprotected at rest. The encryption-key resolver now mirrors the JWT-secret pattern: MFA_ENCRYPTION_KEY env → DATA_DIR/.mfa_encryption_key file → auto-generated Fernet key on first boot (mode 0o600). A re-encryption migration
  runs at startup and lifts existing plaintext rows to the encrypted form (idempotent — re-runs are no-ops). New GET /auth/encryption-status endpoint plus a Security sub-tab under Settings
  → Authentication renders four severity tiers (green / yellow legacy-rows / orange auto-generated key with backup hint / red key-missing-but-rows-exist). Backups now bundle the key file at the ZIP root with safe path-traversal validation on restore, so a backup is self-contained and restorable to a fresh host without losing decryption access.

- Unified Spoolman inventory UI (#1114 by @netscout2001, follow-up fixes by @maziggy) — Spoolman inventory is no longer a separate tab with its own UX. The standard Inventory page now routes to either local DB or Spoolman based on the spoolman_enabled setting, and every operator workflow — quick-add, AMS slot assignment, NFC tag write, storage location, filament catalog picker — works the same way under either backend. Adds spoolman_slot_assignments and spoolman_k_profile tables for local AMS-slot-to-Spoolman-spool mapping and per-printer K-value calibration profiles linked to Spoolman spools. Includes a colour-name fallback for installs where Spoolman doesn't populate color_name (most don't — falls back to the filament's
  subtype, typically "Basic Red" / "Matte White" / "Silk Black"), tag-uniqueness enforcement on NFC write (clears the binding from any previous holder before binding to the new spool), and a 3-second kiosk refetch interval so SpoolBuddy displays pick up assignment changes from other clients within seconds.

- Slicer Bundle (.bbscfg) import — Upload a BambuStudio "Printer Preset Bundle" (.bbscfg) once per printer, then pick from it for every subsequent slice. The slicer materialises the JSON triplet from the stored bundle by name, so cloud presets behind login, "from User" sentinel handling, the # -prefix clone trick, dangling inherits on renamed parents — none of those
  preset-resolution corner cases reach Bambuddy any more. New /api/v1/slicer/bundles routes (POST / GET / GET :id / DELETE :id, gated on Permission.LIBRARY_UPLOAD), new SliceModal Slicer bundle picker at the top of the modal that's only rendered when at least one bundle is imported, bundle-aware preview-slice so gram numbers in the modal match what the actual print will produce. Falls back to the embedded-settings slice path on bundle CLI 5xx, with used_embedded_settings=True surfaced in the response. Server-side support requires the bambuddy/bundle-import branch of the orca-slicer-api fork — see the slicer-api sidecar docker-compose for the matching versions.

**New Features**

  - AMS slot assignments under Spoolman mode — When operating against a Spoolman backend, the dashboard's Assign to AMS flow now writes a local SpoolmanSlotAssignment row instead of polluting Spoolman's spool.location field. The mapping survives restarts, can be unassigned from the AMS page (new Unassign button), and renders an "Assigned spool: brand · material -
  color" info card on the slot picker so kiosk operators can see the linked spool at a glance.

  - NFC tag write under Spoolman mode — Writing a tag for spool B now searches Spoolman for any other spool currently bound to the target UID and clears its extra.tag before binding to the new owner, so a single physical NFC UID never maps to two spools at once. Best-effort cleanup — failures log a warning but don't block the write itself, since the chip is already written.

  - SpoolBuddy LinkSpoolModal Spoolman support — Picker now shows real colour names for Spoolman spools where the original implementation rendered "Unknown color". Falls back to the filament's subtype field when color_name is empty (most Spoolman installs don't populate it).

**Improved**

- Printers page header polish (#1203 by @EdwardChamberlain, partial of #1060) — Tightens the printers-page header layout for visual consistency across screen widths. Spacing, alignment, and element grouping rationalised — pure UI polish, no behaviour change. i18n updated across all 8 locales.

- Slice button no longer enabled before the preview slice resolves — Until the preview slice (or embedded-metadata read for already-sliced 3MFs) returned the per-plate filament list, the SliceModal rendered a synthetic single-slot fallback so the auto-pick had something to bind against. That made the Slice button enabled the moment the modal opened, even before the slicer
   had told us which AMS slots the plate actually consumes — clicking would dispatch against opaque defaults and the real-life print would either pick the wrong filament or fail with a slot-mismatch error. Adds filamentReqsQuery.isSuccess to the isReady chain so the button stays disabled while the preview slice is in flight and flips to enabled the moment the real slot list lands and auto-pick fills it.

**Fixed**

- Slicer "Send to printer" silently rejected the cached push_status with "storage needs to be inserted" on P1S / A1-class targets (#1228, reported by @rtadams89, also hit by @smandon) — Slicer "Send" worked on 0.2.3.2 with a queue-mode VP and started failing on 0.2.4b3 dailies, regardless of subnet topology. The smoking gun was in @rtadams89's debug archive: slicer
  establishes MQTT, gets pushall + get_version responses, then never opens FTP — the slicer reads the cached push, fails its pre-flight, aborts before any data transfer. Cause: the cached-as-base slicer-mirror (commit 7dea33d0) passes the live target's push_status through with only an IP rewrite; if the real firmware doesn't report SD/storage indicators (P1S firmware 01.10.00.00 confirmed in @rtadams89's logs), the slicer sees "no storage" and refuses to send. Fix overlays home_flag bit 0x100, sdcard=True, and a 32 GB synthetic storage block onto the cached push (only fills in if real values are missing — real values pass through unchanged). H2D and X1C work fine without the overlay because their firmware reports the indicators; P1S / A1 don't always.

- Camera preview popup opened to a blank page; deep-route refresh broken (#1221, reported by @enjoylifenow / @Haeckan / @elit3ge / @jc21) — Clicking "open camera in new window" rendered as an empty white page across P1S / P2S / X1, every browser, every install method. Root cause: PR #1195's base: '' change (to support path-prefixed reverse proxies) made index.html
  reference its bundle via relative URLs. In the popup at /camera/<id>, the browser resolved ./assets/index-XXX.js to /camera/assets/index-XXX.js — the SPA catch-all returned index.html (text/html), and modern browsers refuse to execute HTML as a JS module under nosniff. Same break hit any deep-route initial load. Reverted to base: '/' (Vite default, absolute asset URLs). Path-prefixed reverse proxy support was already explicitly closed as wontfix in #1195 — the supported workaround for that audience (NPM + Cloudflare Tunnel + HA Webpage panel via TRUSTED_FRAME_ORIGINS) doesn't depend on base: '' at all.

- Filament usage double-counted when AMS auto-falls-back to a same-material spool (#957) — When one spool ran out mid-print and the AMS transparently switched to a sibling slot loaded with the same material, the usage tracker credited the originally-mapped spool with the full 3MF estimate AND added the fallback spool's remain%-delta on top. A 78 g print could show as 78 g + 60 g consumed across the two spools, leaving the empty spool's recorded weight beyond its label weight. Two interacting bugs: the tray-change recorder gated on the literal gcode_state ∈ {"RUNNING", "PAUSE"} which P2S firmware briefly transitions out of during the swap; the splitter then gated on not slot_to_tray so the tray-change log was ignored when the slicer's mapping had been captured. Now the recorder keys on print-lifecycle flags (any tray change between print start and completion is captured), and the splitter treats tray_change_log evidence with > 1 entries as the source of truth when the printer actually fed from multiple trays.

- 3D Preview returned {"detail":"Not Found"} in Docker installs (#1218) — The embedded GCode viewer's static assets (gcode_viewer/) were not copied into the production Docker image, so /gcode-viewer/?archive=<id> returned a bare FastAPI 404 inside the iframe while the outer Bambuddy layout looked normal. The Vite production build doesn't stage gcode_viewer/ either (its
  dev server uses a configureServer middleware that's dev-only), and the only integration test for the route accepted 404 as valid. Dockerfile now copies gcode_viewer/ alongside the React build output; main.py logs ERROR at startup when the viewer's index.html is missing so future packaging gaps surface in docker logs; integration test now asserts 200 OK + non-empty HTML body when the assets exist on disk.

- New AMS RFID rolls auto-named to the wrong colour when the hex is shared across material variants (#1227) — Inserting an Ivory White (PLA Matte) roll always created a spool named "Jade White" because the colour-catalog lookup filtered by manufacturer + hex only, with no ORDER BY. Three Bambu Lab catalog rows share #FFFFFF — Jade White (PLA Basic), Ivory White (PLA Matte), White (PLA Silk) — and SQLite returned them in rowid order. Now the lookup filters by tray_sub_brands (printer-reported material variant matches the catalog's material column directly), with an explicit ORDER BY id for deterministic third-party / OpenTag fallback. Note: spools already in the database under the wrong colour name don't auto-correct — the matcher only fires when creating a new spool from RFID. Manual rename in Inventory after upgrading.

- Backups to Gitea / Forgejo failed with "Failed to create tree" on empty repos and "list indices must be integers or slices, not str" on populated repos (#1224, #1225) — Two interacting bugs in the inherited-from-GitHub Gitea backend: list-shaped ref response (Gitea returns [{...}] where GitHub returns {...}), and empty-repo writes refused (Gitea won't accept blob/tree/commit POST until the repo has at least one commit). GiteaBackend now overrides the relevant methods directly — list/dict-tolerant _ref_sha() helper for the Git Data API path, plus the empty-repo bootstrap goes through Gitea's Contents API which seeds the initial commit + branch in a single transaction. ForgejoBackend inherits both fixes. Follow-up: Gitea 1.24+ wraps GET /git/commits/{sha} in the Commit schema (tree at commit.tree.sha) where GitHub returns the unwrapped GitCommit (tree at top level) — _commit_tree_sha() helper now tries the
  flat shape first and falls back to the wrapped shape, so subsequent backups don't re-upload every blob.

- Docker data-volume ownership normalised at startup via gosu entrypoint (#1211) — Two long-standing failure modes: (1) Docker named volumes are created as root:root, and the previous chmod 777 /app/data workaround only covered the named-volume root, so subdirs Bambuddy creates at runtime inherited wrong ownership; (2) the shipped docker-compose.yml had
  ./virtual_printer:/app/data/virtual_printer uncommented and dockerd creates missing bind-mount sources as root before the container starts — leaving the host directory unwritable by uid 1000 inside. Symptom either way: [Errno 13] Permission denied: '/app/data/virtual_printer/uploads'. New deploy/docker-entrypoint.sh runs as root, chowns /app/data and /app/logs (and
  /app/data/virtual_printer when bind-mounted) to PUID:PGID, then drops to that uid via gosu before exec'ing the app. Sentinel .bambuddy file in each data path prevents Docker from re-syncing image-directory metadata on every mount. Compose template comments out the bind mount by default with explicit guidance for the few users who actually need it.

- Label picker modal clipped the 4th template option and Cancel button on short viewports (#1230, reported by @elit3ge) — On Windows 11 + Brave at 1080p with browser chrome / DPI scaling, only 3 of the 4 templates were visible (Avery 5160 was half-cut at the bottom) and no Cancel button reachable. Fixed in two passes: spool list min-h-[160px] → min-h-0 so it can yield space, then templates section reorganised as a 2×2 responsive grid (grid-cols-1 sm:grid-cols-2) above the sm breakpoint to trim ~150 px of vertical inside the modal.

- Configure AMS Slot modal: long filament profile names now expand on hover (#1237, reported by @basziee) — Profile names like SUNLU PETG GLOW IN THE DARK GEN2 @Bambu Lab H2C 0.4 nozzle were visually truncated mid-name, hiding the @<printer> <nozzle> suffix. The preset row now expands inline on hover (group-hover:whitespace-normal group-hover:break-all) so the nozzle
  suffix is readable instantly without waiting on the browser's title-tooltip delay. Native title=<full name> added as a belt-and-braces fallback for assistive tech and touch devices.

- Spool assignment to a reset AMS slot left the slot unconfigured both in Bambuddy and on the printer — Reproduced during feature/spoolman-inventory-ui testing (extends the #1228 family). After clicking "Reset slot" then picking an inventory spool, the success toast fired but no ams_filament_setting MQTT command ever fired. Cause: assign_spool decided the slot was empty using tray_type, but "Reset slot" clears tray_type while leaving filament physically loaded — the empty tray_type misled the heuristic into the pending-config (SpoolBuddy weigh-then-assign) branch, which intentionally skips the MQTT publish. Now uses tray.state (Bambu firmware reports state == 11 for loaded, 9 for empty, 10 for spool present but filament not in feeder) when the printer reports it, with the existing tray_type heuristic as fallback for older firmware.

- SpoolBuddy + Spoolman: NFC scan ignored Spoolman setting; "Assign to AMS" did nothing on freshly-linked spools; AMS slot picker hid the assigned spool's info; LinkSpoolModal showed "Unknown color"; tag write didn't enforce uniqueness; kiosk display held stale assignments forever — Seven intertwined bugs surfaced during feature/spoolman-inventory-ui testing; fixing them as one batch because they all live on the SpoolBuddy + Spoolman path. NFC tag-scan now routes via _get_spoolman_client_or_none(db) (Spoolman exclusive when enabled, local exclusive otherwise) instead of always trying local first. Dashboard Assign to AMS synthesises an InventorySpool-shaped object from the WebSocket-delivered MatchedSpool when the cached inventory query hasn't caught up yet. AMS-page slot picker resolves the assignment from spoolmanSlotAssignmentsAll + spoolmanInventorySpoolsCache and renders an "Assigned spool" info card with a new Unassign button. _map_spoolman_spool falls back to filament subtype when color_name is empty. NFC write clears the tag binding from any previous holder before binding to the new spool. Kiosk slot-assignments query gets refetchInterval: 3_000. QuickMenu System commands (Restart Daemon / Restart Browser / Reboot / Shutdown) now accept INVENTORY_UPDATE (matching the rest of the kiosk-scoped routes) instead of silently 403'ing on the kiosk operator's session.

**Security**

- python-multipart bumped to 0.0.27 to clear CVE-2026-42561 — requirements.txt floor raised from >=0.0.26 to >=0.0.27. python-multipart is the multipart/form-data parser FastAPI uses for UploadFile body parsing, so it sits on every Bambuddy upload path (3MF / STEP / STL upload, label-template imports, OIDC certificate upload, backup restore). Bambuddy doesn't expose unauthenticated upload endpoints — every multipart route is gated on Permission.LIBRARY_UPLOAD / SETTINGS_UPDATE / INVENTORY_UPDATE — so blast radius is bounded to authenticated callers, but the bump is mechanical and the floor was already loose.

  ---
**Contributors**

  Thank you to the contributors who helped make this release possible:

  - @netscout2001 — MFA at-rest encryption auto-bootstrap (#1219 via #1231) and unified Spoolman inventory UI (#1114)
  - @EdwardChamberlain — Printers page header polish (#1203)

