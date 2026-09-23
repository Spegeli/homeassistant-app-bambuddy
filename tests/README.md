# Tests

Two stages. Both are channel-scoped: each channel is checked against its own
`config.yaml`, translations and scripts. Daily may legitimately differ from
Stable while it carries an upstream feature Stable has not shipped yet, so a
difference between the channels is reported, never failed.

## Stage 1 - `lint.py` (seconds, no Docker)

```bash
pip install pyyaml
python3 tests/lint.py                    # both channels
python3 tests/lint.py bambuddy           # one channel
```

Checks per channel: `config.yaml` keys and types, the exact
`version: "<version>"` line the auto-update reads and rewrites as text,
`slug`/`image`/`arch` consistency, `options` and `schema` in the same order,
all five translation files carrying exactly those keys in that order with name
and description, the run/finish shebangs and line endings (on the raw bytes),
`exec uvicorn` as the last line of `run`, the `/config` data and log lines,
the `io.hass.*` labels, `ENTRYPOINT` and the blanked `CMD` (whole lines, so a
commented-out instruction does not count), that every file under `rootfs/` is
covered by a `COPY` instruction (whole path components), and - for daily -
that `upstream.digest` is `sha256:` plus 64 hex characters (a missing file is
only a note: the next Auto-update run pins it).

## Stage 2 - container tests (needs Docker)

```bash
docker build -t bambuddy:test --build-arg BAMBUDDY_VERSION=1.2.5.5 --build-arg BUILD_ARCH=amd64 bambuddy
# Daily pins its upstream base by digest (upstream has no versioned daily tags):
docker build -t bambuddy:test --build-arg BAMBUDDY_VERSION=<version> \
  --build-arg BAMBUDDY_DIGEST=$(cat bambuddy-daily/upstream.digest) --build-arg BUILD_ARCH=amd64 bambuddy-daily
bash tests/image-checks.sh bambuddy bambuddy:test          # version from config.yaml
bash tests/image-checks.sh bambuddy bambuddy:test 1.2.5.6  # explicit expected version
bash tests/smoke.sh bambuddy:test                          # all scenarios
bash tests/smoke.sh bambuddy:test all-on                   # one scenario
```

`image-checks.sh` inspects the built image: `io.hass.version` against the
expected version (this only proves the label was set from the build argument;
the no-cache test build guards against a stale image under a new tag),
`io.hass.type`/`arch`, `ENTRYPOINT`/`CMD`, the `ENV` defaults including
`S6_SERVICES_GRACETIME`, the curl-based `HEALTHCHECK`, 0755 on run and finish,
the `with-contenv` symlink, bashio, jq, `ip -j`, and that `import cv2` works.

`smoke.sh` boots the image once per scenario in `scenarios/` against the mock
Supervisor in `mock-supervisor/`, then asserts the web UI, `/health`, exactly
one uvicorn process, the `/config` symlinks, a clean log, and the environment
the run script exported. The trust-store scenarios also make a real HTTPS
request with httpx and the uvicorn process's own environment, against a server
certificate signed by a CA generated for the test. `defaults` runs the image's
`HEALTHCHECK` command against the app. It finishes with the shutdown path
(exit 256, no halt) and the crash path (exit 3 halts the container).

The mock matters: bashio talks to `${SUPERVISOR_API}`, and without it every
`bashio::config` call fails and the run script skips every option block, so the
test would pass while proving nothing.

## Scenarios

| File | Covers |
|------|--------|
| `defaults.json` | shipped defaults, no empty variables exported |
| `all-on.json` | debug, share + media, trust store with a generated CA, HTTPS round-trip |
| `media-only.json` | `BAMBUDDY_EXTERNAL_ROOTS=/media` without a leading colon |
| `cert-missing.json` | both warnings, app still starts |
| `empty-origins.json` | `TRUSTED_FRAME_ORIGINS` stays unset, not empty |
| `cert-subdir-pem.json` | CA in a subfolder with a `.pem` name is installed and trusted |
| `cert-invalid.json` | a file that is no certificate: warning, app still starts |

A new option needs: the option in both `config.yaml` files, all ten
translation files, the options section in both `DOCS.md`, a scenario here, and
its assertion in `smoke.sh`.

## In CI

`_test.yml` is the reusable workflow (lint, then build the image for amd64
and arm64, each natively, and run both scripts). It is called by:

- `test.yml` - manual only (Actions -> Test -> Run workflow), with a channel
  choice and a switch for the container stage. Nothing runs on a push, so small
  commits do not each trigger a build.
- `auto-update.yml` - between `check` and `build`, so a failing test means
  nothing is pushed to GHCR and `config.yaml` is never bumped
- `build.yml` - before the manual build; untick `run_tests` to skip

Build and test resolve the version (and, for daily, the upstream digest)
through the same script, `.github/scripts/resolve-build-args.sh`, so a test
always builds exactly what the build would push.

When anything after the check fails in the auto-update (tests, image build or
push, commit), the workflow opens an issue titled
`Auto-update blocked: <channel> <version>` and skips that version while the
issue is open, so the hourly cron does not retry it forever. Close the issue
after fixing the cause.
