#!/usr/bin/env bash
# Assertions against a built image, without starting the service.
#
# Usage: tests/image-checks.sh <channel-dir> <image> [expected-version]
#   tests/image-checks.sh bambuddy bambuddy:test
#
# The expected version defaults to config.yaml. The auto-update flow passes it
# explicitly, because there the image is built from the new upstream version
# while config.yaml still carries the old one - the bump is only committed
# after these tests pass.
#
# Catches the failures this repo actually had: a cached build that shipped an
# older BamBuddy under a new tag, cv2 missing so plate detection was silently
# off, and the inherited upstream CMD that started a second uvicorn.
set -uo pipefail

CHANNEL="${1:?channel directory required}"
IMAGE="${2:?image required}"
EXPECTED_VERSION="${3:-}"
FAIL=0

check() {
  local label="$1" expected="$2" actual="$3"
  if [ "${expected}" = "${actual}" ]; then
    echo "  ok   ${label}: ${actual}"
  else
    echo "  FAIL ${label}: expected '${expected}', got '${actual}'"
    FAIL=1
  fi
}

echo "=== image checks: ${IMAGE} (${CHANNEL})"

VERSION="${EXPECTED_VERSION}"
if [ -z "${VERSION}" ]; then
  VERSION=$(grep -E '^version:' "${CHANNEL}/config.yaml" | sed -E 's/version:[[:space:]]*"?([^"]+)"?/\1/')
fi

label() { docker inspect "${IMAGE}" --format "{{index .Config.Labels \"$1\"}}"; }

check "io.hass.version" "${VERSION}" "$(label io.hass.version)"
check "io.hass.type" "app" "$(label io.hass.type)"

ARCH=$(label io.hass.arch)
case "${ARCH}" in
  amd64|aarch64) echo "  ok   io.hass.arch: ${ARCH}" ;;
  *) echo "  FAIL io.hass.arch: expected amd64 or aarch64, got '${ARCH}'"; FAIL=1 ;;
esac

check "entrypoint" '[/init]' "$(docker inspect "${IMAGE}" --format '{{.Config.Entrypoint}}')"
check "cmd is blank" '[]' "$(docker inspect "${IMAGE}" --format '{{.Config.Cmd}}')"

for pair in "DATA_DIR=/config/data" "LOG_DIR=/config/logs" "PYTHONUNBUFFERED=1"; do
  if docker inspect "${IMAGE}" --format '{{range .Config.Env}}{{println .}}{{end}}' | grep -qx "${pair}"; then
    echo "  ok   env ${pair}"
  else
    echo "  FAIL env ${pair} missing"
    FAIL=1
  fi
done

# Everything below needs a throwaway container but no running service.
OUT=$(docker run --rm --entrypoint sh "${IMAGE}" -c '
  stat -c "%a %n" /etc/services.d/bambuddy/run /etc/services.d/bambuddy/finish
  readlink /usr/bin/with-contenv
  command -v bashio >/dev/null && echo "bashio ok"
  jq --version >/dev/null && echo "jq ok"
  ip -j addr >/dev/null 2>&1 && echo "ip-json ok"
  python -c "import cv2; print(\"cv2 \" + cv2.__version__)"
' 2>&1)

echo "${OUT}" | sed 's/^/       /'

expect_line() {
  if grep -q "$1" <<<"${OUT}"; then
    echo "  ok   $2"
  else
    echo "  FAIL $2"
    FAIL=1
  fi
}

expect_line "^755 /etc/services.d/bambuddy/run$" "run is 0755"
expect_line "^755 /etc/services.d/bambuddy/finish$" "finish is 0755"
expect_line "^/command/with-contenv$" "with-contenv symlink"
expect_line "^bashio ok$" "bashio installed"
expect_line "^jq ok$" "jq installed"
expect_line "^ip-json ok$" "iproute2 ip -j works"
expect_line "^cv2 " "OpenCV imports (plate detection)"

if [ "${FAIL}" = 0 ]; then
  echo "IMAGE CHECKS PASSED"
else
  echo "IMAGE CHECKS FAILED"
fi
exit "${FAIL}"
