## 0.2.4.6

**Bambuddy 0.2.4.6**

**⚠ Upgrade Notes — Read Before Updating**

0.2.4.6 is a fix-led patch release on the same 0.2.4 code base — no schema breaks beyond auto-migrated column additions (dialect-branched for SQLite and Postgres), no Docker entrypoint changes. The in-app Apply Update button in Settings → System → Updates works for Docker and for any native install already on 0.2.4.1 or later.

Five behavior-change callouts to know about before you upgrade:

- /api/v1/inventory/spools/{id}/reset-usage renamed to /reset-consumed-counter (breaking for external API consumers). The old name implied the endpoint zeroed weight_used; in practice it only stamps the baseline so the consumed-counter widget reads 0 going forward while remaining weight is preserved. Same for the bulk variant and the Spoolman-mode mirror. No compat shim — the old name actively misled callers. If you scripted against the old path, the migration is a one-line URL swap. Frontend, Bambuddy UI, and SpoolBuddy kiosk all migrated in-tree.

- Slicer-API sidecar now ships as pre-built images on GHCR + Docker Hub (#1657). The old slicer-api/docker-compose.yml used build: { context: https://github.com/maziggy/orca-slicer-api.git#... } which required git inside the Docker BuildKit worker — Container Station, Synology DSM, and QNAP don't ship it there, so the build failed outright. New compose uses image: ghcr.io/maziggy/orca-slicer-api:${SIDECAR_TAG:-latest}. After pulling this release:

  cd slicer-api
  docker compose pull
  docker compose up -d

- No more --no-cache --pull build dance. SIDECAR_TAG env var defaults to latest; pin to bambuddy-X.Y.Z to lock to the sidecar image that shipped with a specific Bambuddy release. Both images are linux/amd64 only; ARM64 hosts (Pi 4/5, Apple Silicon Linux) should run the sidecar on a separate x86_64 box and point Bambuddy at it via the Sidecar URL field.

- VP MQTT bridge net.info[].ip rewrite: FQDN-configured printers now work without manual reconfiguration (#1429). If you added a printer to Bambuddy by hostname (p1s.fritz.box, a router-provided DNS name, a Tailscale MagicDNS name, etc.) on 0.2.4+, the bridge couldn't rewrite the slicer-facing IP and Send quietly went to the real printer instead of the Bambuddy archive whenever the printer was powered on. After upgrade the bridge resolves the configured hostname to IPv4 at arm time and the rewrite path engages automatically — no UI action required. The unresolvable-input case (typo, dead DNS) is now logged with a specific reason instead of silently no-opping. If you were on the IPv4 workaround you can switch back to hostnames after upgrade.

- VP access codes auto-derived from the target printer in non-proxy modes. A startup migration syncs any pre-existing diverged Queue / Archive / Review VPs to match their target printer's code on first boot, with one INFO log per VP for audit. If the codes had previously diverged and your slicer was failing to connect because of it, that bridge starts working automatically after this upgrade. No user action; you may need to re-add the device in your slicer if the code changed.

- Docker bridge-mode default port mapping narrowed from 50000-51000 (1001 ports) to 50000-50029 (3 VPs worth) by default (#1646). The wide range from 0.2.4.5 spawned ~2000 docker-proxy host processes consuming ~3.5 GB host RAM on the reporter's box. New compose file maps just the slices for the first 3 VPs by default; bridge-mode users with more than 3 VPs widen the mapping by editing the published comment (50000-500N9 where N = vp_count - 1). Host-mode Linux and proxy-mode VPs are unchanged. Per-VP slicing is non-overlapping by design; collisions beyond 100 VPs fall back to the per-session retry the pre-#1646 code already had.

Make a backup before upgrading via Settings → Backup → Create Backup. Native install with update.sh snapshots the database automatically and rolls back on failure. Docker and fully-manual paths don't.

**Docker**

  docker compose pull
  docker compose up -d

docker-compose.yml doesn't need refreshing unless you map the VP passive FTP port range (see Upgrade Notes above) or you run the slicer-API sidecar (see Upgrade Notes above).

**Native install — recommended path**

  sudo BRANCH=main /opt/bambuddy/install/update.sh

Snapshots the database first and rolls back on failure.

**Native install — manual path**

  sudo systemctl stop bambuddy
  cd /opt/bambuddy
  sudo -u bambuddy git fetch --prune --tags --force origin
  sudo -u bambuddy git checkout main
  sudo -u bambuddy git reset --hard origin/main
  sudo /opt/bambuddy/venv/bin/pip install -r requirements.txt
  sudo systemctl start bambuddy

requirements.txt picks up one new optional dependency this release — curl_cffi, used by the firmware-update check to clear Bambu Lab's Cloudflare JA3 challenge (#1666). If the wheel fails to install on your platform Bambuddy falls back to httpx automatically; only the in-app firmware download URL stops resolving and the wiki-based version-detection badge keeps working.

Native install — INSTALL_PATH under /home

If your install lives under /home/... rather than the default /opt/bambuddy/, the systemd unit's ProtectHome=true directive previously prevented ExecStart from resolving the venv binary (#1685). The new install.sh detects INSTALL_PATH == /home/* and emits ProtectHome=read-only automatically. Existing /opt/... installs keep the stricter ProtectHome=true.

**Windows install**

0.2.4.6 ships the same Windows installer as 0.2.4.5. Existing installs upgrade in place via the Service / Update entries on the installer.

---

**Highlights**

0.2.4.6 is a reporter-credited fix release on top of the 0.2.4 line. Two big-ticket adds: Orca Cloud profile sync end-to-end — read/list/slice with profiles from your Orca Cloud account alongside the existing Bambu Cloud integration, with four sign-in providers (Google, Apple, GitHub, email+password), a 4-tier preset picker (Orca Cloud → Bambu Cloud → local → standard), and full AMS + SpoolBuddy surface integration — and native CSV import / export for the inventory (#1576, PR #1659 by   @samedyuksel), backed by a 18-column round-trippable schema with formula-injection hardening and a per-row dry-run preview.

The VP surface got another sweep. The hostname/FQDN side of #1429's net.info[].ip rewrite is finally closed (root-caused by @Mape6 — every IPv4 codepath now resolves the configured hostname before parsing). #1548 round 2 fixes the underlying reason OrcaSlicer dropped idle MQTT connections to the VP — the slicer never sends PINGREQ at all, so spec-compliant keep_alive * 1.5 disconnects fired against a slicer that holds idle sessions indefinitely against real Bambu firmware; the fix drops the application-level read timeout in favour of TCP SO_KEEPALIVE for dead-connection detection. #1646's FTP passive-port pool is now per-VP-sliced, dropping bridge-mode host RAM by ~16× on the reporter's single-VP setup. #1658 closes the BambuStudio 2.7.x "Downloading" hang — the slicer flipped the Send sequence to FTP-before-MQTT in 2.7.x, so the set_gcode_state(FINISH) synthesis fired before the real _send_print_response overwrote it back to PREPARE; the fix re-fires FINISH 1.5 s after the synthetic ack.

K-profile + AMS-slot work: #1688 / #1689 (both reported and diagnosed by @Spionkiller01 with H2C testing) fix two related symptoms with one shared root cause — spool preset ids (GFSG98_09) and K-profile filament_ids (GFG98) look different but normalise to the same value, and previously the matchers used name parsing only. The follow-up to #1689 (Spionkiller01's diff, applied verbatim) closes the residual unconfigured-but-loaded slot case where the original cali_idx safety net was unreachable. #1694 surfaces "?" instead of "Empty" on loaded-but-unconfigured AMS slots (matches the slicer's own convention). #1680 fixes the Assign-Spool toast that claimed success on the deferred-configure-on-insert path.

Reliability and dispatch: #1679 fixes the false-cancel-and-duplicate-archive bug when Bambuddy restarts mid-print (the connected-edge reconciliation fired against state.state="unknown" before the printer's first real push_status landed). #1678 fixes the print-queue wedge when a printer accepts project_file but never starts (the watchdog returned success on subtask_id advance alone; new Phase B waits up to 180 s for the active-state transition before reverting). #1697 fixes multi-plate filament over-counting — a 190 g lid from a multi-plate 3MF was getting debited the whole file's 273 g. #1397 closes the long-standing "bed already dropped" finish-photo regression by extracting the last frame of a brief timelapse Bambuddy now force-records on every dispatched print (post-park, pre-bed-drop window) — verified on N=2 H2C prints, bed-slinger field verification welcome.

Cloud / auth: #1666 routes the Bambu Lab firmware-download fetch through curl_cffi to clear the Cloudflare JA3 challenge that started 403-ing plain Python TLS — the HTTP-layer User-Agent stays Bambuddy/1.0 honest per the 2026-05-12 compliance commitment, only the TLS handshake bytes match Chrome (pinned by a test that fails the build if the UA override is ever dropped). #1698 fixes the silently-zombie tabs after JWT expiry — setAuthToken(null) from the API client wasn't reaching AuthContext.user, so ProtectedRoute kept rendering with no token and every subsequent request 401'd silently. Fix (mirrored from @TCL987's working fork patch) dispatches an auth:expired event the AuthContext listens to.

---
**New Features**

- Orca Cloud profile sync — end-to-end (slicer + AMS + SpoolBuddy). Bambuddy now reads, lists, and slices with profiles from your Orca Cloud account alongside the existing Bambu Cloud integration. OrcaSlicer 2.4.0-alpha shipped its own Supabase-backed cloud (auth.orcaslicer.com / api.orcaslicer.com); this integrates using a standard PKCE handshake. Four sign-in providers: Google, Apple, GitHub (paste-flow PKCE, since Orca's Supabase project only allowlists localhost for redirect_to), and email+password (direct grant). UI: the Cloud Profiles tab is now two — "Bambu Cloud" (existing, unchanged) and "Orca Cloud" (new, same rich layout). Slicer integration surfaces Orca Cloud as the top tier in a 4-tier preset picker (Orca Cloud → Bambu Cloud → local → standard); AMS slot configuration accepts orca_cloud as a 4th preset   source; SpoolBuddy modal fetches Bambu + Orca filaments in parallel via Promise.allSettled. Persistent storage: 5 new columns on users (token / refresh / expiry / provider / email) plus 3 transient PKCE state columns with 10-min TTL, dialect-branched for SQLite and Postgres. Auth-disabled mode falls back to the global Settings table. Refresh tokens are single-use (Supabase behaviour) and rotated just-in-time with <5 min leeway; new pair persisted before the downstream call so a mid-flight crash doesn't strand the user. New explicit orca_cloud:auth permission flag folded into the existing can_access_cloud API-key scope. Filed OrcaSlicer/OrcaSlicer#14028 upstream to widen the redirect_to allowlist so future Bambuddy versions can ship clean OAuth instead of paste-flow. 32 backend unit + 6 preset-resolver + 6 sidecar-fetch + 6 frontend tests; ~35 new i18n keys translated across all 10 non-English locales.

- Native CSV import / export for the inventory (#1576, PR #1659 by @samedyuksel). Bulk-add spools without manually clicking through the form, and back up / migrate the local inventory in a single round-trip. Export downloads bambuddy-spools-YYYY-MM-DD.csv with one row per active spool; Import shows a per-row preview classifying each row as valid / error / skipped / duplicate-warn before anything hits the database, then a confirm click persists only the valid rows in one transaction. Fixed 18-column schema includes weight_used / last_used / storage_location / category / low_stock_threshold_pct for a lossless round-trip. Colour resolution: explicit rgba wins, otherwise brand + color_name resolves against the Color Catalog in a single in-memory pass. Hardening: 5 MB upload cap with bounded 64 KB chunked read (handles chunked uploads where file.size is None), spreadsheet formula-injection guard on export with the inverse strip on import for lossless round-trip, soft duplicate-warn flag when an active spool with the same material+brand+color exists. Local inventory only — in Spoolman mode the buttons render disabled with a tooltip pointing at Spoolman's own   CSV import/export. 25 backend integration tests + 3 frontend modal tests; full i18n in all 11 locales. Companion wiki PR maziggy/bambuddy-wiki#41.

- Archives page banner: reactive install-step-4 nudge for the slicer-side "Store sent files on external storage" setting. Companion to the new external_storage diagnostic check (below) — catches the slicer-side variant of the same setting that never reaches the printer on older BambuStudio / OrcaSlicer. New GET /archives/no-3mf-warning endpoint returns true iff any archive in the last 30 days has extra_data.no_3mf_available=True and isn't soft-deleted; banner is amber, dismissible, and one-shot via localStorage (persistent across browser restarts — "you've been told" should outlive a session). 5 backend integration tests; 4 i18n keys in all 11 locales.

- Connection diagnostic now verifies install step 4 ("Store sent files on external storage"). Many users miss this setting when adding their first printer; without it BambuStudio / OrcaSlicer never leave a .gcode.3mf on the printer's SD card, every archive falls back to no-thumbnail / no-metadata, and the cause is invisible. New external_storage check reads state.store_to_sdcard (the MQTT home_flag bit 11 Bambuddy already parses). Pass when the printer reports the bit on, fail when off, skip when no live state or the field has never been populated. Slot in the check list sits between port_ftps and mqtt_auth. The skip text explicitly calls out the older-slicer limitation so users on that path know to verify manually. Wiki updated on the System and Troubleshooting pages.

- Connection diagnostic now verifies the printer is publishing on its report topic (#1622). A printer with a wrong-cased serial — or one that isn't publishing for any reason — would previously pass mqtt_auth because the broker accepts the subscription regardless. User-visible symptom was "AMS / K-profiles / custom filaments missing on the slicer side". New printer_publishing check turns the existing log warning into a structured diagnostic result. Bounded 10 s polling at 0.5 s intervals; exits the moment a message arrives, with an elapsed-seconds counter on the modal so the spinner doesn't look hung. The support-package gathering path stays fast (instant pass/fail, no wait).

- "Open in Slicer" desktop target is now configurable separately from the API sidecar slicer (#1329, reported by @hasmar04). Reporter wanted to slice via the Bambu Studio sidecar but open files locally in OrcaSlicer; the existing preferred_slicer setting drove both, so picking one forced the other. New open_in_slicer setting ('bambu_studio' | 'orcaslicer' | null) drives only the desktop "Open in Slicer" URI handoff. Default is null — existing installs fall back to preferred_slicer and behave identically until a user changes it. Five call sites across ArchivesPage, MakerworldPage, ModelViewerModal migrated. MakerWorld's "Slice in {{slicer}}" button label additionally branches on useSlicerApi so the text always matches what the button does.

- Queue items + Print modal now show the build plate type, per-plate accurate (#1281, reported by @CMW-ISS). Multi-printer farms with 40+ plate runs need to know which physical plate each queued job needs. New extract_bed_type_from_3mf(file_path, plate_id) helper alongside the existing filament-usage extractor; PrintQueueItemResponse gains bed_type; the /archives/{id}/plates (and library equivalent) include per-plate bed_type for the modal's plate selector. Per-plate accuracy matters because the archive-level capture stores only the first plate's value — a 40-plate 3MF mixing PEI + Engineering returns "PEI" for every plate at the archive level, but plate 17 may actually need Engineering. 8 unit cases on the extractor.

- Print Log page: per-row delete (#1687 part 1, reported by @IndividualGhost1905). Every row in Archives → Print Log now has a trash icon next to the filament cell, gated on archives:delete_own / archives:delete_all. Filament / time / cost contribution drops out of Quick Stats in the same response cycle (stats aggregate over PrintLogEntry). The matching archive (if any) stays untouched — the log row is a sibling, not a child.

- Print Log page: per-row failure-cause classification (#1687 part 4, reported by @IndividualGhost1905). Reporter clarified after part 1 shipped that what he actually wanted for failure-cause grouping on the log (spaghetti, jam, bed-adhesion, etc.) was different from archive tags (which describe the model). The storage and aggregation were already there; the gaps were the GET serialiser silently dropping failure_reason from PrintLogEntrySchema, and orphan log entries (no archive —
  dispatch errors, aborts, manual entries) having no edit path. New PATCH /print-log/{entry_id}, vocabulary validated against the same 11-key canonical set the Archive Edit modal uses. Pencil icon beside the trash icon; modal saves invalidate both print-log and archives-stats query keys.

- Add Printer: scan a custom subnet for printers behind a router on a different L3 segment (#1564, reported by @MartinNYHC, root-caused by @IndividualGhost1905). SSDP multicast (239.255.255.250:2021) doesn't traverse routers, so the existing Discover pass couldn't find printers on a different subnet. New "Custom subnet..." sentinel in the AddPrinterModal picker reveals a CIDR text input. When custom is picked, discovery routes through POST /discovery/scan with the typed CIDR (which already does the unicast probe). Last custom CIDR persisted to localStorage. No backend changes — SubnetScanner.scan_subnet() already caps at /22 (1024 hosts) with batch-50 concurrency.

- VP MQTT bridge surfaces why net.info[].ip rewrite didn't arm (#1429 defensive). The bridge had 4 silent early-return paths in _refresh_ip_encoding. When the rewrite silently no-op'd, the only signal was the absence of the armed INFO line. Each path now emits one specific-reason INFO line, throttled by a dedup field so an idle unarmed bridge doesn't spam at 30 s tick. This is exactly the surface that pinpointed #1429's hostname/FQDN root cause on the reporter's bundle.

---
**Changes**

- Slicer-API sidecar ships as pre-built images on GHCR + Docker Hub (#1657, reported by @d3nn3s08). Removes the build-from-source git dependency that broke installs on QNAP, Synology DSM, and Container Station. See Upgrade Notes for the new docker compose pull workflow.

- VP access code is now auto-derived from the target printer in non-proxy modes (Discord report). With the live target-printer mirror that landed earlier in the 0.2.5 cycle forwarding slicer auth bytes through to the real printer, the slicer's stored code has to clear both checks (VP listener + real printer). If the codes diverged the bridge silently failed at the second hop. The fix removes the foot-gun: when a target printer is selected, the VP card's access-code field becomes read-only with an
  Eye-toggle reveal showing the target's code. One-shot startup migration syncs any pre-existing diverged VPs with one INFO log per VP. Wiki corrected (previously framed code-match as a camera-only concern — wrong, all bridged protocols inherit).

- File Manager sidebar: "All Files" now scopes to your own uploaded files; new "External" entry holds the combined linked-folder view (#1621, reported by @kcw96). Restores the pre-external semantics so long-time users get their muscle memory back. The combined "everything across every external mount" view moves to a sibling sidebar entry that only renders when at least one external folder is linked (zero-cost on installs without the feature). New internal_only / external_only query flags
  on /api/v1/library/files. Empty-state copy distinguishes "no internal files yet" from "no external files" so a user staring at an empty External view doesn't think their NAS is broken.

- Empty AMS units no longer trigger hourly humidity / temperature notifications (#1619). The hourly recorder fanned out alarms for every AMS unit above threshold without checking whether the unit was actually loaded. New _ams_has_filament() helper inspects the firmware-reported tray_exist_bits bitmap (with a fallback to the tray array's tray_type strings for early-pushall shapes). Sensor history still records regardless of the gate so the System page humidity / temperature charts stay continuous — only the outbound notification is suppressed.

- Inventory: /reset-usage renamed to /reset-consumed-counter; UI label is now "Reset counter". Old name implied the endpoint zeroed weight_used; in practice it only stamps the baseline. See Upgrade Notes for the breaking-change scope. Behaviour is unchanged in both internal and Spoolman modes — only the path and the UI label moved.

- docker-compose.yml: bridge-mode warning about the FTP passive range + docker-proxy RAM footprint (#1646, reported by @TheFou). Default port mapping narrowed from 50000-51000 (1001 ports / ~3.5 GB RSS in bridge mode) to 50000-50029 (3 VPs). Comment explains how to widen for more VPs. See Upgrade Notes.

- AMS drying now enabled for H2C starting at firmware 01.02.00.00. Moved from _DRYING_UNSUPPORTED_MODELS to _DRYING_MIN_FIRMWARE with the same 01.02.00.00 floor as H2S / P2S. Both SSDP model codes the H2C advertises (O1C, O1C2) get the same gate.

---
**Fixed**

  **UI / rendering**

- AMS drying popover's "Start Drying" button no longer hidden behind iOS Safari's bottom URL bar on iPhone (#1669). Popover sizing switched from 100vh → 100dvh; popoverPosition now defaults viewportHeight from window.visualViewport?.height so the flip-above decision uses the actually-visible area.

- Project edit modal couldn't be scrolled on short screens, so Save / Cancel were unreachable (#1642, reported by @klevin92). Standard flex-modal-scroll fix: max-h-[calc(100vh-2rem)] + sticky footer with border-t separator.

- Label printing produced two identical PDFs per click (#1628). window.open(url, '_blank', 'noopener,noreferrer') returns null even on success — the fallback <a download> click fired on every click. Dropped noopener,noreferrer (same-origin blob URL, passive PDF preview, no script context).

- Service-worker activate handler no longer hangs first-install browsers (demo-site stuck spinner + Firefox Corrupted-Content). The forced client.navigate(client.url) added for kiosk-reload-on-deploy fired on every fresh origin, not just upgrades. Reload logic moved from sw.js to sw-register.js gated on hadController = !!navigator.serviceWorker.controller captured at script load — only fires when a previous SW was controlling the document.

  **Inventory / AMS**

- K-profile matching now prefers filament_id over parsed names — surfaces custom profiles in the spool form AND fixes Configure Slot showing "default 0.020" for an actively-bound K-profile (#1688 + #1689, both reported and diagnosed by @Spionkiller01 with H2C testing; #1689 also reported by @IndividualGhost1905). Spool preset ids (GFSG98_09) and K-profile filament_ids (GFG98) normalise to the same value via the new toFilamentId helper (drops _NN variant suffix, strips the S in GFS); generic GFx99 ids excluded from id-match so they don't over-match. Both surfaces — isMatchingCalibration (PA profile suggester) and matchingKProfiles (AMS slot modal) — switched to id-match-first with name fallback. SpoolBuddy kiosk surfaces inherit via shared components.

- Configure Slot now keeps the active K-profile on reopen for assigned-but-unconfigured slots (#1689 follow-up, reported and patched by @Spionkiller01). Residual case where the original cali_idx safety net was unreachable because selectedPresetInfo was null for slots with tray_type="" / no slot_preset_mappings row. Fix is Spionkiller01's diff verbatim with the existing extruder guard.

- AMS slots with a spool loaded but no material configured now show "?" instead of "Empty" (#1694, reported by @kleinwareio). Compact label below the slot circle was rendering tray.tray_type || "Empty", falling back to Empty whenever the firmware hadn't been told which material is in the slot. New branch on getEmptySlotKind matches the slicer's own convention. SpoolBuddy kiosk's AmsUnitCard carried the same bug and got the same fix.

- "Assign Spool" no longer claims the AMS slot was configured when it wasn't (#1680, reported by @kleinwareio). Backend defers the ams_filament_setting MQTT publish for empty slots (Bambu firmware drops the push) and stores the assignment with pending_config=true; the toast was always "Spool assigned and AMS slot configured" regardless. Fix branches on pending_config and surfaces a new "Assigned. Slot will configure when you insert the spool." message.

- Home-page filament assign no longer leaves the slicer unaware of PFCN cloud presets (#1648, reported by @ferch-G). Polymaker's "(Custom)" Bambu Lab H2D variants use PFCN... preset IDs (alongside GFS... and PFUS...); the cloud-detail lookup branch in apply_spool_to_slot_via_mqtt only routed the first two prefixes. Fix extends the cloud-detail-lookup branch + the discard safety net to include PFCN.

- Bambu cloud A1 Mini filament / process profiles no longer hidden in AMS slot picker (#1649, root-caused by @technopaw). Bambu shifted the @BBL suffix from A1 Mini to A1M across 106 cloud profiles mid-2026; Bambuddy's filter compared the token verbatim against the display name. New PRINTER_MODEL_SUFFIX_ALIASES table holds the bidirectional A1 Mini ⇄ A1M mapping. Same helper covers SliceModal Process/Filament compatibility. Aliases narrow on purpose — wide-net aliasing like X1 ⇄ X1C would silently group truly distinct printers.

  **Archive / stats / metadata**

- Filament usage no longer over-counts when printing one plate from a multi-plate 3MF (#1697, reported by @volodymyr-doba). Reporter printed a single 190 g lid from a 5-box+5-lid file and got debited for the whole file's 273 g. Two completion-time recorders (internal _track_from_3mf and store_print_data for Spoolman mode) called the extractor with no plate_id and summed every plate. Fix threads plate_id end-to-end via a new PrintSession.plate_id field captured from on_print_start + a parallel _print_plate_ids dict for the direct-Print path (which bypasses the queue). 9 new tests across test_usage_tracker.py, test_spoolman_tracking.py, and test_print_start_expected_promotion.py.

- VP archive/queue names with & no longer render as &amp;amp; (#1658 follow-up, reported by @IndividualGhost1905). ThreeMFParser._parse_3dmodel was parsing <metadata> payloads without html.unescape(); raw &amp; landed in the DB and React re-escaped on render. Fix applies the same loop-until-stable unescape pattern the sibling ProjectPageParser already had. Same drop: tooltip rewritten in all 11 locales to spell out the BambuStudio 2.7.x reality that BS unconditionally overwrites the user-typed Send-dialog name with the slugified 3MF Title field — there's no MQTT field carrying the original.

- Finish photo no longer shows the bed already dropped (#1397, reported by @rtadams89, @Jeff-GebhartCA, @MA2ZAK). Bambu's end-gcode lowers the build plate at print completion; capturing at gcode_state=FINISH showed the print well below the camera's natural framing. Fix sources the photo from a brief Bambu timelapse Bambuddy now force-records on every dispatched print — firmware stops recording AFTER the toolhead parks but BEFORE the bed-drop end-gcode runs, so the last frame frames the finished print correctly. BackgroundDispatchService overrides timelapse=True on the MQTT command + marks PrintArchive.bambuddy_forced_timelapse; new extract_video_last_frame ffmpeg helper extracts the last frame; _cleanup_forced_timelapse deletes both the locally-attached file and the on-printer copy when the user didn't ask for one. Verified on N=2 H2C prints; bed-slinger field verification welcome. Round-2 fix in the same drop: extractor switched from -sseof -1.0 to -update 1 (frame-per-layer recording produces sub-second videos on small prints, where the 1-second seek-from-end went before the start of the file); resolver wired into print_scheduler.py so queue-dispatched prints get the override too (not just background_dispatch.py).

  **Virtual printer**

- VP MQTT no longer disconnects idle OrcaSlicer at keep_alive * 1.5 (#1548 round 2, reported by @hollajandro). Round 1 shipped the MQTT §4.4-compliant idle disconnect; the reporter's follow-up pcap proved the spec compliance was itself the regression — OrcaSlicer sends zero MQTT packets after the initial burst (no PINGREQ), so any spec-compliant server disconnects. Real Bambu firmware doesn't enforce §4.4 (verified against the reporter's identical Orca install holding idle sessions against real hardware on the same network). Fix drops the application-level read timeout after CONNECT/auth and sets SO_KEEPALIVE on the underlying socket so the OS TCP stack detects truly dead connections.

- VP MQTT bridge net.info[].ip rewrite never armed when the printer was added by hostname/FQDN (#1429, root-caused by @Mape6, also hit @TrickShotMLG02). _ip_to_uint32_le and the host-interface picker both assume dotted-quad IPv4 and bailed on the FQDN string. New _resolve_target_to_ipv4 resolves via socket.getaddrinfo(target, None, family=socket.AF_INET) (IPv4-only filter — the net.info[*].ip field is uint32 LE). Returns None on transient DNS hiccups so the encoding doesn't break permanently. The configured FQDN is preserved into the armed log line as configured→resolved so a bad-DNS regression stays legible.

- FTP passive-port pool now sliced per-VP (10 ports each) so bridge-mode Docker drops from ~3.5 GB to ~210 MB host RAM (#1646, reported by @TheFou). Reporter measured 2002 docker-proxy host processes from the 1001-port range. Class-level PASSIVE_PORT_MIN/MAX constants are gone; new module-level compute_passive_port_slice(vp_id) returns a 10-port window allocated by VP id. Result for the reporter (single VP): ~70 MB instead of ~3.5 GB. Wrap-around behaviour at 100 VPs falls back to the per-session retry the pre-#1646 code already had. Docs corrected in the same drop (userland-proxy: false framing tightened).

- VP Queue / Archive / Review: Bambu Studio 2.7.x stayed stuck at "Downloading" after Send (#1658, reported by @IndividualGhost1905). BambuStudio 2.7.x flipped the Send sequence to verify_job → .3mf → project_file, so on_file_received's set_gcode_state("FINISH") fired first and the synthetic _send_print_response ack overwrote it back to PREPARE. The slicer waited for a FINISH transition it'd never see. Fix re-fires set_gcode_state(FINISH) from  on_print_command 1.5 s after the synthetic ack, for every non-proxy mode. Proxy mode is exempt — there the real printer drives bridge state.

- VP settings card now shows the target printer's serial in proxy mode. Runtime services (SSDP, MQTT bind identity, certificate subject) all use the target printer's actual serial; _vp_to_dict always returned the self-generated suffix-based serial, breaking the visual "one identity per VP" mental model. Fix queries the target's serial when vp.mode == proxy and target_printer_id; falls back to the self-generated serial when the target row is missing (printer deleted, race) so the card still renders.

  **Print queue / dispatch**

- Restarting Bambuddy mid-print no longer marks the live archive as "cancelled / aborted" + duplicates it + double-counts filament (#1679, reported by @IndividualGhost1905, corroborated by @Arn0uDz on watchtower-driven restarts). On startup, _on_connect broadcast on_state_change(self.state) immediately after the broker accepted the connection — BEFORE _request_push_all round-tripped real status. The reconcile saw state.state="unknown" + state.subtask_name="" and synthesised an aborted PRINT COMPLETE for every in-flight archive. When the real PRINT COMPLETE arrived, _active_prints didn't have the entry, so a brand-new archive row was created. Fix: two-layer guard — on_printer_status_change now gates reconcile spawn on state.state being a real value (parsed firmware enum); _is_active_archive_stale returns (False, "") when state.state is empty / "unknown" / None.

- Print queue no longer wedges in "Currently Printing" when a printer accepts project_file but never starts (#1678, reported by @kleinwareio). The _watchdog_print_start returned success as soon as subtask_id advanced — added for H2D's #1078 FINISH→PREPARE delay — but subtask_id advance is "command landed" not "actually printing". When the printer accepted the file but wedged (cloud+LAN re-auth dance after a power cycle, old firmware), the queue row stayed status='printing', in-memory _expected_prints kept the entry, and every subsequent queue item was blocked. Fix splits the watchdog into Phase A (existing 90 s) + Phase B (new 180 s, ~3.5× the worst observed H2D FINISH→PREPARE delay): if Phase A exited via subtask_id-alone, Phase B keeps watching for the active-state transition before reverting. Phase B explicitly does NOT force-reconnect (subtask_id advance proves the publish landed; force-reconnect mid-parse triggers 0500_4003 per #1150).

- Print Log "User" column now shows the user for prints started from the Queue (#1670, reported by @JmanB52D). Two-link gap on the Queue→manual-start path: POST /queue/{id}/start discarded the user dep, and PrintScheduler._start_print never called set_current_print_user. Fix writes item.created_by_id on the route (first-claim-wins so UI-added attribution isn't overwritten), and forwards the resolved username into printer_manager.set_current_print_user from the scheduler.

- Print queue require_previous_success no longer cascades indefinitely after a user-cancelled print (#1667, fully root-caused by @599w6c26tv-droid). Reporter saw a single user-cancelled print block 18 downstream queue items over 3 days, with reproducible logs + DB dumps proving two distinct bugs: the lookback query excluded cancelled (so user-cancellations were never found as the recent predecessor — the query walked past) AND included skipped (so one bug-cascaded skip became the next item's "failed predecessor"). Fix swaps the lookback list to ["completed", "failed", "cancelled", "aborted"] and broadens the success check to prev_item.status in ("completed", "cancelled"). Conservative one-shot recovery migration in run_migrations resets only the skipped items whose immediate real predecessor was cancelled — narrow enough not to disturb skipped items whose true predecessor was a real failure.

- Print modal now exposes a "Nozzle Offset Calibration" toggle for dual-nozzle printers (#1682, reported by @louiskleiman). The nozzle_offset_cali field was hardcoded to 2 (skip) in the MQTT project_file payload. New end-to-end plumbing with a hard MQTT-layer gate on dual-nozzle (is_dual_nozzle_model() + runtime _is_dual_nozzle flag) — even a stale queue item from when the printer was misidentified gets downgraded to 2 at dispatch. New default_nozzle_offset_cali setting (default True, matches BambuStudio behaviour); Settings row + QueuePage bulk-edit toggle only render when at least one registered printer is dual-nozzle.

  **Cloud / external**

- Firmware-update check no longer 403s against Bambu Lab's Cloudflare-gated download page (#1666, reported by @arekm). CF upped bot protection on bambulab.com to a JA3 / TLS-fingerprint challenge; plain Python TLS handshakes (httpx, requests, urllib) don't match Chrome's ClientHello bytes. Fix uses curl_cffi for the two bambulab.com fetches only. The HTTP-layer User-Agent stays Bambuddy/1.0 honest per the 2026-05-12 compliance commitment — only TLS handshake bytes match Chrome. Pinned by a test (test_bambulab_curl_cffi_session_keeps_honest_user_agent) that fails the build if the UA override is ever dropped. Soft dependency: if the wheel doesn't install on the host platform, the service logs a startup warning and falls back to httpx (wiki-based version detection continues to work; only the in-app firmware download URL stops resolving). wiki.bambulab.com and the CDN path stay on httpx — neither sits behind the same JA3 gate.

- MakerWorld URL imports into a writable external folder wrote bytes to internal storage, not the NAS (#1645, reported and root-caused by @needo37). save_3mf_bytes_to_library accepted folder_id but never loaded the folder or inspected is_external / external_path — hardcoded the destination to internal storage and left the row with is_external=False. Same class of bug as #1112 (fixed for multipart-upload + move paths, never applied to byte-import). Fix mirrors the multipart-upload path: load the target LibraryFolder, feed it through _resolve_upload_destination, persist via _stored_file_path(dest, is_external).

  **Auth / session**

- Tabs no longer go silently zombie after the JWT expires — auth-expiry now redirects to /login on the same tab (#1698, reported by @TCL987, fix mirrored from reporter's fork). When a 401 with a token-invalidating message landed in client.ts, the handler called setAuthToken(null) to drop the token, but AuthContext.user is a React state value that doesn't react to module-level setters. ProtectedRoute only redirects when user === null, so the protected tree kept rendering, every request went out with no Authorization header, and the UI silently looked empty. Fix dispatches a window.dispatchEvent(new CustomEvent('auth:expired')) after setAuthToken(null); AuthContext listens and calls setUser(null). Generic 401 Authentication required (no token-invalidating message) still doesn't fire the event — preserves the existing transient-401 tolerance.

  **System / install**

- System page now reports the container's uptime / boot time, not the host's (#1690, reported by @IndividualGhost1905). psutil.boot_time() reads /proc/stat:btime, which on shared-kernel containers is the host's boot time. Fix reads psutil.Process(1).create_time() — PID 1 in a container is the entrypoint, on bare metal / VMs it's effectively the host init. Defensive fallback to boot_time() if /proc/1/stat is unreadable.

- Native systemd install no longer fails when INSTALL_PATH is under /home (#1685, reported by @Geoff-S). bambuddy.service shipped with ProtectHome=true, which makes /home/* invisible to the service namespace; ReadWritePaths=$INSTALL_PATH doesn't reliably re-expose subpaths for executable resolution. Fix detects INSTALL_PATH == /home/* and emits ProtectHome=read-only for that case; the default /opt/bambuddy/ install keeps ProtectHome=true.

- X2D archives lose 3MF metadata because FTPS handshake fails on firmware 01.01.00.00 (#1638, reported by @vasmarfas). Same shape as the P2S 01.02.00.00 FTPS bug from #1401 — Python 3.13's TLS-1.3 default rejected by the X2D's implicit-FTPS server. Fix adds an X2D entry to the per-model ftp_profiles.py registry with cap_tls_v1_2=True and an N6 → X2D SSDP alias. Honest caveat: hypothesis-driven trial. The TLS-1.2 cap is the most likely cure given symptom family resemblance to #1401; if it doesn't clear the error, the registry slot stays useful as a tuning anchor for the next round of diagnostics.

  **Settings**

- Profile editor filament type dropdown now lists PLA-CF and the other Bambu CF / GF / specialty materials (#1686, reported by @Bgabor997). The filament_type select shipped with 11 base materials; expanded to 25 BambuStudio-aligned options grouped by family (PLA + CF/GF/AERO, PETG + CF, ABS + GF, ASA + CF/GF, PC, PCTG, PA family + CF/PAHT-CF/PA6-CF/PA6-GF, PET-CF, TPU, PPS family + CF/GF for X1E, PVA, HIPS).

- Scheduled local backup time is now interpreted as local time, not UTC (#1602 follow-up). Pre-fix the picker stored HH:MM and _calculate_next_run replaced into datetime.now(timezone.utc) — a UTC+3 user who wanted 21:00 local had to enter 18:00. Post-fix uses the container's local timezone resolved from TZ via zoneinfo.ZoneInfo. UTC fallback when TZ is unset or unrecognised. UI now renders the resolved zone name next to the time field. One-time behaviour change: users who   entered a UTC-offset workaround will see the first scheduled cycle after upgrade run at their local-TZ offset earlier than expected.

  **Internal / observability**

- Background asyncio tasks no longer get garbage-collected mid-flight (#1648 follow-up). Support-bundle review surfaced 94 Task was destroyed but it is pending! warnings in 8 days of v0.2.4.5 — asyncio holds only a weak reference to the result of create_task, so "fire and forget" call sites that don't store the returned task got GC'd before completion. The warning gives no traceback, so the originating exception (if any) vanished silently. New spawn_background_task(coro, *, name=None) helper stores a strong reference, attaches a done-callback that auto-removes on completion AND logs uncaught exceptions with the originating traceback. 16 truly-orphan create_task call sites migrated; other sites already keeping strong refs are unchanged.

---
**Credits**

  External contributors and reporters who drove this release: @samedyuksel (PR #1659 CSV import / export), @Spionkiller01 (root-caused + patched #1688 / #1689 / #1689 follow-up with H2C testing), @TCL987 (#1698 JWT zombie tabs — fix mirrored from their fork), @needo37 (#1645 MakerWorld external folder, plus the original #1593 multi-plate diagnosis), @volodymyr-doba (#1697 multi-plate filament tracking), @kleinwareio (#1680 / #1694 / #1678), @IndividualGhost1905 (#1679 / #1658 / #1690 / #1687 / #1670), @hasmar04 (#1329), @CMW-ISS (#1281), @hollajandro (#1548 round 2), @klevin92 (#1642), @kcw96 (#1621), @TheFou (#1646 + Docker docs corrections), @louiskleiman (#1682), @ferch-G (#1648), @technopaw (#1649), @arekm (#1666 with the working bypass demonstrated), @JmanB52D (#1670), @599w6c26tv-droid (#1667 fully root-caused), @Bgabor997 (#1686), @Geoff-S (#1685), @vasmarfas (#1638), @MartinNYHC (#1564), @d3nn3s08 (#1657), @rtadams89, @Jeff-GebhartCA, @MA2ZAK (#1397), @vmhomelab's Windows installer carries forward unchanged. 
  
Thank you!

