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
- **Improve translations** — corrections and new languages are welcome, see [Translations](#translations).
- **Submit a change** — see [Pull requests](#pull-requests).

## Branches

- **`main`** is what Home Assistant installs: it reads `config.yaml`, the translations and `DOCS.md` from there. It changes only through the pull request from `dev`, which merges only with a green **Validation result**, and through the version commits of the Auto-update workflow.
- **`dev`** is where changes come together before they go live, contributions included.
- **Topic branches** start from `dev` and go back into it.

## Pull requests

1. Fork the repository and branch from `dev`.
2. Keep the change focused — one topic per pull request.
3. Please write the commit messages as [Conventional Commits](https://www.conventionalcommits.org) — see [Commit messages](#commit-messages).
4. Open the pull request against **`dev`** and fill in the template.
5. Validate checks it automatically (see [Continuous integration](#continuous-integration)); it is merged once its **Validation summary** is green. A first-time contributor's run waits for the maintainer's approval, so run the tests yourself first (see [Testing locally](#testing-locally)): you get the answer sooner.

**Channels.** There are two channels: `bambuddy/` (Stable) and `bambuddy-daily/` (Daily). By default, apply a change to **both** so they stay consistent. Exception: if the change depends on an upstream feature that so far only exists in BamBuddy's daily build, change `bambuddy-daily/` only. Stable follows once that feature ships in a stable BamBuddy release. The pull request template asks which channels you changed.

**Don't touch** `version:` in `config.yaml` or `CHANGELOG.md`. Both are updated automatically by the Auto-update workflow.

**New or changed options** need all of these, in both channels and in the same order as in `config.yaml`:
- `options` and `schema` in `config.yaml`
- every file in `translations/` (see [Translations](#translations))
- the options section in `DOCS.md`
- a scenario in `tests/scenarios/` and its assertions in `tests/smoke.sh`

**Runtime settings** (paths, environment variables, option handling) belong in `rootfs/etc/services.d/bambuddy/run`.

**Don't add** system packages the upstream image already ships (e.g. `ffmpeg`, `curl`, `ca-certificates`, OpenCV).

## Development setup

The app is a container image built on top of BamBuddy's: a change to a Dockerfile or to `rootfs/` takes effect only in a new image, while Home Assistant reads `config.yaml`, the translations and `DOCS.md` straight from the repository.

1. Fork and clone the repository, and branch from `dev`.
2. Install Docker with Buildx, and Python 3 with PyYAML for the static checks.
3. Test locally as below. You need no Home Assistant for it: `tests/smoke.sh` runs the image against a mock Supervisor.

Home Assistant installs this app as a ready-made image from GHCR (`image:` in `config.yaml`). To try a change to the image on a real Home Assistant, publish your own image first — see [Workflows in your fork](#workflows-in-your-fork).

To see what BamBuddy is doing, turn on **Debug** in the app's **Configuration** tab. The **Log** tab shows the output; BamBuddy's own log files are in the app's configuration folder (`addon_configs` → `[slug]_bambuddy` or `[slug]_bambuddy_daily` → `logs`).

### Testing locally

The full recipe is in [tests/README.md](tests/README.md); in short, for the Stable image:

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

On ARM machines (e.g. Apple Silicon, Raspberry Pi) use `BUILD_ARCH=aarch64`. To repeat a single scenario: `bash tests/smoke.sh bambuddy:test all-on`.

On Windows, run the scripts from Git Bash. Don't export `MSYS_NO_PATHCONV` globally: `smoke.sh` sets it for Docker only, and exported it breaks the `curl` the script uses. If a scenario fails only now and then, repeat it alone.

If you change a workflow, run [actionlint](https://github.com/rhysd/actionlint) as well — CI does not:

```bash
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:latest
```

On Windows in Git Bash: `MSYS_NO_PATHCONV=1 docker run --rm -v "$(cygpath -w "$PWD"):/repo" -w /repo rhysd/actionlint:latest`.

CI runs the same checks as above, except actionlint (see [Continuous integration](#continuous-integration)).

## Project layout

The two channels have the same structure; paths below `bambuddy/` apply to `bambuddy-daily/` as well.

| Path | Responsibility |
|---|---|
| `bambuddy/config.yaml` | The app for Home Assistant: image, permissions, options and their schema, watchdog |
| `bambuddy/Dockerfile` | The image: BamBuddy's upstream image plus s6-overlay and bashio, labels, health check |
| `bambuddy/rootfs/etc/services.d/bambuddy/run` | Starts BamBuddy: sets up `/config`, turns the app options into environment variables, ends with `exec uvicorn` |
| `bambuddy/rootfs/etc/services.d/bambuddy/finish` | Runs when BamBuddy ends: logs why and stops the app |
| `bambuddy/translations/` | Names and descriptions of the options in the app's **Configuration** tab (`en`, `de`, `fr`, `es`, `it`) |
| `bambuddy/DOCS.md`, `bambuddy/README.md` | The app's **Documentation** tab and its card in the app store |
| `bambuddy/CHANGELOG.md` | BamBuddy's release notes, written by the Auto-update workflow |
| `bambuddy-daily/upstream.digest` | The BamBuddy daily image the Daily channel is pinned to, written by the Auto-update workflow |
| `.github/workflows/` | Validate, Auto-update and Build image, and their shared parts `_validate.yml` and `_build.yml` |
| `.github/scripts/resolve-build-args.sh` | What to build — version, digest and image description — for both building and validating |
| `tests/` | `lint.py`, `image-checks.sh`, `smoke.sh` with its Supervisor mock and scenarios (see [tests/README.md](tests/README.md)) |
| `repository.json` | The repository's name and maintainer for Home Assistant's app store |

Home Assistant pulls the image named in `config.yaml` from GHCR. At start, s6-overlay runs `run`, which reads the options through the Supervisor API (bashio) and starts BamBuddy; when BamBuddy ends, `finish` stops the app, and Home Assistant's watchdog decides whether it starts again. The Auto-update workflow watches BamBuddy's releases and daily builds, validates and publishes each new image, and then sets the new version in `config.yaml`.

## Things that are easy to get wrong

- **Line endings.** `run` and `finish` fail in the image with Windows line endings (CRLF). `.gitattributes` keeps LF in the repository; on Windows, make sure Git does not convert them on checkout (`git config core.autocrlf false`). `tests/lint.py` checks it.
- **A plain `docker run` tests nothing.** Without a Supervisor, `bashio::config` cannot read the app options, and the run script skips every option block — the code you changed never runs. `tests/smoke.sh` starts a mock Supervisor for exactly that.
- **Both channels share `run` and `finish`.** The two copies are identical; change both.
- **`exec uvicorn ...` stays the last line of `run`.** uvicorn then receives Home Assistant's SIGTERM directly and shuts BamBuddy down cleanly.
- **Data belongs in `/config`,** the app's configuration folder (`/config/data`, `/config/logs`) — never in `/data`, which Home Assistant deletes on every uninstall.
- **A new file under `rootfs/` needs its own `COPY` line** in both Dockerfiles: they copy only `rootfs/etc/services.d/bambuddy`.
- **The build warning `InvalidDefaultArgInFrom` is expected.** `BAMBUDDY_VERSION` (and the Daily's `BAMBUDDY_DIGEST`) deliberately have no default, so an image never drifts from `config.yaml`. Don't add one.
- **uvicorn listens on `0.0.0.0`, not `::`.** `::` fails to start on hosts with IPv6 switched off.

## Translations

The app options are translated into English (`en`), German (`de`), French (`fr`), Spanish (`es`) and Italian (`it`). Home Assistant shows them in the app's **Configuration** tab, in each user's profile language. Corrections by native speakers are welcome.

The files are `translations/<language>.yaml`, the same in both channels. Each lists every option under `configuration:`, in the order of `options:` in `config.yaml`, with a `name` and a `description`; `tests/lint.py` checks that.

- **Changing a text means changing it in every file:** all five languages, in both channels. If you cannot write one of the languages, say so in the pull request rather than leaving English in its file.
- Keep the product name **BamBuddy**, paths such as `/share` and file names as they are.
- Name Home Assistant's menus as Home Assistant labels them in that language — for example "Settings -> System -> Storage" in English, "Einstellungen -> System -> Speicher" in German.
- Write the files as UTF-8; German uses real umlauts.

To add a language, copy `translations/en.yaml` to `translations/<code>.yaml` in both channels, translate the values, and add the code to `LANGUAGES` in `tests/lint.py`.

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

One last check sums up each run: green when every check passed or its channel was left out by hand, red when one failed or the run was cancelled. A pull request to `main` calls it **Validation result**, the check `main` requires: a pull request to `main` merges only when it is green. Every other run — a pull request to `dev`, a push, a run by hand — calls it **Validation summary**: GitHub counts a required check by its name on a commit, so only the run that validates the merge into `main` may answer for it. A pull request to `dev` is merged once its Validation summary is green. A run by hand never counts for a pull request anyway, so leaving a channel or the container tests out cannot stand in for the required check.

A pull request from a fork, to `dev` or to `main`, runs the same checks, with a read-only token and no secrets: Validate uses `pull_request`, never `pull_request_target`. A first-time contributor's run waits for the maintainer's approval.

## Commit messages

Please write commit messages as [Conventional Commits](https://www.conventionalcommits.org): `<type>: <description>`, optionally with a scope, as in `fix(run): …`. Nothing is generated from them here, but they keep the history readable and show at a glance what a pull request touches.

| Type | For |
|---|---|
| `feat` | something new for the people who run the app, such as a new option |
| `fix` | a bug in the app: the run script, a Dockerfile, `config.yaml` |
| `docs` | what users read: `DOCS.md`, the READMEs, the option texts in `translations/` |
| `refactor` | a restructuring that changes no behavior |
| `test` | the tests alone |
| `ci` | the workflows and their scripts |
| `chore` | everything else in the repository: this file, the issue and pull request templates, the other community files |

- Write the description in the imperative and lower case, for the people who run the app: `fix: keep the custom CA when its file name has spaces`.
- Mark a change that breaks an installation with `!` after the type, as in `feat!: rename an option` — users have to act after such an update.
- `chore: update BamBuddy … -> …` and `chore: pin BamBuddy Daily …` are the Auto-update workflow's own commits; don't write those by hand.

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
