#!/usr/bin/env node
// Applies the Home Assistant Ingress changes to an upstream BamBuddy checkout.
//
// Usage: node patch-frontend.mjs <bambuddy-source-dir>
//
// Most of the work is done at runtime by ingress.ts (copied to
// frontend/src/lib/ingress.ts), which fixes root-relative URLs in the browser
// APIs. This script only makes the few changes that cannot be done at runtime:
// the router basename, full-page navigations, pathname checks, asset URLs in
// the build output and the service worker.
//
// Every edit names the text it expects. If upstream changes that text the
// build fails here with the file and the missing text, instead of shipping a
// frontend that breaks under Ingress.

import { copyFileSync, existsSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = process.argv[2];
if (!root) {
  console.error('usage: node patch-frontend.mjs <bambuddy-source-dir>');
  process.exit(2);
}
const frontend = join(root, 'frontend');
const src = join(frontend, 'src');
const here = dirname(fileURLToPath(import.meta.url));

let failed = false;
const fail = (message) => {
  console.error(`ingress patch: ${message}`);
  failed = true;
};

const read = (file) => readFileSync(join(frontend, file), 'utf8');
const write = (file, text) => writeFileSync(join(frontend, file), text);

// Replace `find` with `replace`, expecting exactly `count` matches.
function edit(file, find, replace, count = 1) {
  const text = read(file);
  const found = text.split(find).length - 1;
  if (found !== count) {
    fail(`${file}: expected ${count} x ${JSON.stringify(find)}, found ${found}`);
    return;
  }
  write(file, text.split(find).join(replace));
  console.log(`  ${file}: ${count} x ${JSON.stringify(find)}`);
}

// Add `import { names } from '<relative path to src/lib/ingress>'` at the top.
function addImport(file, names) {
  const fromDir = dirname(join(frontend, file));
  let spec = relative(fromDir, join(src, 'lib', 'ingress')).split(sep).join('/');
  if (!spec.startsWith('.')) spec = `./${spec}`;
  write(file, `import { ${names.join(', ')} } from '${spec}';\n${read(file)}`);
}

const sourceFiles = (dir) =>
  readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    if (statSync(path).isDirectory()) return name === '__tests__' ? [] : sourceFiles(path);
    return /\.tsx?$/.test(name) && !/\.test\.tsx?$/.test(name) ? [path] : [];
  });

console.log('Applying Home Assistant Ingress changes');

// 1. Runtime URL handling, loaded before anything else.
const target = join(src, 'lib', 'ingress.ts');
if (existsSync(target)) fail('frontend/src/lib/ingress.ts already exists upstream');
else copyFileSync(join(here, 'ingress.ts'), target);
write('src/main.tsx', `import './lib/ingress'\n${read('src/main.tsx')}`);

// 2. Client-side routes live under the Ingress prefix.
edit('src/App.tsx', '<BrowserRouter>', '<BrowserRouter basename={BASE_PATH || undefined}>');
addImport('src/App.tsx', ['BASE_PATH']);

// 3. Code that compares the document pathname with an app route.
edit('src/contexts/AuthContext.tsx', '.test(window.location.pathname)', '.test(stripBase(window.location.pathname))');
edit('src/contexts/AuthContext.tsx', 'const currentPath = window.location.pathname;',
  'const currentPath = stripBase(window.location.pathname);');
addImport('src/contexts/AuthContext.tsx', ['stripBase']);

// 4. Full-page navigations to a literal app path, anywhere in the source.
//    location.href cannot be wrapped at runtime.
const navigation = /(window\.location\.href\s*=\s*|window\.location\.(?:assign|replace)\()(['"`])(\/[^'"`$]*)\2/g;
for (const path of sourceFiles(src)) {
  const text = readFileSync(path, 'utf8');
  const changed = text.replace(navigation, (_, call, quote, url) => `${call}withBase(${quote}${url}${quote})`);
  if (changed === text) continue;
  writeFileSync(path, changed);
  const file = relative(frontend, path).split(sep).join('/');
  addImport(file, ['withBase']);
  console.log(`  ${file}: literal navigations`);
}
edit('src/pages/MakerworldPage.tsx', 'window.location.assign(target)', 'window.location.assign(withBase(target))', 2);
if (!read('src/pages/MakerworldPage.tsx').startsWith('import { withBase }')) {
  addImport('src/pages/MakerworldPage.tsx', ['withBase']);
}

// 5. The admin's first settings save stores the browser origin as BamBuddy's
//    external URL. Under Ingress that is Home Assistant, so skip it there.
edit('src/pages/SettingsPage.tsx', '(isAdmin ? window.location.origin : settings.external_url)',
  '(isAdmin && !BASE_PATH ? window.location.origin : settings.external_url)');
addImport('src/pages/SettingsPage.tsx', ['BASE_PATH']);

// 6. pdf.js fetches its runtime data from a worker, where fetch() is not wrapped.
edit('src/components/PdfPreviewModal.tsx', '`${import.meta.env.BASE_URL}assets/pdfjs/`',
  '`${BASE_PATH}${import.meta.env.BASE_URL}assets/pdfjs/`');
addImport('src/components/PdfPreviewModal.tsx', ['BASE_PATH']);

// 7. Fonts: the stylesheet is served from /assets/, so ../fonts/ is /fonts/
//    at the root and <prefix>/fonts/ under Ingress.
edit('src/index.css', "url('/fonts/", "url('../fonts/", 2);

// 8. Build output: index.html keeps root-absolute asset URLs (deep links,
//    upstream #1221; the app's nginx adds the prefix under Ingress), while
//    JS and CSS load their chunks, workers and assets relative to themselves.
edit('vite.config.ts', 'export default defineConfig({', `export default defineConfig({
  experimental: {
    renderBuiltUrl(filename, { hostType }) {
      return hostType === 'html' ? \`/\${filename}\` : { relative: true }
    },
  },`);

// 9. No service worker under Ingress: it would register on Home Assistant's
//    origin.
const swRegister = join(frontend, 'public', 'sw-register.js');
const swText = readFileSync(swRegister, 'utf8');
const swFind = "if ('serviceWorker' in navigator) {";
if (swText.split(swFind).length !== 2) fail(`public/sw-register.js: expected 1 x ${JSON.stringify(swFind)}`);
else {
  writeFileSync(swRegister, swText.replace(swFind,
    "if ('serviceWorker' in navigator && !location.pathname.startsWith('/api/hassio_ingress/')) {"));
  console.log('  public/sw-register.js: skipped under Ingress');
}

// Guard: a new comparison of window.location.pathname with an app route would
// redirect in a loop under Ingress. Every remaining use must be reviewed.
const allowed = /(stripBase\(window\.location\.pathname|cleanUrl = window\.location\.pathname)/;
for (const path of sourceFiles(src)) {
  readFileSync(path, 'utf8').split('\n').forEach((line, index) => {
    if (line.includes('window.location.pathname') && !allowed.test(line) && !path.endsWith(`${sep}ingress.ts`)) {
      fail(`${relative(frontend, path)}:${index + 1}: unreviewed window.location.pathname: ${line.trim()}`);
    }
  });
}

if (failed) {
  console.error('ingress patch: upstream changed; update ingress/patch-frontend.mjs');
  process.exit(1);
}
console.log('Done');
