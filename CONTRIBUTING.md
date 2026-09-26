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

**Don't touch** `version:` in `config.yaml` or `CHANGELOG.md`. Both are updated automatically by the Auto-update workflow.

**New or changed options** need all of these, in the same order as in `config.yaml`:
- `options` and `schema` in `config.yaml`
- every file in `translations/` (currently `en`, `de`, `fr`, `es`, `it`)
- the options section in `DOCS.md`
- a scenario in `tests/scenarios/` and its assertions in `tests/smoke.sh`

**Runtime settings** (paths, environment variables, option handling) belong in `rootfs/etc/services.d/bambuddy/run`. Keep `exec uvicorn ...` as the last line.

**Don't add** system packages the upstream image already ships (e.g. `ffmpeg`, `curl`, `ca-certificates`, OpenCV).

**PR description:** what changed, why, and how you tested it (a log excerpt is ideal).

**Automatic checks:** every pull request to `main` runs the **Validate** workflow – static checks, then the image built and started on amd64 and arm64 against a mock Supervisor. A pull request can only be merged once the **Validation result** check is green. If this is your first contribution here, the checks start once the maintainer approves them (a GitHub default for first-time contributors).

## Testing locally

You need Docker with Buildx, and Python 3 with PyYAML for the static checks. The full recipe is in [tests/README.md](tests/README.md); in short, for the Stable image:

```bash
python3 tests/lint.py
docker buildx build --load -t bambuddy:test \
  --build-arg BAMBUDDY_VERSION="$(grep '^version:' bambuddy/config.yaml | cut -d'"' -f2)" \
  --build-arg BUILD_ARCH=amd64 \
  bambuddy/
bash tests/image-checks.sh bambuddy bambuddy:test
bash tests/smoke.sh bambuddy:test
```

The Daily image pins its upstream base by digest, so it needs one more build argument:

```bash
docker buildx build --load -t bambuddy:test \
  --build-arg BAMBUDDY_VERSION="$(grep '^version:' bambuddy-daily/config.yaml | cut -d'"' -f2)" \
  --build-arg BAMBUDDY_DIGEST="$(cat bambuddy-daily/upstream.digest)" \
  --build-arg BUILD_ARCH=amd64 \
  bambuddy-daily/
```

On ARM machines (e.g. Apple Silicon, Raspberry Pi) use `BUILD_ARCH=aarch64`.

`smoke.sh` starts the image against a small mock of the Home Assistant Supervisor. That matters: the run script reads the app options through the Supervisor API, so a container started without it skips every option and never runs the code you changed.

## Workflows in your fork

GitHub keeps Actions switched off in a fork until you enable them on its **Actions** tab.

**Validate** works as it is – it needs no secrets. In your fork it lints every push to a branch other than `main` and runs the full validation on pull requests to your fork's `main`. Your pull request here is validated in this repository anyway.

**Auto-update** and **Build image** publish to this repository's packages on GHCR, so in a fork they fail when pushing the image. If you don't want your own images, disable **Auto-update** on your fork's Actions tab – otherwise it fails every hour as soon as a new BamBuddy version comes out. To publish your own images instead, change:
- `image:` in `.github/workflows/auto-update.yml` and `.github/workflows/build.yml` (two per file)
- `image:` in both `config.yaml`, or Home Assistant keeps pulling this repository's images
- the expected image name in `tests/lint.py`, or the validation fails
- the visibility of your new GHCR packages to public – new packages start private, and Home Assistant cannot pull private ones
- optionally `org.opencontainers.image.source` in both Dockerfiles and `repository.json`, and enable Issues in your fork (the Auto-update opens an issue when it gets blocked)

Both workflows only run on `main`. You need no deploy key: without the `AUTO_UPDATE_DEPLOY_KEY` secret, the Auto-update commits with the regular token, which works as long as your `main` has no ruleset that blocks it.

**Keep these changes out of pull requests here.** Start a pull request branch from this repository's `main` (e.g. `git switch -c my-fix upstream/main`), not from a fork `main` that carries them.

## After merging

- Changes to `config.yaml`, translations or `DOCS.md` take effect when Home Assistant reloads the repository.
- Changes to the image (Dockerfile, run script) need a new image build. The maintainer starts these builds manually, so a merged PR does not reach users immediately.

## Code of Conduct and license

Please follow the [Code of Conduct](CODE_OF_CONDUCT.md). Contributions are licensed under the repository's [MIT License](LICENSE). BamBuddy itself remains AGPL-3.0-only.
