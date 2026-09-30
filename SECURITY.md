# Security policy

## Reporting a vulnerability

Please report a vulnerability privately, never in a public issue or pull request:

1. Open [Report a vulnerability](https://github.com/Spegeli/homeassistant-app-bambuddy/security/advisories/new) — or the **Security** tab → **Report a vulnerability**.
2. Describe the problem, how to reproduce it and what an attacker could do with it. Name the channel (Stable or Daily), the app version and the Home Assistant version.

Never put a real secret into a report, such as a Home Assistant token or a printer's access code.

Only you and the maintainer see the report. This is a personal project, maintained in spare time: you get an answer as soon as possible, but there is no fixed response time. The advisory is published once the fix is available, and you are credited unless you ask not to be.

Not sure whether it is a vulnerability, or whether it lies in this app or in BamBuddy? Report it here privately anyway.

## Scope

In scope is what this repository adds to BamBuddy, in particular:

- the permissions the app asks Home Assistant for in `config.yaml`, such as host networking and access to the `/share` and `/media` folders
- the image built here: the Dockerfile and the s6 scripts, including how the run script passes the Supervisor token to BamBuddy and installs a custom CA certificate
- the workflows that test, build and publish the images and update them automatically

Vulnerabilities in BamBuddy itself are out of scope: report them as [BamBuddy's security policy](https://github.com/maziggy/bambuddy/blob/main/SECURITY.md) describes. The same goes for [Home Assistant](https://www.home-assistant.io/security/) and for Bambu Lab's printers, apps and cloud.

## Supported versions

Only the latest version of each channel receives security fixes. Update the app in Home Assistant as soon as it offers an update.

| Channel | Security fixes |
|---|---|
| Stable, latest version | ✅ |
| Daily, latest version | ✅ |
| Older versions of either channel | ❌ |
