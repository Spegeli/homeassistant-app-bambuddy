"""Minimal stand-in for the Home Assistant Supervisor API.

bashio talks to ${SUPERVISOR_API} (default http://supervisor). Without a
Supervisor every bashio::config call fails and the run script silently skips
every option block, so a smoke test without this mock proves almost nothing.

Only the endpoints bashio actually uses are served; everything else returns an
empty result so an unexpected call cannot hang the test.
"""

import json
from http.server import BaseHTTPRequestHandler, HTTPServer

with open("/mock/options.json", encoding="utf-8") as handle:
    OPTIONS = json.load(handle)


class Handler(BaseHTTPRequestHandler):
    def _send(self, data):
        body = json.dumps({"result": "ok", "data": data}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):  # noqa: N802 - name defined by BaseHTTPRequestHandler
        path = self.path
        if path.startswith("/addons/self/options/config"):
            self._send(OPTIONS)
        elif path.startswith("/addons/self/info"):
            self._send({"slug": "bambuddy", "options": OPTIONS})
        elif path.startswith("/info"):
            self._send({"timezone": "Europe/Berlin", "supervisor": "test"})
        elif path.startswith("/core/info"):
            self._send({"version": "2026.9.0"})
        else:
            self._send({})

    def log_message(self, *args):
        pass


HTTPServer(("0.0.0.0", 80), Handler).serve_forever()
