#!/usr/bin/env python3
"""Static checks for one channel directory (no Docker, runs in seconds).

Each channel is checked against itself only. Stable and Daily may legitimately
differ while Daily carries an upstream feature Stable has not shipped yet, so a
difference between the two is reported but never fails the run.

Usage: tests/lint.py [bambuddy bambuddy-daily]
"""

import pathlib
import re
import sys

import yaml

LANGUAGES = ("en", "de", "fr", "es", "it")
EXPECTED_ARCH = ["aarch64", "amd64"]
REQUIRED_KEYS = (
    "name", "version", "slug", "description", "url", "image", "arch", "init",
    "timeout", "host_network", "map", "options", "schema", "webui", "watchdog",
)

FAILURES = []


def fail(channel, message):
    FAILURES.append("{}: {}".format(channel, message))
    print("  FAIL {}".format(message))


def ok(message):
    print("  ok   {}".format(message))


def check_config(channel):
    name = channel.name
    path = channel / "config.yaml"
    raw = path.read_text(encoding="utf-8")
    config = yaml.safe_load(raw)

    # Raw bytes: read_text() would already have turned CRLF into LF.
    if b"\r" in path.read_bytes():
        fail(name, "config.yaml has CRLF line endings")

    for key in REQUIRED_KEYS:
        if key not in config:
            fail(name, "config.yaml is missing '{}'".format(key))

    version = config.get("version")
    if not isinstance(version, str) or not version.strip():
        fail(name, "version must be a non-empty string (quote it in YAML)")
    else:
        ok("version {}".format(version))

    # The auto-update reads and rewrites this line as text (grep/sed), so it
    # must be exactly one plain quoted value. A trailing comment or other
    # quoting would make every hourly run see a "new" version.
    version_lines = re.findall(r"^version:.*$", raw, re.M)
    if len(version_lines) != 1 or not re.fullmatch(
            r'version: "[0-9A-Za-z][0-9A-Za-z._-]*"', version_lines[0]):
        fail(name, 'config.yaml needs exactly one line version: "<version>" (no comment, double quotes)')

    expected_slug = name.replace("-", "_")
    if config.get("slug") != expected_slug:
        fail(name, "slug is '{}', expected '{}'".format(config.get("slug"), expected_slug))

    expected_image = "ghcr.io/spegeli/homeassistant-app-{}".format(name)
    if config.get("image") != expected_image:
        fail(name, "image is '{}', expected '{}'".format(config.get("image"), expected_image))

    if config.get("arch") != EXPECTED_ARCH:
        fail(name, "arch is {}, expected {}".format(config.get("arch"), EXPECTED_ARCH))

    if config.get("init") is not False:
        fail(name, "init must be false (s6-overlay v3)")

    if str(config.get("name", "")).startswith("Bambuddy"):
        fail(name, "display name must spell the product 'BamBuddy'")

    options = list(config.get("options") or {})
    schema = list(config.get("schema") or {})
    if options != schema:
        fail(name, "options order {} != schema order {}".format(options, schema))
    else:
        ok("options == schema ({} keys)".format(len(options)))

    return config


def check_translations(channel, config):
    name = channel.name
    keys = list(config.get("options") or {})
    clean = True
    for language in LANGUAGES:
        path = channel / "translations" / "{}.yaml".format(language)
        if not path.is_file():
            fail(name, "translations/{}.yaml is missing".format(language))
            clean = False
            continue
        data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
        entries = data.get("configuration")
        if not isinstance(entries, dict):
            fail(name, "translations/{}.yaml has no 'configuration:' block".format(language))
            clean = False
            continue
        if list(entries) != keys:
            fail(name, "translations/{}.yaml order {} != options {}".format(
                language, list(entries), keys))
            clean = False
            continue
        for key, value in entries.items():
            value = value or {}
            if not value.get("name") or not value.get("description"):
                fail(name, "translations/{}.yaml: '{}' needs name and description".format(
                    language, key))
                clean = False
    if clean:
        ok("translations {} match options".format("/".join(LANGUAGES)))


def check_scripts(channel):
    name = channel.name
    run = channel / "rootfs/etc/services.d/bambuddy/run"
    finish = channel / "rootfs/etc/services.d/bambuddy/finish"

    for path, shebang in ((run, "#!/usr/bin/with-contenv bashio"),
                          (finish, "#!/usr/bin/env bashio")):
        if not path.is_file():
            fail(name, "{} is missing".format(path.name))
            continue
        # Raw bytes: read_text() would already have turned CRLF into LF.
        if b"\r" in path.read_bytes():
            fail(name, "{} has CRLF line endings".format(path.name))
        if not path.read_text(encoding="utf-8").startswith(shebang):
            fail(name, "{} must start with '{}'".format(path.name, shebang))

    if not run.is_file():
        return

    text = run.read_text(encoding="utf-8")
    lines = [line for line in text.strip().split("\n") if line.strip()]
    last = lines[-1]
    if not last.startswith("exec uvicorn "):
        fail(name, "run must end with 'exec uvicorn ...' (graceful shutdown)")
    elif "--host 0.0.0.0" not in last or "--port 8000" not in last:
        fail(name, "run must start uvicorn on 0.0.0.0:8000")
    else:
        ok("run ends with exec uvicorn on 0.0.0.0:8000")

    # The data must live in the addon_config mount (/config), which survives an
    # uninstall. Check the exact lines - a log message also mentions the paths.
    for line in ("ln -s /config/data /app/data", "ln -s /config/logs /app/logs",
                 "export DATA_DIR=/config/data", "export LOG_DIR=/config/logs"):
        if not re.search(r"^{}$".format(re.escape(line)), text, re.M):
            fail(name, "run is missing the line '{}'".format(line))


def check_dockerfile(channel):
    name = channel.name
    text = (channel / "Dockerfile").read_text(encoding="utf-8")

    # Anchored to whole lines, so a commented-out instruction does not count.
    if not re.search(r'^ENTRYPOINT \["/init"\]$', text, re.M):
        fail(name, 'Dockerfile must set ENTRYPOINT ["/init"]')
    if not re.search(r"^CMD \[\]$", text, re.M):
        fail(name, "Dockerfile must blank the inherited CMD (else a second uvicorn starts)")
    for label in ('io.hass.version="${BAMBUDDY_VERSION}"', 'io.hass.type="app"',
                  'io.hass.arch="${BUILD_ARCH}"'):
        if not re.search(r"^LABEL {}$".format(re.escape(label)), text, re.M):
            fail(name, "Dockerfile must set LABEL {}".format(label))

    # Every file under rootfs/ must be covered by a COPY instruction, otherwise
    # the deliberately narrow "COPY --chmod=755 rootfs/etc/..." drops it silently.
    sources = []
    for match in re.finditer(r"^COPY(?: --\S+)* (.+?) (\S+)\s*$", text, re.M):
        sources.extend(match.group(1).split())
    rootfs = channel / "rootfs"
    files = [p for p in rootfs.rglob("*") if p.is_file()]
    uncovered = []
    for path in files:
        relative = path.relative_to(channel).as_posix()
        # Whole path components: "rootfs/etc/services.d/bambuddy" does not
        # cover a sibling folder like "rootfs/etc/services.d/bambuddy-extra".
        if not any(relative == source.rstrip("/") or relative.startswith(source.rstrip("/") + "/")
                   for source in sources):
            uncovered.append(relative)
    if uncovered:
        fail(name, "Dockerfile COPY does not cover: {}".format(", ".join(uncovered)))
    else:
        ok("Dockerfile COPY covers all {} rootfs files".format(len(files)))


def check_upstream_digest(channel):
    """Daily pins its upstream base by digest (no versioned daily tags upstream)."""
    name = channel.name
    if "ARG BAMBUDDY_DIGEST" not in (channel / "Dockerfile").read_text(encoding="utf-8"):
        return
    path = channel / "upstream.digest"
    if not path.is_file():
        # Not a failure: the next Auto-update run builds, tests and pins it.
        # Manual builds of this channel fail loudly until then.
        print("  note upstream.digest missing - the next Auto-update run pins it")
        return
    digest = path.read_text(encoding="utf-8").strip()
    if not re.fullmatch(r"sha256:[0-9a-f]{64}", digest):
        fail(name, "upstream.digest must be 'sha256:' + 64 hex characters, got '{}'".format(digest))
    else:
        ok("upstream.digest {}...".format(digest[:19]))


def report_channel_drift(channels):
    """Informational only - Daily is allowed to run ahead of Stable."""
    if len(channels) < 2:
        return
    first, second = channels[0], channels[1]
    print("\nChannel drift {} vs {} (informational, never fails):".format(
        first.name, second.name))
    drifted = []
    for relative in ("rootfs/etc/services.d/bambuddy/run",
                     "rootfs/etc/services.d/bambuddy/finish",
                     "translations/en.yaml",
                     "DOCS.md"):
        a, b = first / relative, second / relative
        if a.is_file() and b.is_file() and a.read_bytes() != b.read_bytes():
            drifted.append(relative)
    print("  " + ("identical" if not drifted else "differs: " + ", ".join(drifted)))


def main():
    channels = [pathlib.Path(arg) for arg in (sys.argv[1:] or ["bambuddy", "bambuddy-daily"])]
    for channel in channels:
        print("\n=== {}".format(channel.name))
        if not channel.is_dir():
            fail(channel.name, "channel directory not found")
            continue
        config = check_config(channel)
        check_translations(channel, config)
        check_scripts(channel)
        check_dockerfile(channel)
        check_upstream_digest(channel)

    report_channel_drift(channels)

    print()
    if FAILURES:
        print("LINT FAILED ({} problems)".format(len(FAILURES)))
        for failure in FAILURES:
            print("  - {}".format(failure))
        return 1
    print("LINT PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
