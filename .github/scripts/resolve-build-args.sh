#!/usr/bin/env bash
# Resolves what to build for one channel and writes it to $GITHUB_OUTPUT.
# Shared by _build.yml and _test.yml so both always build the same thing.
#
# Usage: resolve-build-args.sh <context> [version] [digest]
#   context  channel directory (bambuddy, bambuddy-daily)
#   version  explicit version; default: version: from <context>/config.yaml
#   digest   explicit upstream digest; default: <context>/upstream.digest
#
# Outputs:
#   version      the BamBuddy version (config.yaml is the single source)
#   digest_arg   "BAMBUDDY_DIGEST=sha256:..." for channels whose Dockerfile pins
#                its upstream base by digest (daily), empty otherwise
#   description  one-line text for the GHCR package page (text only, max 512
#                characters). GHCR reads it from the manifest annotations, not
#                from the Dockerfile label, for multi-arch images.
#
# Daily needs the digest because upstream publishes no versioned daily tags,
# only the rolling :daily. Without it a manual daily build would pull whatever
# :daily is right now and label it with the older version from config.yaml.
set -euo pipefail

CONTEXT="${1:?context required}"
VERSION="${2:-}"
DIGEST="${3:-}"
OUT="${GITHUB_OUTPUT:-/dev/stdout}"

if [ -z "${VERSION}" ]; then
  VERSION=$(grep -E '^version:' "${CONTEXT}/config.yaml" | sed -E 's/version:[[:space:]]*"?([^"]+)"?/\1/')
fi
if [ -z "${VERSION}" ]; then
  echo "::error::no version found in ${CONTEXT}/config.yaml"
  exit 1
fi
echo "version=${VERSION}" >> "${OUT}"
echo "Version: ${VERSION}"

if grep -q '^ARG BAMBUDDY_DIGEST' "${CONTEXT}/Dockerfile"; then
  if [ -z "${DIGEST}" ] && [ -f "${CONTEXT}/upstream.digest" ]; then
    DIGEST=$(tr -d '[:space:]' < "${CONTEXT}/upstream.digest")
  fi
  if ! grep -Eq '^sha256:[0-9a-f]{64}$' <<<"${DIGEST}"; then
    echo "::error::${CONTEXT} pins its upstream base by digest, but no valid digest is recorded in ${CONTEXT}/upstream.digest (got '${DIGEST}'). Run the 'Auto-update' workflow once to pin it."
    exit 1
  fi
  echo "digest_arg=BAMBUDDY_DIGEST=${DIGEST}" >> "${OUT}"
  echo "Upstream digest: ${DIGEST}"
else
  DIGEST=""
  echo "digest_arg=" >> "${OUT}"
fi

# Release notes live upstream; the full changelog does not fit (512 chars,
# no markdown), so the description links to it instead.
NOTES="https://github.com/maziggy/bambuddy/releases/tag/v${VERSION}"
if [ -n "${DIGEST}" ]; then
  DESCRIPTION="BamBuddy ${VERSION} (Daily) for Home Assistant built from upstream daily ${DIGEST:0:19}. Release notes: ${NOTES}"
else
  DESCRIPTION="BamBuddy ${VERSION} (Stable) for Home Assistant. A powerful self-hosted command center for Bambu Lab printers. Release notes: ${NOTES}"
fi
# The per-architecture suffix (" — arm64 image") is added later; keep room.
DESCRIPTION="${DESCRIPTION:0:490}"
echo "description=${DESCRIPTION}" >> "${OUT}"
echo "Description: ${DESCRIPTION}"
