# Contributing

Thanks for wanting to help! This repository is small, so these guidelines are too.

## Scope first

This repository **only packages [BamBuddy](https://github.com/maziggy/bambuddy) as a Home Assistant app**: Dockerfiles, `config.yaml`, the s6 run scripts, translations, documentation and the GitHub Actions workflows.

Bugs and feature requests for **BamBuddy itself** (printer handling, UI, archive, camera, virtual printer behaviour, ...) belong in the upstream project: <https://github.com/maziggy/bambuddy/issues>

## Issues

- Use the issue forms (**Bug report** / **Feature request**).
- For bugs, include the channel (Stable / Daily), app and Home Assistant versions, architecture, and the **full app log** from the startup on.

## Pull requests

**Channels.** There are two channels: `bambuddy/` (Stable) and `bambuddy-daily/` (Daily). By default, apply a change to **both** so they stay consistent. Exception: if the change depends on an upstream feature that so far only exists in BamBuddy's daily build, change `bambuddy-daily/` only. Stable follows once that feature ships in a stable BamBuddy release. Say which channel(s) you changed and why in the PR description.

**Don't touch** `version:` in `config.yaml` or `CHANGELOG.md`. Both are updated automatically by the version workflow.

**New or changed options** need all of these, in the same order as in `config.yaml`:
- `options` and `schema` in `config.yaml`
- every file in `translations/` (currently `en`, `de`, `fr`, `es`, `it`)
- the options section in `DOCS.md`

**Runtime settings** (paths, environment variables, option handling) belong in `rootfs/etc/services.d/bambuddy/run`. Keep `exec uvicorn ...` as the last line.

**Don't add** system packages the upstream image already ships (e.g. `ffmpeg`, `curl`, `ca-certificates`, OpenCV).

**PR description:** what changed, why, and how you tested it (a log excerpt is ideal).

## Testing locally

You need Docker with Buildx. Build the Stable image. The version is read from `bambuddy/config.yaml`, so it always matches the current release:

```bash
docker buildx build --load -t bambuddy-test \
  --build-arg BAMBUDDY_VERSION="$(grep '^version:' bambuddy/config.yaml | cut -d'"' -f2)" \
  --build-arg BUILD_ARCH=amd64 \
  bambuddy/
```

Or the Daily image:

```bash
docker buildx build --load -t bambuddy-test \
  --build-arg BAMBUDDY_VERSION="$(grep '^version:' bambuddy-daily/config.yaml | cut -d'"' -f2)" \
  --build-arg BUILD_ARCH=amd64 \
  bambuddy-daily/
```

On ARM machines (e.g. Apple Silicon, Raspberry Pi) use `BUILD_ARCH=aarch64`.

Start it outside Home Assistant. The run script expects the Supervisor token and the options file, so provide stand-ins:

```bash
echo '{"debug": false}' > options.json
docker run --rm -p 8000:8000 \
  -e SUPERVISOR_TOKEN=dummy \
  -e TZ=Europe/Berlin \
  -v "$PWD/options.json:/data/options.json:ro" \
  bambuddy-test
```

Expect `Setting TZ: Europe/Berlin` and `Uvicorn running on http://0.0.0.0:8000` in the log, and no `Traceback` or `unbound variable`. Errors about contacting the Supervisor API are expected outside Home Assistant.

Quick check that OpenCV works:

```bash
docker run --rm --entrypoint "" bambuddy-test python3 -c "import cv2; print(cv2.__version__)"
```

## After merging

- Changes to `config.yaml`, translations or `DOCS.md` take effect when Home Assistant reloads the repository.
- Changes to the image (Dockerfile, run script) need a new image build. The maintainer starts these builds manually, so a merged PR does not reach users immediately.

## Code of Conduct and license

Please follow the [Code of Conduct](CODE_OF_CONDUCT.md). Contributions are licensed under the repository's [MIT License](LICENSE). BamBuddy itself remains AGPL-3.0-only.
