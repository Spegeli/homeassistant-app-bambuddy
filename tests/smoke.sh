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
  SCENARIOS=(defaults all-on media-only cert-missing empty-origins cert-subdir-pem cert-invalid)
fi

NET=bambuddy-smoke-net
MOCK=bambuddy-smoke-mock
APP=bambuddy-smoke-app
PORT=18999
FAIL=0
PROBLEMS=0

# Git Bash mangles container paths and needs Windows-style volume sources.
host_path() { case "${OSTYPE:-}" in msys*|cygwin*) cygpath -w "$1" ;; *) printf '%s' "$1" ;; esac; }
docker() { MSYS_NO_PATHCONV=1 command docker "$@"; }

cleanup() { docker rm -f "${APP}" "${MOCK}" >/dev/null 2>&1; }
trap 'cleanup; docker network rm "${NET}" >/dev/null 2>&1' EXIT

problem() { echo "  FAIL $1"; FAIL=1; PROBLEMS=$((PROBLEMS + 1)); }
good() { echo "  ok   $1"; }

docker build -q -t bambuddy-smoke-mock-image mock-supervisor >/dev/null || {
  echo "cannot build the Supervisor mock"; exit 1; }
docker network inspect "${NET}" >/dev/null 2>&1 || docker network create "${NET}" >/dev/null

# Value of one environment variable inside the running uvicorn process. Reading
# /proc beats `docker exec env`, which would show the container defaults rather
# than what the run script exported. Prints "=<value>" when the variable is set,
# "!" when it is not and "?" without a uvicorn process. No output at all means
# docker exec itself failed - that happens now and then under Git Bash on
# Windows - so it is retried instead of being read as "not set".
app_env() {
  local out attempt
  for attempt in 1 2 3; do
    out=$(docker exec "${APP}" python3 -c '
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
        print("=" + env[sys.argv[1]] if sys.argv[1] in env else "!")
        break
    except OSError:
        continue
else:
    print("?")
' "$1" 2>/dev/null)
    [ -n "${out}" ] && break
    sleep 1
  done
  printf '%s' "${out}"
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
  case "${got}" in
    "="*) got="${got#=}" ;;
    "!") got="" ;;
    "?") problem "${key}: no uvicorn process to read it from"; return ;;
    *) problem "${key}: could not read the uvicorn environment"; return ;;
  esac
  if [ "${got}" = "${want}" ]; then
    good "${key}=${want:-<unset>}"
  else
    problem "${key}: expected '${want:-<unset>}', got '${got:-<unset>}'"
  fi
}

expect_log() {
  grep -qF "$1" <<<"${LOG}" && good "log: $1" || problem "log is missing: $1"
}

# HTTPS round-trip the way BamBuddy's httpx clients make it: with the uvicorn
# process's own environment, against a throwaway server inside the container
# that presents a certificate signed by the generated test CA.
expect_trusted_tls() {
  local result
  result=$(docker exec "${APP}" python3 -c '
import functools, http.server, os, ssl, threading
env = None
for pid in os.listdir("/proc"):
    if not pid.isdigit():
        continue
    try:
        argv = open("/proc/%s/cmdline" % pid, "rb").read().decode().split("\0")
        if any(a.endswith("/uvicorn") for a in argv):
            env = dict(line.split("=", 1)
                       for line in open("/proc/%s/environ" % pid, "rb").read().decode().split("\0")
                       if "=" in line)
            break
    except OSError:
        continue
if env is None:
    raise SystemExit("no uvicorn process")
os.environ.clear()
os.environ.update(env)
import httpx
handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory="/tmp")
server = http.server.HTTPServer(("127.0.0.1", 8443), handler)
context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.load_cert_chain("/config/tls/server.crt", "/config/tls/server.key")
server.socket = context.wrap_socket(server.socket, server_side=True)
threading.Thread(target=server.serve_forever, daemon=True).start()
try:
    print("status", httpx.get("https://localhost:8443/", timeout=5).status_code)
except Exception as error:
    print("error", type(error).__name__, str(error)[:120])
' 2>/dev/null)
  [ "${result}" = "status 200" ] && good "httpx trusts the custom CA (HTTPS round-trip)" \
    || problem "httpx does not trust the custom CA: ${result:-no output}"
}

for scenario in "${SCENARIOS[@]}"; do
  file="scenarios/${scenario}.json"
  [ -f "${file}" ] || { problem "unknown scenario ${scenario}"; continue; }

  echo ""
  echo "--- scenario: ${scenario}"
  cleanup
  problems_before=${PROBLEMS}

  RUNDIR=$(mktemp -d "${TMPDIR:-/tmp}/bambuddy-smoke.XXXXXX")
  mkdir -p "${RUNDIR}/data" "${RUNDIR}/config" "${RUNDIR}/share" "${RUNDIR}/media"
  cp "${file}" "${RUNDIR}/data/options.json"
  # Test CA plus a server certificate it signed, for the HTTPS round-trip.
  # all-on uses custom_ca.crt, cert-subdir-pem the same CA as certs/rootCA.pem,
  # cert-invalid a file that is no certificate; cert-missing points at nothing.
  # Generated inside the image rather than on the host: Git Bash rewrites both
  # "/CN=..." and "/dev/null" into Windows paths and openssl then fails. The CA
  # needs keyUsage - Python 3.13 verifies strictly and rejects a CA without it.
  docker run --rm --entrypoint sh \
    -v "$(host_path "${RUNDIR}/config")":/out "${IMAGE}" -c '
      set -e
      mkdir -p /out/tls /out/certs
      openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj "/CN=bambuddy-smoke" \
        -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign" \
        -keyout /out/tls/ca.key -out /out/custom_ca.crt
      openssl req -newkey rsa:2048 -nodes -subj "/CN=localhost" \
        -keyout /out/tls/server.key -out /out/tls/server.csr
      printf "subjectAltName=DNS:localhost\nbasicConstraints=CA:FALSE\nkeyUsage=digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth\n" \
        > /out/tls/server.ext
      openssl x509 -req -days 1 -in /out/tls/server.csr -CA /out/custom_ca.crt -CAkey /out/tls/ca.key \
        -CAcreateserial -extfile /out/tls/server.ext -out /out/tls/server.crt
      cp /out/custom_ca.crt /out/certs/rootCA.pem
      echo "this is not a certificate" > /out/not-a-cert.crt' >/dev/null 2>&1
  for generated in custom_ca.crt tls/server.crt tls/server.key certs/rootCA.pem not-a-cert.crt; do
    [ -s "${RUNDIR}/config/${generated}" ] || problem "could not generate the test file ${generated}"
  done

  docker run -d --name "${MOCK}" --network "${NET}" \
    -v "$(host_path "${RUNDIR}/data/options.json")":/mock/options.json:ro \
    bambuddy-smoke-mock-image >/dev/null

  # The run script asks the Supervisor for its options within a second of
  # boot. A mock that is still starting makes every bashio::config call fail
  # and every option block get skipped - locally the mock was always fast
  # enough, on the GitHub runner it was not. Wait until it really answers.
  mock_ready=0
  for _ in $(seq 1 60); do
    if docker exec "${MOCK}" python3 -c \
        'import urllib.request; urllib.request.urlopen("http://127.0.0.1/addons/self/options/config", timeout=1)' \
        >/dev/null 2>&1; then
      mock_ready=1
      break
    fi
    sleep 0.5
  done
  if [ "${mock_ready}" != 1 ]; then
    problem "Supervisor mock did not come up within 30 s"
    docker logs "${MOCK}" 2>&1 | tail -10
    cleanup
    continue
  fi

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
    curl -sf --max-time 5 -o /dev/null "http://127.0.0.1:${PORT}/" && { up=1; break; }
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

  health=$(curl -sf --max-time 5 "http://127.0.0.1:${PORT}/health")
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
      expect_env SSL_CERT_DIR ""
      expect_env DEBUG ""
      # The image's HEALTHCHECK must pass against the running app, or Docker
      # marks it unhealthy and Home Assistant's watchdog restarts it.
      hc=$(docker inspect -f '{{index .Config.Healthcheck.Test 1}}' "${IMAGE}")
      docker exec "${APP}" sh -c "${hc}" >/dev/null 2>&1 \
        && good "HEALTHCHECK command passes" || problem "HEALTHCHECK command fails: ${hc}"
      ;;
    all-on)
      expect_env TRUSTED_FRAME_ORIGINS "http://ha.test:8123,https://example.com"
      expect_env BAMBUDDY_EXTERNAL_ROOTS "/share:/media"
      expect_env USE_SYSTEM_TRUST_STORE "true"
      expect_env SSL_CERT_DIR "/etc/ssl/certs"
      expect_env DEBUG "true"
      expect_log "Setting USE_SYSTEM_TRUST_STORE: true (CA: custom_ca.crt)"
      docker exec "${APP}" sh -c '[ -f /usr/local/share/ca-certificates/bambuddy-custom-ca.crt ]' \
        && good "CA copied into the trust store" || problem "CA was not installed"
      docker exec "${APP}" sh -c \
        'openssl crl2pkcs7 -nocrl -certfile /etc/ssl/certs/ca-certificates.crt | openssl pkcs7 -print_certs -noout 2>/dev/null | grep -q bambuddy-smoke' \
        && good "CA present in the system bundle" || problem "CA missing from the system bundle"
      expect_trusted_tls
      grep -qE "[0-9]+ added, [0-9]+ removed" <<<"${LOG}" \
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
      expect_env SSL_CERT_DIR ""
      expect_log "use_system_trust_store is enabled but certificate file not found: /config/does-not-exist.crt"
      expect_log "Place your CA certificate (.crt) in the addon_configs folder"
      ;;
    empty-origins)
      expect_env TRUSTED_FRAME_ORIGINS ""
      ;;
    cert-subdir-pem)
      # A subfolder used to abort run (cp into a missing directory), and a .pem
      # name was skipped by update-ca-certificates although success was logged.
      expect_env USE_SYSTEM_TRUST_STORE "true"
      expect_env SSL_CERT_DIR "/etc/ssl/certs"
      expect_log "Setting USE_SYSTEM_TRUST_STORE: true (CA: certs/rootCA.pem)"
      expect_trusted_tls
      ;;
    cert-invalid)
      expect_env USE_SYSTEM_TRUST_STORE ""
      expect_env SSL_CERT_DIR ""
      expect_log "use_system_trust_store is enabled but /config/not-a-cert.crt is not a PEM certificate, skipping it"
      ;;
  esac

  # A failed check is much easier to read next to what the run script logged.
  if [ "${PROBLEMS}" != "${problems_before}" ]; then
    echo "  --- last lines of the app log:"
    tail -25 <<<"${LOG}" | sed 's/^/  | /'
  fi

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
