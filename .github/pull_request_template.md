<!-- Thanks for contributing! Please read CONTRIBUTING.md first. -->

## Description

<!-- What does this pull request change, and why? -->

## Related issue

<!-- e.g. Fixes #7 – or "none". Bugs in BamBuddy itself belong upstream: https://github.com/maziggy/bambuddy/issues -->

## Channels

- [ ] Stable (`bambuddy/`)
- [ ] Daily (`bambuddy-daily/`)

<!-- By default a change goes into both. Daily only? Name the upstream feature it depends on. -->

## Type of change

- [ ] Bug fix
- [ ] New feature
- [ ] Documentation
- [ ] Refactor / code quality
- [ ] CI / repository

## How was this tested?

<!--
Which channel and architecture? Locally (see tests/README.md) or on a real Home Assistant instance?
A log excerpt from the app's startup is ideal.
-->

## Checklist

- [ ] `tests/lint.py` passes; for changes to the Dockerfile or `rootfs/` also `tests/image-checks.sh` and `tests/smoke.sh`
- [ ] Tested on a real Home Assistant instance, if the change affects the running app
- [ ] New or changed option: `options` + `schema` in `config.yaml`, all `translations/*.yaml` (`en`, `de`, `fr`, `es`, `it`), the options section in `DOCS.md`, a scenario in `tests/scenarios/` with assertions in `tests/smoke.sh` – in both channels, in the order of `config.yaml`
- [ ] No token or other secret ends up in the log (the run script logs `Setting <VAR>: <value>`)
- [ ] `DOCS.md` updated if user-facing behavior changed

<!--
Do NOT change `version:` in config.yaml or CHANGELOG.md – the Auto-update workflow maintains both.
Every pull request runs the Validate workflow; it can only be merged once "Validation result" is green.
-->
