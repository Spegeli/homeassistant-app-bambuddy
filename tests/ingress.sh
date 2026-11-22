#!/usr/bin/env bash
# ==============================================================================
# Home Assistant Ingress test for the app image.
#
# Starts the app behind a stand-in for the Supervisor's Ingress proxy
# (fake-ingress/nginx.conf: path prefix, X-Ingress-Path, source address
# 172.30.32.2) and checks:
#   - index.html, headers and redirects through Ingress
#   - only the Supervisor's address may use the Ingress port
#   - large uploads are not cut off by nginx
#   - in a real browser (Playwright): the UI renders inside a same-origin
#     iframe, every request stays below the prefix, deep links and in-app
#     navigation work, and direct access on port 8000 is unchanged.
#
# Usage: tests/ingress.sh <image>
# Needs Docker. Uses the docker network 172.30.32.0/23 (like the Supervisor).
# ==============================================================================
set -uo pipefail
cd "$(dirname "$0")" || exit 1

IMAGE="${1:?image required}"
NET=bambuddy-ingress-net
MOCK=bambuddy-ingress-mock
APP=bambuddy-ingress-app
PROXY=bambuddy-ingress-proxy
PREFIX=/api/hassio_ingress/smoketoken
# Pinned by digest; bump together with the tag.
NGINX_IMAGE=nginx:1.29-alpine@sha256:5616878291a2eed594aee8db4dade5878cf7edcb475e59193904b198d9b830de
PLAYWRIGHT_IMAGE=mcr.microsoft.com/playwright/python:v1.65.2-noble@sha256:38dd67fc654b56b3cba611e4c8eb71cd33750e1cd29eea2a5dc00b484817a75f
PLAYWRIGHT_VERSION=1.65.2
FAIL=0

host_path() { case "${OSTYPE:-}" in msys*|cygwin*) cygpath -w "$1" ;; *) printf '%s' "$1" ;; esac; }
docker() { MSYS_NO_PATHCONV=1 command docker "$@"; }
cleanup() { docker rm -f "${APP}" "${MOCK}" "${PROXY}" >/dev/null 2>&1; }
trap 'cleanup; docker network rm "${NET}" >/dev/null 2>&1' EXIT
problem() { echo "  FAIL $1"; FAIL=1; }
good() { echo "  ok   $1"; }
# curl from a container on the test network (the host cannot reach it on macOS).
net_curl() {
  local ip="$1"; shift
  docker run --rm --network "${NET}" --ip "${ip}" --entrypoint curl "${NGINX_IMAGE}" -s "$@"
}

echo "=== Ingress test: ${IMAGE}"
cleanup
docker network rm "${NET}" >/dev/null 2>&1
docker network create --subnet 172.30.32.0/23 "${NET}" >/dev/null || {
  echo "cannot create the test network 172.30.32.0/23"; exit 1; }
docker build -q -t bambuddy-smoke-mock-image mock-supervisor >/dev/null || {
  echo "cannot build the Supervisor mock"; exit 1; }

RUNDIR=$(mktemp -d "${TMPDIR:-/tmp}/bambuddy-ingress.XXXXXX")
mkdir -p "${RUNDIR}/data" "${RUNDIR}/config" "${RUNDIR}/share" "${RUNDIR}/media"
cp scenarios/defaults.json "${RUNDIR}/data/options.json"

docker run -d --name "${MOCK}" --network "${NET}" --ip 172.30.32.10 \
  -v "$(host_path "${RUNDIR}/data/options.json")":/mock/options.json:ro \
  bambuddy-smoke-mock-image >/dev/null
# bashio reads the Ingress port from the mock, so it has to answer first.
mock_ready=0
for _ in $(seq 1 60); do
  if docker exec "${MOCK}" python3 -c \
      'import urllib.request; urllib.request.urlopen("http://127.0.0.1/addons/self/info", timeout=1)' \
      >/dev/null 2>&1; then
    mock_ready=1
    break
  fi
  sleep 0.5
done
[ "${mock_ready}" = 1 ] || { echo "Supervisor mock did not come up within 30 s"; exit 1; }
docker run -d --name "${APP}" --network "${NET}" --ip 172.30.32.20 \
  -e SUPERVISOR_API=http://172.30.32.10 \
  -e SUPERVISOR_TOKEN=ingress-test \
  -e TZ=Europe/Berlin \
  -v "$(host_path "${RUNDIR}/data")":/data \
  -v "$(host_path "${RUNDIR}/config")":/config \
  -v "$(host_path "${RUNDIR}/share")":/share \
  -v "$(host_path "${RUNDIR}/media")":/media \
  "${IMAGE}" >/dev/null
docker run -d --name "${PROXY}" --network "${NET}" --ip 172.30.32.2 \
  -v "$(host_path "$(pwd)/fake-ingress/nginx.conf")":/etc/nginx/nginx.conf:ro \
  "${NGINX_IMAGE}" >/dev/null

up=0
for _ in $(seq 1 60); do
  sleep 2
  [ "$(net_curl 172.30.32.30 -o /dev/null -w '%{http_code}' "http://172.30.32.2${PREFIX}/")" = 200 ] && { up=1; break; }
done
LOG=$(docker logs "${APP}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
if [ "${up}" = 1 ]; then
  good "UI answers through Ingress"
else
  problem "UI never came up through Ingress"
  tail -30 <<<"${LOG}"
  exit 1
fi
grep -qF "Starting Ingress on port 8099" <<<"${LOG}" && good "log: Starting Ingress on port 8099" \
  || problem "log is missing: Starting Ingress on port 8099"

# index.html: every root-relative URL carries the prefix.
html=$(net_curl 172.30.32.30 "http://172.30.32.2${PREFIX}/")
grep -qE '(src|href)="/(assets|img|manifest)' <<<"${html}" \
  && problem "index.html still has root-relative URLs" || good "index.html URLs carry the prefix"
grep -qF "src=\"${PREFIX}/assets/" <<<"${html}" && good "entry script below the prefix" \
  || problem "entry script not below the prefix"

# Headers: same-origin framing allowed, the rest of the CSP intact.
headers=$(net_curl 172.30.32.30 -D - -o /dev/null "http://172.30.32.2${PREFIX}/" | tr -d '\r')
grep -qi "^content-security-policy:.*frame-ancestors 'self'" <<<"${headers}" \
  && good "CSP frame-ancestors 'self'" || problem "CSP does not allow same-origin framing"
grep -qi "^content-security-policy:.*script-src" <<<"${headers}" \
  && good "CSP script-src kept" || problem "CSP script-src lost"
grep -qi "^x-frame-options: SAMEORIGIN" <<<"${headers}" \
  && good "X-Frame-Options SAMEORIGIN" || problem "X-Frame-Options is not SAMEORIGIN"

# Only the Supervisor (172.30.32.2) may use the Ingress port.
code=$(net_curl 172.30.32.30 -o /dev/null -w '%{http_code}' "http://172.30.32.20:8099/")
[ "${code}" = 403 ] && good "Ingress port refuses other addresses (403)" \
  || problem "Ingress port answered ${code} to another address"

# Uploads larger than the Supervisor's 16 MB buffer pass nginx (413 = cut off).
head -c 20000000 /dev/zero > "${RUNDIR}/upload.bin"
code=$(docker run --rm --network "${NET}" --ip 172.30.32.30 \
  -v "$(host_path "${RUNDIR}/upload.bin")":/upload.bin:ro --entrypoint curl "${NGINX_IMAGE}" \
  -s -o /dev/null -w '%{http_code}' -X POST -F "file=@/upload.bin" \
  "http://172.30.32.2${PREFIX}/api/v1/library/files")
[ "${code}" != 413 ] && [ "${code}" != 000 ] && good "20 MB upload passes nginx (HTTP ${code})" \
  || problem "20 MB upload was cut off (HTTP ${code})"

# The browser test.
echo ""
docker run --rm --network "${NET}" --ip 172.30.32.30 --ipc=host \
  -v "$(host_path "$(pwd)/ingress_browser.py")":/test/ingress_browser.py:ro \
  "${PLAYWRIGHT_IMAGE}" sh -c \
  "pip install --quiet --disable-pip-version-check playwright==${PLAYWRIGHT_VERSION} >/dev/null 2>&1 && python3 /test/ingress_browser.py http://172.30.32.2 http://172.30.32.20:8000" \
  || FAIL=1

LOG=$(docker logs "${APP}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
grep -qiE 'traceback|\[emerg\]|\[crit\]' <<<"${LOG}" \
  && { problem "errors in the log"; grep -iE 'traceback|\[emerg\]|\[crit\]' <<<"${LOG}" | head -5; } \
  || good "no errors in the log"

echo ""
if [ "${FAIL}" = 0 ]; then
  echo "Ingress test passed"
else
  echo "Ingress test FAILED"
  echo "--- app log (tail)"
  tail -30 <<<"${LOG}"
fi
exit "${FAIL}"
