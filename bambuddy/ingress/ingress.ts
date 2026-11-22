/**
 * Home Assistant Ingress support.
 *
 * Added to BamBuddy's frontend by the Home Assistant app build
 * (ingress/patch-frontend.mjs); it is not part of upstream BamBuddy.
 *
 * Under Ingress the app is served at /api/hassio_ingress/<token>/ on Home
 * Assistant's origin instead of at "/". The prefix is read from the document
 * URL, so the token is never baked in at build time and a new token just
 * works. Outside Ingress BASE_PATH is "" and this module changes nothing.
 *
 * BamBuddy builds root-relative URLs ("/api/v1/...", "/img/...") in many
 * places. Rather than editing every one of them (and every new one each
 * release), the browser APIs that take a URL are wrapped here so that a
 * root-relative URL, or a same-host URL outside the prefix, gets the prefix.
 * Anything already under the prefix, cross-host, data:, blob: or relative is
 * left alone.
 */

const INGRESS_PATH = /^\/api\/hassio_ingress\/[^/]+/;

export const BASE_PATH: string = INGRESS_PATH.exec(window.location.pathname)?.[0] ?? '';

function outsideBase(path: string): boolean {
  return path !== BASE_PATH && !path.startsWith(`${BASE_PATH}/`);
}

/** Prefix a root-relative URL ("/login") with BASE_PATH. */
export function withBase(url: string): string {
  if (!BASE_PATH || !url.startsWith('/') || url.startsWith('//') || !outsideBase(url)) return url;
  return BASE_PATH + url;
}

/** The app route for a document pathname ("/api/hassio_ingress/x/setup" -> "/setup"). */
export function stripBase(pathname: string): string {
  if (!BASE_PATH || outsideBase(pathname)) return pathname;
  return pathname.slice(BASE_PATH.length) || '/';
}

/** withBase() for root-relative and same-host absolute URLs (http, https, ws, wss). */
function fixUrl(url: string): string {
  if (url.startsWith('/')) return withBase(url);
  if (!/^(?:https?|wss?):\/\//i.test(url)) return url;
  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    return url;
  }
  if (parsed.host !== window.location.host || !outsideBase(parsed.pathname)) return url;
  parsed.pathname = BASE_PATH + parsed.pathname;
  return parsed.href;
}

function install(): void {
  // fetch() with a string, URL or Request.
  const nativeFetch = window.fetch.bind(window);
  window.fetch = ((input: RequestInfo | URL, init?: RequestInit) => {
    if (typeof input === 'string') return nativeFetch(fixUrl(input), init);
    if (input instanceof URL) return nativeFetch(fixUrl(input.href), init);
    const fixed = fixUrl(input.url);
    return nativeFetch(fixed === input.url ? input : new Request(fixed, input), init);
  }) as typeof window.fetch;

  // XMLHttpRequest (upload progress uses it).
  const nativeXhrOpen = XMLHttpRequest.prototype.open as (...args: unknown[]) => void;
  XMLHttpRequest.prototype.open = function open(this: XMLHttpRequest, ...args: unknown[]) {
    if (args.length > 1) args[1] = fixUrl(String(args[1]));
    nativeXhrOpen.apply(this, args);
  } as typeof XMLHttpRequest.prototype.open;

  // WebSocket and EventSource, e.g. `${proto}//${location.host}/api/v1/ws`.
  const NativeWebSocket = window.WebSocket;
  window.WebSocket = class extends NativeWebSocket {
    constructor(url: string | URL, protocols?: string | string[]) {
      super(fixUrl(String(url)), protocols);
    }
  };
  const NativeEventSource = window.EventSource;
  window.EventSource = class extends NativeEventSource {
    constructor(url: string | URL, init?: EventSourceInit) {
      super(fixUrl(String(url)), init);
    }
  };

  // window.open('/camera/1', ...) popups.
  const nativeWindowOpen = window.open.bind(window);
  window.open = (url?: string | URL, target?: string, features?: string) =>
    nativeWindowOpen(url === undefined ? url : fixUrl(String(url)), target, features);

  // Element URLs: React sets attributes, plain code sets properties
  // (img.src = ..., a.href = ...). Both are covered before the browser loads
  // anything.
  const URL_ATTRIBUTES = ['src', 'href', 'poster'];
  const nativeSetAttribute = Element.prototype.setAttribute;
  Element.prototype.setAttribute = function setAttribute(this: Element, name: string, value: string) {
    const fixed = typeof value === 'string' && URL_ATTRIBUTES.includes(name.toLowerCase()) ? fixUrl(value) : value;
    nativeSetAttribute.call(this, name, fixed);
  };
  const wrapProperty = (proto: object, property: string) => {
    const descriptor = Object.getOwnPropertyDescriptor(proto, property);
    if (!descriptor?.set || !descriptor.get) return;
    const nativeSet = descriptor.set;
    Object.defineProperty(proto, property, {
      ...descriptor,
      set(this: Element, value: unknown) {
        nativeSet.call(this, typeof value === 'string' ? fixUrl(value) : value);
      },
    });
  };
  wrapProperty(HTMLImageElement.prototype, 'src');
  wrapProperty(HTMLMediaElement.prototype, 'src');
  wrapProperty(HTMLSourceElement.prototype, 'src');
  wrapProperty(HTMLIFrameElement.prototype, 'src');
  wrapProperty(HTMLVideoElement.prototype, 'poster');
  wrapProperty(HTMLAnchorElement.prototype, 'href');
  wrapProperty(HTMLLinkElement.prototype, 'href');

  // HTML inserted as markup (innerHTML / dangerouslySetInnerHTML) bypasses
  // both of the above; fix its URLs as soon as it lands in the document.
  const selector = URL_ATTRIBUTES.map((name) => `[${name}^="/"]`).join(',');
  const fixElement = (element: Element) => {
    for (const name of URL_ATTRIBUTES) {
      const value = element.getAttribute(name);
      if (value === null) continue;
      const fixed = fixUrl(value);
      if (fixed !== value) nativeSetAttribute.call(element, name, fixed);
    }
  };
  new MutationObserver((records) => {
    for (const record of records) {
      if (record.type === 'attributes') {
        if (record.target instanceof Element) fixElement(record.target);
        continue;
      }
      record.addedNodes.forEach((node) => {
        if (!(node instanceof Element)) return;
        if (node.matches(selector)) fixElement(node);
        node.querySelectorAll(selector).forEach(fixElement);
      });
    }
  }).observe(document.documentElement, {
    subtree: true,
    childList: true,
    attributes: true,
    attributeFilter: URL_ATTRIBUTES,
  });
}

if (BASE_PATH) install();
