## 0.2.4.5

# Bambuddy 0.2.4.5

**⚠ Upgrade Notes — Read Before Updating**

0.2.4.5 is a substantial patch release on the same 0.2.4 code base — no schema breaks beyond the documented column additions for the new API-key scopes (auto-migrated on first start, dialect-branched for SQLite and Postgres), no Docker entrypoint changes, no Vite/proxy quirks. The in-app Apply Update button in Settings → System → Updates works for Docker and for any native install already on 0.2.4.1 or later.

**Four behavior-change callouts to know about before you upgrade:**

- **API-key permission model switched from denylist to allowlist** (security fix). Two new scope flags were added — `can_manage_library` and `can_manage_inventory` — and existing keys that had `can_queue` set are auto-backfilled with both new scopes on first start so library upload and inventory write keep working for keys you'd previously created as "queue-only". A hardened "read-only" key (no `can_queue`) does **not** silently gain new writes on upgrade. Review the Settings → API Keys page after upgrade if you run integrations against specific keys.

- **External folder mounting is now disabled by default and requires explicit operator opt-in via `BAMBUDDY_EXTERNAL_ROOTS`** (security fix). If you currently use the File Manager → external folder feature (mounting host paths like a NAS share, USB drive, or `/mnt/library`), you **must** set `BAMBUDDY_EXTERNAL_ROOTS=/path/one:/path/two` in your env / `docker-compose.yml` / systemd unit before upgrading, or all mounted external folders will be rejected on next start. The variable takes a colon-separated allowlist of absolute paths; the mount route is also now gated on the admin `SETTINGS_UPDATE` scope rather than `LIBRARY_UPLOAD` because mounting host paths crosses user boundaries. Bambuddy-owned dirs (data dir, log dir, static dir, archive dir) are hardcode-rejected even if added to the allowlist. See [wiki → Docker → External library folders](https://wiki.bambuddy.cool/getting-started/docker/#external-library-folders-bambuddy_external_roots) for examples.

- **Slicer-API sidecar users: bump `BAMBU_VERSION` in `slicer-api/.env` to `02.07.01.57` and rebuild.** If you run the optional OrcaSlicer API sidecar for server-side slicing, the upstream `bambu-studio-api` image switched from the no-longer-published Fedora AppImage to the Ubuntu 22.04 AppImage. The new default in `slicer-api/.env.example` / `slicer-api/docker-compose.yml` matches the new build path. After pulling this release:

  ```
  cd slicer-api
  docker compose --profile bambu build --no-cache bambu-studio-api
  docker compose --profile bambu up -d
  ```

  Bambuddy users who don't run the slicer-API sidecar are unaffected.

- **Virtual-printer FTP passive port range widened from 50000–50100 (101 ports) to 50000–51000 (1001 ports)** for the non-proxy path. Docker bridge-mode users mapping the old range need to update to `50000-51000:50000-51000`. Docker host-mode and bare-metal users are unaffected. Proxy-mode VPs keep the old range (they pre-bind the printer-side range exactly).

Make a backup before upgrading via Settings → Backup → Create Backup. Native install with `update.sh` snapshots the database automatically and rolls back on failure. Docker and fully-manual paths don't.

### Docker

```
docker compose pull
docker compose up -d
```

`docker-compose.yml` doesn't need refreshing unless you map the VP passive FTP port range (see above) — no other entrypoint, volume, or env-var conventions changed since
 0.2.4.

### Native install — recommended path

```
sudo BRANCH=main /opt/bambuddy/install/update.sh
```

Snapshots the database first and rolls back on failure.

### Native install — manual path

```
sudo systemctl stop bambuddy
cd /opt/bambuddy
sudo -u bambuddy git fetch --prune --tags --force origin
sudo -u bambuddy git checkout main
sudo -u bambuddy git reset --hard origin/main
sudo /opt/bambuddy/venv/bin/pip install -r requirements.txt
sudo systemctl start bambuddy
```

### Windows install

0.2.4.5 ships Windows installer (#1529). Existing installs upgrade in place via the Service / Update entries on the installer; fresh installs use the new GUI installer end-to-end.

---

## Highlights

0.2.4.5 is a security-led release. The big-ticket security work — API-key permission allowlist, path-traversal hardening across the upload / import / file-write surface with a fifth CI backstop, a WebSocket auth gate and audit-driven sweep, a vitest dev-dep bump, and a PyJWT floor bump for four upstream advisories — sits alongside a Windows-first installer (#1529), Turkish (#1571) and Korean (#1587) locales, OS-aware system theme detection (#1418), and the second wave of virtual-printer hardening (cipher-pin parity on every slicer-facing TLS context #1610, multi-slicer response routing, MQTT brute-force rate-limit, sticky-keys for seven more fields).

On the fix side, the biggest reports closed in this cycle: multi-plate archives now report filament / time / cost honestly (#1593), card timestamps render in the browser's local timezone instead of UTC (#1602), the multi-run accuracy badge is suppressed when it would be apples-to-oranges (#1608), the cross-distro TLS handshake regression on hardened-policy hosts is fixed at every VP TLS context (#1610), inventory and AMS handling tightened across transparent filament (#1545), profile-only mismatch popups (#1552), per-spool weight sync (#1530 / #1459), the SpoolBuddy tare banner (#1536), and the OIDC `email` claim auto-provisioning gap (#1569). VP `_pending_files` / temp-file leaks, queue-position assignment, DELETE orphan cleanup, sync-from-db race, and slicer-options cache bounds all landed as one slicer-surface audit bundle (#1558) plus follow-ups.

---

## Security

- **API-key permission model rewritten as an allowlist (critical).** The three documented API-key scopes ("Read Status", "Manage Queue", "Control Printer") were enforced only inside the legacy `/api/v1/webhook/*` router; every other route fell through to a 17-entry admin denylist that granted any valid key access to every non-admin endpoint regardless of which scope flags were ticked. Fix: a new explicit mapping pins every non-admin permission to exactly one scope; unmapped permissions return 403 ("administrative operations") regardless of scope. Two new scope flags ship in the same release — `can_manage_library` (gates library upload / update / delete and MakerWorld import) and `can_manage_inventory` (gates inventory create / update / delete and SpoolBuddy kiosk writes). Existing keys with `can_queue` set are auto-backfilled with both new scopes; "read-only" keys don't gain new writes. A new CI test fails the build on any future permission added without a scope classification, so the surface can't silently grow again. See **Upgrade Notes** above for the migration story.

- **WebSocket auth gate.** The proactive WebSocket audit caught that `/api/v1/ws` was broadcasting every printer-status / archive / inventory event to anyone who could reach the HTTP port. The endpoint is now auth-gated like the REST surface; events broadcast only to authenticated subscribers.

- **Path-traversal hardening across the upload / import / file-write surface.** A private report against `POST /api/v1/projects/import/file` traced two attacker-controlled strings being joined to the library directory with no resolve + containment check (`linked_folders[*].name` from the request `project.json` and per-entry `zf.namelist()` paths from the ZIP itself). Concrete escalation: drop a `.pth` into the venv's `site-packages` for code execution on next restart, overwrite the JWT signing-secret file to forge an admin token, or overwrite `~/.ssh/authorized_keys` on native installs. Fix is structural: a new `safe_join_under(parent, *parts)` helper resolves both sides and asserts containment; both vectors now route through it. Adjacent fixes in the same audit: `GET /api/v1/archives/{id}/photos/{filename}` had no traversal guard and was serving arbitrary paths; `ArchiveService.attach_timelapse` accepted printer-FTP-listing-supplied filenames with `..` segments under the compromised-printer threat model. The audit sweep marked every Path-arithmetic site under `backend/app/api/routes/` AND `backend/app/services/` with an explicit `# SEC-PATH-OK` annotation or routed it through the helper; a new CI test (the fifth security backstop) AST-walks both directories and fails the build on any future unsafe-shape join that's neither helper-routed nor marker-annotated.

- **External folder mounting restructured to an opt-in allowlist + admin-only scope.** External folder mounting (host paths like a NAS share or USB drive surfaced into Bambuddy's File Manager) was previously gated on `LIBRARY_UPLOAD` (any non-admin user with that scope) and validated against a small denylist of system directories — meaning anything not on the denylist could be mounted, including the Bambuddy data directory containing other users' archives, the log directory, or arbitrary NFS / SMB mounts. The route now requires the admin `SETTINGS_UPDATE` scope and accepts only paths inside the new `BAMBUDDY_EXTERNAL_ROOTS` env-var allowlist. The default empty allowlist disables the feature outright. Bambuddy-owned directories are hardcode-rejected even if the operator adds them to the allowlist. **This is a breaking change for installs that currently use external folder mounting** — see Upgrade Notes above for the restoration path.

- **VP MQTT brute-force rate-limit.** Bambuddy's virtual printer exposes an 8-character access code on the slicer-facing MQTT port; without rate-limiting it was brute-forceable by anyone who could reach the VP's bind IP. A new per-IP sliding-window limiter (5 failures / 60 s) now blocks further CONNECTs from a failing IP for the rest of the window; successful auth clears the IP's failure history.

- **VP access codes now compared in constant time.** Both the FTP `PASS` handler and the MQTT CONNECT handler used Python's `==` operator on the 8-character access code. Closes the timing side-channel without changing the protocol surface.

- **VP FTP uploads capped at 4 GiB.** `cmd_STOR` now rejects uploads exceeding 4 GiB, deletes the partial file, and replies 426. Without the cap a runaway or malicious client could drive RSS or disk to exhaustion; 4 GiB is well above any realistic multi-plate `.gcode.3mf`.

- **vitest bumped 3.2.4 → 4.1.8** (development dependency) to pick up an upstream CVSS 9.8 advisory. No production-runtime impact, but the floor moves so fresh installs and CI pick up the fix.

- **PyJWT bumped to >=2.13.0** to pick up four upstream advisories. Audit confirmed Bambuddy's usage is unaffected by every behavioural change in 2.13.0 (HMAC empty-key reject can't trigger, OIDC decode uses raw-key path not PyJWK, `jwks_uri` is HTTPS from discovery, no `b64=false` usage, `enforce_minimum_key_length` not opted into); 229 auth/MFA/OIDC integration tests + 78 auth unit tests pass on 2.13.0; `pip-audit --strict` is clean.

- **Trivy DS-0026 silenced on `Dockerfile.test` via `HEALTHCHECK NONE`.** The test image runs `pytest` and exits — no service to probe. Adding a healthcheck would have b
een cargo-cult noise.

---

## New Features

- **Windows installer (#1529, contributed by @vmhomelab).** Installer for Windows hosts — fresh install, service install / uninstall, in-place update, and a Troubleshooting entry. Existing native Windows users can upgrade via the Update entry on the installer.

- **Turkish (`tr`) locale (#1571, contributed by @samedyuksel).** Full Turkish translation across all keys, joining the existing 9-locale set.

- **Korean (`ko`) locale (#1587, contributed by @hijae).** Full Korean translation across all keys.

- **System theme detection — sidebar toggle and Settings selector follow the OS dark/light preference (#1418, contributed by @TempleClause via PR #1501).** `ThemeMode` gains a third value `system` alongside `dark` and `light`. The provider listens to `window.matchMedia('(prefers-color-scheme: dark)')` and tracks the OS preference in real time. The sidebar toggle now cycles `dark → light → system → dark` with the icon hinting at the next stop; Settings → Appearance gained a 3-button Dark / Light / System selector. Existing users' persisted preference is untouched — anyone on `dark` or `light` stays there and simply gains an extra stop in the cycle.

- **MQTT auth rate-limit on the virtual printer.** Per-IP sliding-window limiter (5 failures / 60 s) on VP MQTT CONNECT, brute-force-resistant. See Security section above for the full description.

- **Per-slicer MQTT response routing for multi-slicer VP setups.** Pre-fix: when slicer A sent a bridge-forwarded command to a non-proxy VP bound to a target printer, the printer's response was fanned out to every connected slicer. Now responses are routed to the originating slicer only, falling back to broadcast for printer-initiated unsolicited pushes (push_status etc.) and for sequence_ids the routing map never saw. Bounded at 256 entries with FIFO eviction.

- **VP child-service readiness barrier.** Each VP child sub-service (FTP, MQTT, Bind, SSDP) now exposes a `ready` event that fires after the socket actually binds; `start_server` awaits all of them with a bounded 5 s timeout. Closes a race where `is_running` reported true while the child sockets were still binding, which a quick poll from the diagnostic route or the VP card could observe.

---

## Changes

- **Bug-report template tightened + new Area dropdown.** 170 issues have been closed `invalid` (61 of them in the last 30 days alone — roughly 1 in 5 of all closed issues), nearly always because the reporter hadn't run the in-app diagnostics or checked the documented troubleshooting page. The Connection Diagnostic checkbox, Support Package attachment, and a new "Troubleshooting steps already taken" textarea are now required. The old `Bambuddy / SpoolBuddy / Both` dropdown is replaced with two required dropdowns — `Product` and `Area` (15 options covering the actual feature surface) — and an auto-label workflow applies the matching `area:*` label on every issue open/edit.

- **VP virtual-printer FTP server streams uploads straight to disk instead of buffering.** Pre-fix: `cmd_STOR` accumulated every chunk in a list and called `write_bytes` at the end. Peak RSS for a multi-GB `.gcode.3mf` was ~2× the file size and could OOM-kill a low-memory host. The streaming rewrite writes each 64 KiB chunk inline as it arrives, bounding peak memory at one chunk regardless of total upload size. Same change adds the 4 GiB hard cap described above.

- **VP virtual-printer FTP passive port range widened from 50000–50100 to 50000–51000.** Docker bridge-mode users mapping the old range need to update — see Upgrade Notes above.

- **VP MQTT bridge sticky-keys: 7 more fields preserved across incremental pushes.** Pre-fix: a single 1 Hz incremental push (which only carries changed temps / fan / wifi_signal) wiped any field not in the sticky-keys allowlist. The cached state lost `upgrade_state`, `xcam`, `hw_switch_state`, `nozzle_diameter`, `nozzle_type`, `online`, and `ams_status` after a single tick — BambuStudio's Send pre-flight reads several of these and could refuse Send because the cached push said "unknown firmware state". Same shape as #1228 (storage indicators) and #1558 (live-progress fields). Sticky-keys carry-forward is now also a `copy.deepcopy` (was reference) so a future merge can't corrupt both copies.

- **VP target-printer DHCP IP / serial refresh now restarts proxy VPs.** Pre-fix: when a target printer's IP changed (DHCP renewal, network reconfiguration), the running proxy VP kept forwarding to the stale IP forever; the user had to manually toggle the VP to refresh. `sync_from_db` now re-evaluates the proxy target each cycle and restarts the VP when the IP or serial actually changes.

- **VP `queue_force_color_match` setting takes effect immediately.** Pre-fix: toggling the per-VP "Force exact color match" setting via the UI silently no-op'd because `sync_from_db`'s "changed" predicate didn't include the field. Now restarts the running instance on toggle.

- **VP MQTT client session errors elevated from DEBUG to WARNING.** Production never sees the message at DEBUG; legitimate slicer-side errors (TLS handshake failure, protocol violation) deserve to be visible in the default log level.

- **VP MQTT periodic status push: one-line per-minute counter per active slicer connection (#1548 follow-up).** Replaces the noisy per-tick log line with a single per-minute summary, while still surfacing connection-drop events at WARNING.

---

## Fixed

**UI / rendering**

- Print-run log, spool usage history, camera-token list, and SpoolBuddy device "last calibrated" timestamps now render in the browser's local timezone instead of UTC (#1602, reported by @maziggy, confirmed by @IndividualGhost1905 with a UTC+3 reproduction). Same shape as the #504 timezone-offset bug — four sites the #504 sweep didn't catch because they were added afterwards or were missed.

- Archive card's Print Time + accuracy badge are now consistent for multi-run / multi-plate archives (#1608). The card was showing one run's actual duration next to a whole-file estimate, producing badges like "+188%". Multi-run archives now show "Estimated 5h 6m" with no badge; single-run archives keep the badge.

- Cancelled prints have their own stats bucket and no longer drag down the Success Rate gauge (#1390 follow-up).

- Cancelled bucket icon now uses the semantic warning token (orange) instead of an unrelated palette colour (#1390 follow-up).

- Quick Stats: user-cancelled prints now have their own bucket and no longer drag down the Success Rate gauge (#1390 follow-up, reported by @IndividualGhost1905).

**Slicer / library**

- Sliced `.gcode.3mf` files now render in the 3D preview and expose a Preview-3D action in the file row (#1543, reported by @Vlado-Tarakan).

- External-folder `.gcode.3mf` files now show thumbnails, and every ingest path stores the same canonical `file_type` for sliced outputs (#1600, reported by @maziggy).

- Deleted local profiles no longer linger in the SliceModal preset dropdown; new manual "Refresh" button surfaces cloud-side deletions without waiting for the 5-minute cache (#1581, reported by @lloydcat).

- STL thumbnail noise on first generation: matplotlib cache + font_manager scan no longer log three WARNING lines on first STL upload (reported by @maziggy).

- Bulk-upload ZIPs of stub / empty STL files no longer spam the log with thousands of warnings (reported by @maziggy).

- Print filenames with FAT32-illegal characters now rejected at rename / upload / queue time instead of failing at FTP (#1540, reported by @anthonyma94).

**Archive / stats**

- Multi-plate `.gcode.3mf` archives and reprints no longer under-report filament, time, and cost — project stats and parser both fixed (#1593, reported by @needo37). 3-plate file printed plate-by-plate over 9 runs was showing 1/9th of the real material consumption.

- Source-3MF upload on "fallback" archives no longer crashes with HTTP 500 (and stops orphaning files outside the data volume) (#1531, reported by @d3nn3s08).

- Fallback archives now carry MQTT-derived filament type + colour when the 3MF can't be downloaded (#1533, reported by @JmanB52D), plus a follow-up fix for real prints (#1533 follow-up).

**Inventory / Spoolman**

- Transparent / clear filament now selectable and rendered as transparent end-to-end in the built-in inventory (#1545, reported by @Synec5, confirmed by @CMW-ISS).

- Assigning a spool no longer shows a profile-mismatch warning when only the slicer profile differs; the warning now states the AMS slot will be reconfigured (#1552, reported by @anthonyma94).

- External-spool usage is now tracked when the AMS has empty slots in between loaded ones (#1607, reported by @ahmtcnby).

- SpoolBuddy weight sync no longer silently lands on a stale local row when Spoolman is enabled (#1530, reported by @chesterakl).

- SpoolBuddy Tare status banner no longer sits at "Waiting for device..." forever (#1536, reported by @flom89).

**Virtual printer**

- Queue / Review / Archive virtual-printer modes now complete the TLS handshake on hardened-distro hosts (#1610). Real Bambu printers offer only the plain-RSA AES-GCM suites `AES256-GCM-SHA384` / `AES128-GCM-SHA256`; a system crypto policy that strips them left the slicer's ClientHello with no overlap. The #620 cipher-suite fix only patched the printer-facing context; this release patches every slicer-facing VP TLS context (bind / MQTT / proxy-server / FTP).

- VP "Send file" IP rewrite now also fires for VPs without a dedicated bind IP (#1429 follow-up, residual case confirmed by @Mape6).

- VP "Send file" no longer redirects from Bambuddy to the physical printer's SD card once the printer powers on, and the mode button labels now match the wire values stored in the DB (#1429).

- VP queue mode no longer blocks BambuStudio Send while the target printer is mid-print (#1558, reported by @phieb).

- VP `_pending_files` / temp-file leak fixed on every error path across the three file handlers.

- VP queue position now picks `MAX(position)+1` instead of hardcoded `1`; duplicate position=1 entries no longer pile up on non-empty queues.

- VP DELETE route now cleans orphan `PendingUpload` rows and the on-disk `upload_dir`; previously these accumulated.

- VP `MQTTBridge._refresh_loop` no longer leaks the raw_message_handler on exceptions in the IP-encoding branch.

- VP `sync_from_db` serialised by `asyncio.Lock`; concurrent PUT calls (browser racing the auto-save trigger) no longer race the inner start/stop.

- VP `_slicer_print_options` cache bounded at 128 entries with FIFO eviction.

- VP MQTT bridge sticky-key carry-forward now uses `copy.deepcopy`; a sticky key carried over from the previous cache no longer shares nested dicts with the next push.

- VP MQTT no longer drops idle slicer connections at exactly 60 s (#1548, reported by @hollajandro); honours client-negotiated keepalive instead of the hardcoded 60 s.

- VP diagnostic now probes both bind ports 3000 (plain) and 3002 (TLS).

- VP FTP `stop()` now awaits cancelled sessions instead of `sleep(0.1)`; a session mid-write or mid-TLS-handshake can no longer outlive the stop call.

- VP per-VP TLS certificate auto-regenerates when the shared CA is rotated.

- VP `tailscale.py::get_status` now catches `asyncio.TimeoutError`; a stuck Tailscale subprocess no longer surfaces an uncaught exception.

- VP `certificate.py` CA save uses correct parent directory; previously the CA write could fail because only the per-VP subdirectory had been created.

- VP `_extract_plate_id` failures now log at debug instead of swallowing silently; a malformed `Metadata/slice_info.config` is now traceable.

**Dispatch / prints**

- A1 no longer auto-replays the previous print after a power cycle when the library row's filename has a doubled `.gcode.3mf` (#1542). The dispatch SD-cleanup path now aligns with the upload path; doubled-extension library rows no longer leave ghost prints.

- Connected-edge reconciliation closes the missed-PRINT-COMPLETE loop that produced ghost replays on smart-plug power cycles (#1542 follow-up, reported by @vixussrl-ui).

- Paused prints no longer inflate maintenance hours (#1521, reported by @TempleClause). `track_printer_runtime` was counting both RUNNING and PAUSE states.

- Webhook printer-status / stop / cancel routes 500'd on every connected printer because the route treated the `PrinterState` dataclass as a dict (#1584).

**Cloud / auth**

- Bambu Cloud sign-in failures caused by an upstream Cloudflare challenge now surface an actionable message instead of "Invalid response from Bambu Cloud" (#1575, reported by @cliveflint).

- OIDC auto-provisioning now reads the standard `email` claim for `User.email` when `Email Claim` is set to a non-email identity claim (#1569, reported by @anderl1969).

**Notifications**

- ntfy notifications: honest User-Agent + actionable error when the server is behind a Cloudflare challenge (#1534, reported by @apizz). User-Agent is now `Bambuddy/<version>` instead of the bare httpx default.

**Maintenance**

- Custom maintenance type "documentation URL" now persists on create (#1596, reported by @BurntOutHylian — with the exact root cause pre-triaged in the issue body).

**Internal / CI**

- Path-traversal CI backstop now recognises markers on the closing-paren line (project-wide convention).

- Backend test sharded 4-way + `-n auto` for ~3.5× wall-clock speedup in CI; pip cache mount in the test image.

- Unit tests no longer re-run inside the test image (duplicated the parent CI job).

- Trivy DS-0026 silenced on `Dockerfile.test` via `HEALTHCHECK NONE` (see Security).

---

## Credits

External contributors this release: @TempleClause (#1418 / PR #1501 system theme detection), @vmhomelab (PR #1529 Windows installer), @samedyuksel (PR #1571 Turkish locale), and @hijae (PR #1587 Korean locale). 
Thank you!

