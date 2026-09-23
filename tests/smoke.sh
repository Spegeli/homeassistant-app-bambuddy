#!/usr/bin/env bash
# Boots the image once per scenario against a mock Supervisor and asserts what
# the run script did with the options, then checks the shutdown and crash paths.
#
# Usage: tests/smoke.sh <image> [scenario ...]
#   tests/smoke.sh bambuddy:test
#   tests/smoke.sh bambuddy:test all-on
#
# Without the mock, bashio::config cannot reach the Supervisor API, every option
# block is skipped and the test would pass while proving nothing - so a missing
# mock is a hard error here.
set -uo pipefail
cd "$(dirname "$0")" || exit 1

IMAGE="${1:?image required}"
shift
SCENARIOS=("$@")
if [ "${#SCENARIOS[@]}" -eq 0 ]; then
  SCENARIOS=(defaults all-on media-only cert-missing empty-origins)
fi

NET=bambuddy-smoke-net
MOCK=bambuddy-smoke-mock
APP=bambuddy-smoke-app
PORT=18999
FAIL=0

# Git Bash mangles container paths and needs Windows-style volume sources.
host_path() { case "${OSTYPE:-}" in msys*|cygwin*) cygpath -w "$1" ;; *) printf '%s' "$1" ;; esac; }
docker() { MSYS_NO_PATHCONV=1 command docker "$@"; }

cleanup() { docker rm -f "${APP}" "${MOCK}" >/dev/null 2>&1; }
trap 'cleanup; docker network rm "${NET}" >/dev/null 2>&1' EXIT

problem() { echo "  FAIL $1"; FAIL=1; }
good() { echo "  ok   $1"; }

docker build -q -t bambuddy-smoke-mock-image mock-supervisor >/dev/null || {
  echo "cannot build the Supervisor mock"; exit 1; }
docker network inspect "${NET}" >/dev/null 2>&1 || docker network create "${NET}" >/dev/null

# Value of one environment variable inside the running uvicorn process. Reading
# /proc beats `docker exec env`, which would show the container defaults rather
# than what the run script exported.
app_env() {
  docker exec "${APP}" python3 -c '
import os, sys
for pid in os.listdir("/proc"):
    if not pid.isdigit():
        continue
    try:
        argv = open("/proc/%s/cmdline" % pid, "rb").read().decode().split("\0")
        if not any(a.endswith("/uvicorn") for a in argv):
            continue
        env = dict(
            line.split("=", 1)
            for line in open("/proc/%s/environ" % pid, "rb").read().decode().split("\0")
            if "=" in line
        )
        print(env.get(sys.argv[1], ""))
        break
    except OSError:
        continue
' "$1" 2>/dev/null
}

uvicorn_count() {
  docker exec "${APP}" python3 -c '
import os
n = 0
for pid in os.listdir("/proc"):
    if not pid.isdigit():
        continue
    try:
        argv = open("/proc/%s/cmdline" % pid, "rb").read().decode().split("\0")
    except OSError:
        continue
    if any(a.endswith("/uvicorn") for a in argv):
        n += 1
print(n)
' 2>/dev/null
}

expect_env() {
  local key="$1" want="$2" got
  got=$(app_env "${key}")
  if [ "${got}" = "${want}" ]; then
    good "${key}=${want:-<unset>}"
  else
    problem "${key}: expected '${want:-<unset>}', got '${got:-<unset>}'"
  fi
}

expect_log() {
  grep -qF "$1" <<<"${LOG}" && good "log: $1" || problem "log is missing: $1"
}

for scenario in "${SCENARIOS[@]}"; do
  file="scenarios/${scenario}.json"
  [ -f "${file}" ] || { problem "unknown scenario ${scenario}"; continue; }

  echo ""
  echo "--- scenario: ${scenario}"
  cleanup

  RUNDIR=$(mktemp -d "${TMPDIR:-/tmp}/bambuddy-smoke.XXXXXX")
  mkdir -p "${RUNDIR}/data" "${RUNDIR}/config" "${RUNDIR}/share" "${RUNDIR}/media"
  cp "${file}" "${RUNDIR}/data/options.json"
  # all-on points certfile at this file; cert-missing deliberately does not.
  # Generated inside the image rather than on the host: Git Bash rewrites both
  # "/CN=..." and "/dev/null" into Windows paths and openssl then fails.
  docker run --rm --entrypoint sh \
    -v "$(host_path "${RUNDIR}/config")":/out "${IMAGE}" -c \
    'openssl req -x509 -newkey rsa:2048 -nodes -keyout /dev/null -out /out/custom_ca.crt -days 1 -subj "/CN=bambuddy-smoke"' \
    >/dev/null 2>&1
  [ -s "${RUNDIR}/config/custom_ca.crt" ] || problem "could not generate the test CA"

  docker run -d --name "${MOCK}" --network "${NET}" \
    -v "$(host_path "${RUNDIR}/data/options.json")":/mock/options.json:ro \
    bambuddy-smoke-mock-image >/dev/null

  docker run -d --name "${APP}" --network "${NET}" -p "${PORT}:8000" \
    -e SUPERVISOR_API=http://${MOCK} \
    -e SUPERVISOR_TOKEN=smoke-test \
    -e TZ=Europe/Berlin \
    -v "$(host_path "${RUNDIR}/data")":/data \
    -v "$(host_path "${RUNDIR}/config")":/config \
    -v "$(host_path "${RUNDIR}/share")":/share \
    -v "$(host_path "${RUNDIR}/media")":/media \
    "${IMAGE}" >/dev/null

  up=0
  for _ in $(seq 1 40); do
    sleep 2
    curl -sf -o /dev/null "http://127.0.0.1:${PORT}/" && { up=1; break; }
  done

  LOG=$(docker logs "${APP}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g')

  if [ "${up}" = 1 ]; then
    good "web UI answers on port 8000"
  else
    problem "web UI never came up"
    tail -25 <<<"${LOG}"
    cleanup
    continue
  fi

  health=$(curl -sf "http://127.0.0.1:${PORT}/health")
  grep -q '"healthy"' <<<"${health}" && good "/health: ${health}" \
    || problem "/health did not report healthy: ${health}"

  count=$(uvicorn_count)
  [ "${count}" = "1" ] && good "exactly one uvicorn process" \
    || problem "expected 1 uvicorn process, found ${count} (inherited CMD?)"

  grep -qiE 'traceback|unbound variable|Something went wrong contacting the API' <<<"${LOG}" \
    && { problem "errors in the log"; grep -iE 'traceback|unbound variable|Something went wrong' <<<"${LOG}" | head -3; } \
    || good "no errors in the log"

  links=$(docker exec "${APP}" sh -c 'readlink /app/data; readlink /app/logs')
  [ "${links}" = "$(printf '/config/data\n/config/logs')" ] \
    && good "/app/data and /app/logs link into /config" \
    || problem "unexpected symlinks: ${links}"

  expect_env DATA_DIR /config/data
  expect_env LOG_DIR /config/logs
  expect_env TZ Europe/Berlin

  case "${scenario}" in
    defaults)
      expect_env TRUSTED_FRAME_ORIGINS "http://homeassistant.local:8123"
      expect_env BAMBUDDY_EXTERNAL_ROOTS ""
      expect_env USE_SYSTEM_TRUST_STORE ""
      expect_env DEBUG ""
      ;;
    all-on)
      expect_env TRUSTED_FRAME_ORIGINS "http://ha.test:8123,https://example.com"
      expect_env BAMBUDDY_EXTERNAL_ROOTS "/share:/media"
      expect_env USE_SYSTEM_TRUST_STORE "true"
      expect_env DEBUG "true"
      expect_log "Setting USE_SYSTEM_TRUST_STORE: true (CA: custom_ca.crt)"
      docker exec "${APP}" sh -c '[ -f /usr/local/share/ca-certificates/custom_ca.crt ]' \
        && good "CA copied into the trust store" || problem "CA was not installed"
      docker exec "${APP}" sh -c \
        'openssl crl2pkcs7 -nocrl -certfile /etc/ssl/certs/ca-certificates.crt | openssl pkcs7 -print_certs -noout 2>/dev/null | grep -q bambuddy-smoke' \
        && good "CA present in the system bundle" || problem "CA missing from the system bundle"
      grep -q "^\[.*\] INFO.*[0-9] added" <<<"${LOG}" \
        && problem "update-ca-certificates output leaked into the log" \
        || good "update-ca-certificates stays quiet"
      ;;
    media-only)
      # Regression guard for the ${VAR:+${VAR}:} append - a bug here yields ":/media".
      expect_env BAMBUDDY_EXTERNAL_ROOTS "/media"
      expect_env TRUSTED_FRAME_ORIGINS ""
      ;;
    cert-missing)
      expect_env USE_SYSTEM_TRUST_STORE ""
      expect_log "use_system_trust_store is enabled but certificate file not found: /config/does-not-exist.crt"
      expect_log "Place your CA certificate (.crt) in the addon_configs folder"
      ;;
    empty-origins)
      expect_env TRUSTED_FRAME_ORIGINS ""
      ;;
  esac

  # Shutdown path: s6 reports 256 for "terminated by a signal", so finish must
  # log the plain exit line and must not halt the container.
  if [ "${scenario}" = "defaults" ]; then
    docker stop -t 30 "${APP}" >/dev/null
    STOPLOG=$(docker logs "${APP}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
    grep -q "Application shutdown complete" <<<"${STOPLOG}" \
      && good "uvicorn shut down gracefully" || problem "no graceful uvicorn shutdown"
    grep -q "BamBuddy exited (code 256)" <<<"${STOPLOG}" \
      && good "finish logged the signal exit" || problem "finish did not log 'BamBuddy exited (code 256)'"
    grep -q "crashed" <<<"${STOPLOG}" \
      && problem "a normal stop was reported as a crash" || good "a normal stop is not a crash"
  fi

  cleanup
  rm -rf "${RUNDIR}" 2>/dev/null
done

# Crash path: a service exit other than 0/256 must halt the container and carry
# the exit code out, so Home Assistant shows the app as stopped.
echo ""
echo "--- lifecycle: crash path"
cleanup
CRASHDIR=$(mktemp -d "${TMPDIR:-/tmp}/bambuddy-crash.XXXXXX")
printf '#!/usr/bin/with-contenv bashio\nbashio::log.info "fake service, exiting 3"\nexit 3\n' \
  > "${CRASHDIR}/run"
chmod 755 "${CRASHDIR}/run"
docker run -d --name "${APP}" \
  -e SUPERVISOR_TOKEN=smoke-test \
  -v "$(host_path "${CRASHDIR}/run")":/etc/services.d/bambuddy/run:ro \
  "${IMAGE}" >/dev/null
for _ in $(seq 1 20); do
  state=$(docker inspect -f '{{.State.Status}}' "${APP}")
  [ "${state}" = "exited" ] && break
  sleep 1
done
code=$(docker inspect -f '{{.State.ExitCode}}' "${APP}")
CRASHLOG=$(docker logs "${APP}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
[ "${code}" = "3" ] && good "container exited with the service's code 3" \
  || problem "container exit code is '${code}', expected 3"
grep -q "BamBuddy crashed (exit code 3), halting app" <<<"${CRASHLOG}" \
  && good "finish logged the crash" || problem "finish did not log the crash"
cleanup
rm -rf "${CRASHDIR}" 2>/dev/null

echo ""
if [ "${FAIL}" = 0 ]; then
  echo "SMOKE PASSED"
else
  echo "SMOKE FAILED"
fi
exit "${FAIL}"
