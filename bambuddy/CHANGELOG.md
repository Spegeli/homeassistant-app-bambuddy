## 0.2.4.8

**Bambuddy 0.2.4.8**

**⚠ Upgrade Notes — Read Before Updating**

0.2.4.8 is a fix-led patch release on the same 0.2.4 code base — no schema breaks beyond auto-migrated column additions (dialect-branched for SQLite and Postgres), no Docker entrypoint changes. The in-app Apply Update button in Settings → System → Updates works for Docker and for any native install already on 0.2.4.x.

Three behaviour-change callouts to know about before you upgrade:

- SSO autologin landed as a per-OIDC-provider opt-in (#1589, requested by @einstux). No existing install changes behaviour on upgrade — local login stays enabled by default and no provider is marked as autologin. To enable: turn on the new `is_autologin` flag on exactly one enabled OIDC provider in Settings → Auth, optionally disable local login at the same screen, and unauthenticated visitors will be redirected to your IdP on mount. A `BAMBUDDY_LOCAL_LOGIN=true` env-var bypasses both gates if your SSO provider is unreachable, and `/login?fallback=local` is a bookmarkable always-shows-the-form URL. Two refusal modes protect against lockout: disabling local login is rejected unless at least one OIDC provider is enabled AND the calling admin has a UserOIDCLink row.

- Sponsor-prompt thresholds lowered to fire for typical installs. The lowest print milestone drops from 100 → 10, archives from 50 → 5, and cost from 100 → 25 (EUR). Installs that already saw a sponsor toast within the last 14 days won't see more — the cross-family cooldown is unchanged. Installs that have never crossed the old 100-print bar become eligible the first time they pass 10 prints. The toast itself is the existing one, copy unchanged.

- Printer card UI refresh (#1661). Visual change on the main Printers page — re-arranged for structure and readability. The Filaments section header now carries the new AMS Filament Backup badge (blue circle-arrow when on, dim when off, "?" on A1 family where the cfg bit isn't yet parsed). External tray slots show `L` / `R` inside the colour circle instead of a separate `Ext-L` / `Ext-R` caption underneath, equalising the bottom row's height. No data-model change; existing customisation persists.

Make a backup before upgrading via Settings → Backup → Create Backup. Native install with update.sh snapshots the database automatically and rolls back on failure. Docker and fully-manual paths don't.

**Docker**

```
docker compose pull
docker compose up -d
```

docker-compose.yml doesn't need refreshing for 0.2.4.8.

**Native install — recommended path**

```
sudo BRANCH=main /opt/bambuddy/install/update.sh
```

Snapshots the database first and rolls back on failure.

**Native install — manual path**

```
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

Download `bambuddy-0.2.4.8-windows-x64-setup.exe` from this release page (or the unversioned `bambuddy-windows-x64-setup.exe` alias for an always-latest link). The In-app "Install Update" button on Windows installs now uses the same release-asset flow — no more "Could not find git executable" failures.

---
**Highlights**

0.2.4.8 is dominated by three threads: **AMS Filament Backup** becoming a first-class surface, **SSO autologin** for operators running their own OIDC, and a heavy contributor-credited fix sweep across notifications, the Virtual Printer, SpoolBuddy, and the queue.

The AMS Filament Backup thread closes the gap reporters @jpcast2001 and @Arn0uDz hit on dual-AMS X1C farms — when one slot ran low, the deficit check ignored a same-material backup peer and blocked the print. Bambuddy now reads and writes the per-printer backup state from the printer card (new badge in the Filaments section header), mirrors it into the colour-strict deficit check (#1762), and threads it into the dispatcher's "Prefer lowest" sort (#1766) so the spool that ought to run dry first really does. The mid-print spool-switch attribution bug @biduleman hit (#1771) — the firmware's end-of-print `total_layer_num=0` push was clobbering the cached total, collapsing every previous segment to 0g — is fixed in the same train.

SSO autologin (#1589) lands as a per-OIDC-provider opt-in with safety refusals on the disable-local-login toggle to prevent lockout, plus an env-var recovery path and a bookmarkable `/login?fallback=local`. See Upgrade Notes for the full surface.

Notifications got a sweep: false-positive "Print Stopped" on reprint after MQTT reconnect (#1807), finish-photo dropped on FINISH-state fallback (#1790), completion notification scoping the whole multi-plate project instead of the printed plate (#1785), and "Printer offline" push never firing on the disconnect edge (#1752) all fixed by separate contributors and reporters.

The Virtual Printer surface got another #1780 round driven by reporter @mkoreen — three commits bumping the slicer-MQTT race window to 5s with retroactive stamp, correcting a VP intake key mismatch that was silently dropping every slicer field, and forwarding the H2C rack-swap nozzle pick from slicer to dispatch.

Smaller-but-load-bearing: **per-printer Maintenance Mode** (#1476) so a printer can be excluded from the dispatcher without unplugging it, **per-filament humidity threshold for auto-drying** (#1605), **drag-reorder for grouped queue items**, and **heater history** (nozzle / bed / chamber) tracked with a per-tile chart-icon overlay opening the history modal.

---
**New Features**

- AMS Filament Backup status badge + toggle on the printer card; "Prefer lowest" actually picks the lowest spool (#1766, reported by @biduleman). Three states — ON (blue circle-arrow), OFF (dim), Unknown ("?" on A1 family where the cfg bit isn't parsed yet). Click toggles via the new `POST /printers/{id}/ams-backup` endpoint (gated on `printers:control`).

- Backup-aware filament deficit check, colour-strict (#1762, reported by @jpcast2001 + @Arn0uDz). Pre-print check sums grams across same-material backup peers instead of treating each slot in isolation.

- SSO autologin + disable local username/password login (#1589, requested by @einstux). Per-OIDC-provider `is_autologin` flag and `BAMBUDDY_LOCAL_LOGIN` env-var recovery path. See Upgrade Notes.

- Per-printer Maintenance Mode toggle (#1476, requested by @IndividualGhost1905 / Ferdi SEVER). Excludes a printer from queue dispatch without disconnecting it — useful for swap-out / cleaning / firmware-flash windows.

- Per-filament humidity threshold for auto-drying + alarms (#1605, requested by @thenewguy). Replaces the single global threshold with per-filament overrides; falls back to global when unset.

- Heater history (nozzle / bed / chamber) tracked + per-tile chart-icon overlay opens history modal. Mirrors the existing AMS sensor history surface; same retention + sampling cadence.

- Updated printer card UI for structure and readability (#1661). See Upgrade Notes for the visual change summary.

- Drag-reorder for grouped queue items; collapsed batches no longer block adjacent rows.

- Forecasting groups spools by colour + Forecast UI rework (#1814, by @Keybored02).

- "Auto-add unknown RFID spools" toggle + global confirmation modal (#1764). Reporters with multi-operator workshops saw duplicate inventory rows accumulating; toggle defaults to today's auto-add behaviour for compatibility, the modal asks before adding when unset.

- In-app sponsor-toast at earned milestones (Prints / Cost / Archives / Anniversary / Version-update). Cooldown 14 days across all families.

- Prominent sponsor banner on Settings → General. Single dismissable banner above the existing settings list on the default landing tab.

- Lower sponsor-prompt thresholds. See Upgrade Notes.

---
**Changes**

- Printer card AMS row: external tray height matches regular AMS slots. L/R label now lives inside the slot's colour circle in place of the index; bottom `Ext-L` / `Ext-R` caption removed.

---
**Fixed**

**Notifications**

- False-positive "Print Stopped" notification on reprint after MQTT reconnect (#1807, reported by @volodymyr-doba).

- Print-complete notification no longer drops the finish photo when the FINISH-state fallback fires (#1790, reported by @needo37). Producer→consumer sync.

- Completion notification scoped to printed plate on multi-plate 3MFs (#1785). Multi-plate single-plate prints used to report the whole project's duration + material; now matches the queue card.

- Push notification for "Printer offline" actually fires (#1752, reported by @saint-hh). `on_printer_offline` dispatch wired on the disconnect edge — the callback existed but the wire was missing.

**Auth / OIDC / permissions**

- API keys with Manage Library permission can rename / delete / move library files (#1832, reporter @MorganMLGman). `LIBRARY_UPDATE_ALL` / `LIBRARY_DELETE_ALL` now map to `can_manage_library`; `LIBRARY_PURGE` stays admin-only.

- Sidebar entries for Files / Archives / Queue no longer hidden from non-admin users with granular `*_read` access (#1755, reported by @knifesk).

- Auth preserves the original URL across login + OIDC round-trip (#1750). Bookmarks land where the user clicked, not the dashboard.

- Printer secrets restricted to update-authority callers. Tightens which API surfaces can return access codes and credentials.

**Virtual printer / dispatch**

- H2C nozzle pick from Bambu Studio preserved on dual-nozzle rack variant + VP slicer-field intake (#1780, reported by @mkoreen). Three commits landed: slicer-MQTT race window bumped to 5s with retroactive stamp, VP intake key mismatch corrected, rack-swap nozzle pick forwarded to dispatch.

- Mid-print AMS Backup spool-switch correctly splits weight instead of crediting all to the second spool (#1771, reported by @biduleman). Cascades `state.total_layers` → `last_layer_num` → equal-split fence; firmware's end-of-print `total_layer_num=0` push no longer clobbers the cached total.

**Print queue + scheduler**

- `require_previous_success` no longer permanently blocks a printer's queue after a failure (#1818, reported by @jmassardo). Resume-after-failure clears the gate.

**Inventory / AMS / SpoolBuddy**

- Assign-spool picker note now visible on mobile (#793 follow-up, reporter @EmcetPL). Note rendered as a muted line under the weight on both internal and Spoolman branches; `title=` tooltip preserved for desktop hover.

- SpoolBuddy "Assign to AMS" preserves the user's slicer preset instead of pushing Generic (#1815, reported by @Bgabor997). Resolver now preserves PFUS / PFCN `setting_id`.

- SpoolBuddy inventory search matches spool ID, slicer filament name, and storage location (#1738, reported by @shaddowlink). Was filtering on spool name only.

- H2S active-tray highlight no longer stuck on AMS slot 1 during external-spool prints (#1822, reported by @ojimpo). `tray_now` promoted to 254 on all-external prints.

- Unknown-tag modal no longer pops for slots with no RFID.

**Connection / install**

- Connection diagnostic no longer reports false camera-port warning on A1 / A1 Mini / P1 (#1799 closing #1798, by @lesbass / Stefano Maffeis).

- Docker installer escalates on EACCES instead of failing on `/opt/bambuddy` (#1774, reported by @jmoore-skild). Auto-sudo on the directory create when needed.

- In-app "Install Update" on Windows installer switched to release-asset update flow — no more "Could not find git executable" failures.

**UI / rendering**

- Chamber-fan badge hidden on open-frame Bambu printers that have no chamber fan.

- Archive thumbnails rendered server-side when the sidecar slice skips them (#1759, reported by @VID-PRO).

- Local Presets page: deleted row optimistically removed instead of staying visible until refetch returned (which had allowed a second delete click → 404).

- AMS history modal respects theme background variant in stats modal.

- Post-#1661 printer-card cleanup — test fixtures + hover-card fly-in removal.

**Docs / archives**

- Archives "Step 4" docs link no longer 404s (#1812, reported by @Spanholz). Corrected `bambuddy.cool/wiki/...` host to `wiki.bambuddy.cool/...`.

- Archives backfill NULL `created_at` + tolerate NULL in response (#1732). Old archive rows from upgrades that ran before the column existed now render correctly.

---
**Security**

- dompurify 3.4.10 → 3.4.11 (GHSA-cmwh-pvxp-8882, moderate). Frontend HTML sanitisation library; no Bambuddy code change.

- Backend dependency security floor bumps — cryptography, python-multipart, starlette. Floor raises so fresh installs and CI pick up the fixed runtime.

- Floor pins for pydantic-settings ≥2.14.2 + msgpack ≥1.2.1 to clear `pip-audit`.

- Vite 7 → 8 + plugin-react 5.2 (major bump) + frontend dependency bumps.

- 422 constant rename — pinpoints the dependency-related security response constant.

---
**Contributors**

External code contributors with merged PRs in this release: @EdwardChamberlain (#1661 — Update printer card UI for structure and readability), @Keybored02 (#1814 — Forecasting: group spools by colour + UI rework), @lesbass / Stefano Maffeis (#1799 closing #1798 — A1 / A1 Mini / P1 camera-port diagnostic). Thank you!

The reporters who drove the fixes in this release are credited inline next to each Fixed entry above.

---
**Sponsors**

Bambuddy is sustainable thanks to people who put their money where their use is. If this release saved you time or kept your farm running, the project runs on recurring contributions — there's no paid tier, no telemetry, no upsell, just sustainable maintenance.

- **GitHub Sponsors** (recurring, 5 tiers from $5/mo to $300/mo) — https://github.com/sponsors/maziggy
- **Ko-fi** (one-time or recurring) — https://ko-fi.com/maziggy

Everyone supporting Bambuddy is named at https://bambuddy.cool/backers.html (and in `BACKERS.md` in the repo). Special thanks to @northpole3dprinting (Corporate tier) and all the Patron / Supporter / Backer sponsors who made this release possible.

