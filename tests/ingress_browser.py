"""Browser test for Home Assistant Ingress, run by tests/ingress.sh.

Loads the UI in headless Chromium through the Ingress stand-in (below
/api/hassio_ingress/smoketoken/, inside a same-origin iframe like Home
Assistant's panel) and directly on port 8000, and reports every request that
leaves the prefix or fails. Runs inside the Playwright image on the test
network.

Usage: python3 ingress_browser.py <proxy origin> <direct origin>
"""

import sys
from urllib.parse import urlsplit

from playwright.sync_api import sync_playwright

PROXY, DIRECT = sys.argv[1].rstrip("/"), sys.argv[2].rstrip("/")
PREFIX = "/api/hassio_ingress/smoketoken"
# Static files every page needs; a failure here means a broken page.
STATIC = ("/assets/", "/img/", "/fonts/", "/icons/", "/manifest.json")

problems = 0


def problem(message):
    global problems
    problems += 1
    print(f"  FAIL {message}")


def good(message):
    print(f"  ok   {message}")


class Watch:
    """Collects what a page does on the network and in the console."""

    def __init__(self, page, origin):
        self.host = urlsplit(origin).netloc
        self.requests, self.failed, self.sockets, self.errors = [], [], [], []
        self.documents = 0
        page.on("request", self._request)
        page.on("response", self._response)
        page.on("requestfailed", self._request_failed)
        page.on("websocket", lambda ws: self.sockets.append(ws.url))
        page.on("console", self._console)

    def _request(self, request):
        if urlsplit(request.url).netloc == self.host:
            self.requests.append(urlsplit(request.url).path)
        if request.resource_type == "document":
            self.documents += 1

    def _request_failed(self, request):
        # ERR_ABORTED is the browser cancelling a preload it no longer needs or
        # a request of a page being left; it happens when served directly too.
        if "ERR_ABORTED" not in (request.failure or ""):
            self.failed.append(f"{request.url} ({request.failure})")

    def _response(self, response):
        parts = urlsplit(response.url)
        if parts.netloc == self.host and response.status >= 400:
            self.failed.append(f"{parts.path} -> {response.status}")

    def _console(self, message):
        if message.type == "error":
            self.errors.append(message.text)


def settle(page):
    page.wait_for_load_state("networkidle", timeout=60_000)
    page.wait_for_timeout(1500)


def check(name, watch, frame, inside_prefix):
    print(f"--- {name}")
    rendered = frame.evaluate("() => document.getElementById('root')?.childElementCount ?? 0")
    good("app rendered") if rendered else problem("app did not render (#root is empty)")
    if inside_prefix:
        outside = sorted({p for p in watch.requests if not p.startswith(PREFIX + "/") and p != "/panel"})
        good("every request stays below the Ingress prefix") if not outside else problem(
            f"{len(outside)} request(s) left the Ingress prefix: {outside[:8]}")
        ws = [u for u in watch.sockets if urlsplit(u).path == PREFIX + "/api/v1/ws"]
        good("WebSocket through Ingress") if ws else problem(f"no WebSocket below the prefix (seen: {watch.sockets})")
        fonts = [p for p in watch.requests if p.startswith(PREFIX + "/fonts/")]
        good("fonts load below the prefix") if fonts else problem("no font request below the prefix")
    else:
        leaked = sorted({p for p in watch.requests if "hassio_ingress" in p})
        good("no Ingress paths when served directly") if not leaked else problem(f"Ingress paths used directly: {leaked[:8]}")
    static_failures = [f for f in watch.failed if any(s in f for s in STATIC)]
    good("static files load") if not static_failures else problem(f"static files failed: {static_failures[:8]}")
    blocked = [e for e in watch.errors if "Content Security Policy" in e or "Refused to" in e]
    good("no CSP violations") if not blocked else problem(f"CSP: {blocked[:3]}")
    if watch.failed:
        print(f"       (other failed requests: {watch.failed[:6]})")
    good(f"no redirect loop ({watch.documents} page loads)") if watch.documents <= 3 else problem(
        f"{watch.documents} page loads: redirect loop?")


with sync_playwright() as playwright:
    browser = playwright.chromium.launch()

    # Fresh install: BamBuddy sends the browser to its first-run setup page
    # with a full page load, which must land below the prefix, once.
    page = browser.new_page(viewport={"width": 1400, "height": 900})
    watch = Watch(page, PROXY)
    page.goto(f"{PROXY}/panel")
    settle(page)
    app = next((f for f in page.frames if f.url.startswith(f"{PROXY}{PREFIX}/")), None)
    print("--- first run")
    if app is None:
        problem(f"the Ingress iframe did not load (frames: {[f.url for f in page.frames]})")
    else:
        path = urlsplit(app.url).path
        good(f"setup redirect stays below the prefix: {path}") if path == PREFIX + "/setup" else problem(
            f"setup redirect went to {path}")
        good(f"no redirect loop ({watch.documents} page loads)") if watch.documents <= 3 else problem(
            f"{watch.documents} page loads: redirect loop?")
    # Finish the setup (authentication off) through Ingress.
    response = page.request.post(f"{PROXY}{PREFIX}/api/v1/auth/setup", data={"auth_enabled": False})
    good("setup finished through Ingress (POST)") if response.ok else problem(
        f"setup POST through Ingress: HTTP {response.status}")
    page.close()

    # Through Ingress, the way Home Assistant shows it: a same-origin iframe.
    page = browser.new_page(viewport={"width": 1400, "height": 900})
    watch = Watch(page, PROXY)
    page.goto(f"{PROXY}/panel")
    settle(page)
    app = next((f for f in page.frames if f.url.startswith(f"{PROXY}{PREFIX}/")), None)
    if app is None:
        problem(f"the Ingress iframe did not load (frames: {[f.url for f in page.frames]})")
    else:
        check("Ingress panel (iframe)", watch, app, inside_prefix=True)
        # Client-side navigation stays below the prefix.
        link = app.locator("a[href$='/settings']").first
        if link.count():
            link.click()
            settle(page)
            path = urlsplit(app.url).path
            good(f"in-app navigation: {path}") if path == PREFIX + "/settings" else problem(
                f"in-app navigation went to {path}")
        else:
            problem("no link to /settings in the sidebar")
    page.close()

    # A deep link opened directly (camera popup, reload on a sub-page).
    page = browser.new_page(viewport={"width": 1400, "height": 900})
    watch = Watch(page, PROXY)
    page.goto(f"{PROXY}{PREFIX}/settings")
    settle(page)
    check("Ingress deep link /settings", watch, page.main_frame, inside_prefix=True)
    page.close()

    # Served directly on port 8000 nothing may change.
    for path in ("/", "/settings"):
        page = browser.new_page(viewport={"width": 1400, "height": 900})
        watch = Watch(page, DIRECT)
        page.goto(f"{DIRECT}{path}")
        settle(page)
        check(f"direct {path}", watch, page.main_frame, inside_prefix=False)
        page.close()

    browser.close()

print()
print("browser test passed" if problems == 0 else f"browser test FAILED ({problems} problem(s))")
sys.exit(1 if problems else 0)
