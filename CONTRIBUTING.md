# Contributing

Thanks for your interest in improving this app. This is a small personal project, so the process is deliberately light.

By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

## Scope first

This repository **only packages [BamBuddy](https://github.com/maziggy/bambuddy) as a Home Assistant app**: Dockerfiles, `config.yaml`, the s6 run scripts, translations, documentation and the GitHub Actions workflows.

Bugs and feature requests for **BamBuddy itself** (printer handling, UI, archive, camera, virtual printer behaviour, ...) belong in the upstream project: <https://github.com/maziggy/bambuddy/issues>

## Ways to contribute

- **Report a security vulnerability** — privately, never as a public issue: see the [security policy](SECURITY.md).
- **Report a bug** — [open a bug report](https://github.com/Spegeli/homeassistant-app-bambuddy/issues/new?template=bug_report.yml) with the channel (Stable / Daily), the app and Home Assistant versions, the architecture and the **full app log** from the startup on.
- **Suggest a feature** — [open a feature request](https://github.com/Spegeli/homeassistant-app-bambuddy/issues/new?template=feature_request.yml).
- **Improve translations** — the app options are translated into English, German, French, Spanish and Italian (`translations/*.yaml` in both channels); corrections by native speakers are welcome.
- **Submit a change** — see [Pull requests](#pull-requests).

## Branches

- **`main`** is what Home Assistant installs: it reads `config.yaml`, the translations and `DOCS.md` from there. It changes only through the pull request from `dev`, which merges only with a green **Validation result**, and through the version commits of the Auto-update workflow.
- **`dev`** is where changes come together before they go live, contributions included.
- **Topic branches** start from `dev` and go back into it.

## Pull requests

1. Fork the repository and branch from `dev`.
2. Keep the change focused — one topic per pull request.
3. Please write the commit messages as [Conventional Commits](https://www.conventionalcommits.org) — `fix:`, `feat:`, `docs:`, `test:`, `ci:` or `chore:`, e.g. `fix: keep the custom CA when its file name has spaces`.
4. Open the pull request against **`dev`** and fill in the template.
5. Validate checks it automatically (see [Continuous integration](#continuous-integration)); it is merged once its **Validation summary** is green. A first-time contributor's run waits for the maintainer's approval, so run the tests yourself first (see [Testing locally](#testing-locally)): you get the answer sooner.

**Channels.** There are two channels: `bambuddy/` (Stable) and `bambuddy-daily/` (Daily). By default, apply a change to **both** so they stay consistent. Exception: if the change depends on an upstream feature that so far only exists in BamBuddy's daily build, change `bambuddy-daily/` only. Stable follows once that feature ships in a stable BamBuddy release. The pull request template asks which channels you changed.

**Don't touch** `version:` in `config.yaml` or `CHANGELOG.md`. Both are updated automatically by the Auto-update workflow.

**New or changed options** need all of these, in both channels and in the same order as in `config.yaml`:
- `options` and `schema` in `config.yaml`
- every file in `translations/` (`en`, `de`, `fr`, `es`, `it`)
- the options section in `DOCS.md`
- a scenario in `tests/scenarios/` and its assertions in `tests/smoke.sh`

**Runtime settings** (paths, environment variables, option handling) belong in `rootfs/etc/services.d/bambuddy/run`.

**Don't add** system packages the upstream image already ships (e.g. `ffmpeg`, `curl`, `ca-certificates`, OpenCV).

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

## Things that are easy to get wrong

- **Line endings.** `run` and `finish` fail in the image with Windows line endings (CRLF). `.gitattributes` keeps LF in the repository; on Windows, make sure Git does not convert them on checkout (`git config core.autocrlf false`). `tests/lint.py` checks it.
- **A plain `docker run` tests nothing.** Without a Supervisor, `bashio::config` cannot read the app options, and the run script skips every option block — the code you changed never runs. `tests/smoke.sh` starts a mock Supervisor for exactly that.
- **Both channels share `run` and `finish`.** The two copies are identical; change both.
- **`exec uvicorn ...` stays the last line of `run`.** uvicorn then receives Home Assistant's SIGTERM directly and shuts BamBuddy down cleanly.
- **Data belongs in `/config`,** the app's configuration folder (`/config/data`, `/config/logs`) — never in `/data`, which Home Assistant deletes on every uninstall.
- **A new file under `rootfs/` needs its own `COPY` line** in both Dockerfiles: they copy only `rootfs/etc/services.d/bambuddy`.
- **The build warning `InvalidDefaultArgInFrom` is expected.** `BAMBUDDY_VERSION` (and the Daily's `BAMBUDDY_DIGEST`) deliberately have no default, so an image never drifts from `config.yaml`. Don't add one.
- **uvicorn listens on `0.0.0.0`, not `::`.** `::` fails to start on hosts with IPv6 switched off.

## Continuous integration

One workflow, **Validate** (`.github/workflows/validate.yml`), checks every change. The checks live in `.github/workflows/_validate.yml`, which the Auto-update and Build image workflows run as well:

| Check | What it runs |
|---|---|
| Lint | `tests/lint.py` and a shell syntax check, per channel |
| Container tests | the image built natively on amd64 and arm64, then `tests/image-checks.sh` and `tests/smoke.sh` |

When Validate runs:

- **A push to `dev`** — everything.
- **A push to any other branch but `main`** — lint only.
- **A pull request to `dev` or `main`** — everything.
- **By hand** — Actions → Validate → Run workflow, with a choice of channel and of the container tests.

Validate does not run on `main` itself: changes reach it only through a validated pull request, or as the Auto-update's version commit, validated just before. A newer push to the same branch, or a new commit in the same pull request, cancels the run it makes obsolete. A run started by hand and a push's run on the same branch cancel each other as well, whichever starts later cancelling the other: start one by hand only after the push's run has finished, or that run is cancelled and its Validation summary turns red.

One last check sums up each run: green when every check passed or its channel was left out by hand, red when one failed or the run was cancelled. A pull request to `main` calls it **Validation result**, the check `main` requires. Every other run — a pull request to `dev`, a push, a run by hand — calls it **Validation summary**: GitHub counts a required check by its name on a commit, so only the run that validates the merge into `main` may answer for it. A pull request to `dev` is merged once its Validation summary is green.

A pull request from a fork runs the same checks with a read-only token and no secrets: Validate uses `pull_request`, never `pull_request_target`. A first-time contributor's run waits for the maintainer's approval.

## Workflows in your fork

GitHub keeps Actions switched off in a fork until you enable them on its **Actions** tab.

**Validate** works as it is – it needs no secrets. In your fork it validates every push to a branch other than `main` – fully on `dev`, lint only elsewhere – and runs the full validation on pull requests to your fork's `dev` or `main`. Your pull request here is validated in this repository anyway.

**Auto-update** and **Build image** publish to this repository's packages on GHCR, so in a fork they fail when pushing the image. If you don't want your own images, disable **Auto-update** on your fork's Actions tab – otherwise it fails every hour as soon as a new BamBuddy version comes out. To publish your own images instead, change:
- `image:` in `.github/workflows/auto-update.yml` and `.github/workflows/build.yml` (two per file)
- `image:` in both `config.yaml`, or Home Assistant keeps pulling this repository's images
- the expected image name in `tests/lint.py`, or the validation fails
- the visibility of your new GHCR packages to public – new packages start private, and Home Assistant cannot pull private ones
- optionally `org.opencontainers.image.source` in both Dockerfiles and `repository.json`, and enable Issues in your fork (the Auto-update opens an issue when it gets blocked)

Both workflows only run on `main`. You need no deploy key: without the `AUTO_UPDATE_DEPLOY_KEY` secret, the Auto-update commits with the regular token, which works as long as your `main` has no ruleset that blocks it.

**Keep these changes out of pull requests here.** Start a pull request branch from this repository's `dev` (e.g. `git switch -c my-fix upstream/dev`), not from a fork `main` that carries them.

## After merging

- A change on `dev` reaches `main` with the next pull request from `dev`.
- Changes to `config.yaml`, translations or `DOCS.md` take effect when Home Assistant reloads the repository.
- Changes to the image (Dockerfile, `rootfs/`) need a new image build: the Daily image gets one with its next automatic update, the Stable image with the next BamBuddy release, or earlier when the maintainer builds it by hand. Home Assistant offers an update only for a new version number, so installed apps get the change with the next version.

## License

Contributions are licensed under the repository's [MIT License](LICENSE). BamBuddy itself remains AGPL-3.0-only.
