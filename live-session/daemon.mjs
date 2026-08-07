#!/usr/bin/env node
// Long-running daemon: launches a non-headless *real* Google Chrome with a
// remote-debugging port and a persistent user-data-dir, then publishes its CDP
// endpoint so `live-session.sh exec` can connect over CDP via Playwright.
//
// Why real Chrome + a persistent profile (instead of a throwaway Chromium):
// the profile keeps your SSO/cookies between `start`/`stop` cycles, so you log
// into Datadog / Grafana / etc. once and stay logged in.
import { spawn } from 'node:child_process';
import { writeFile, unlink, mkdir, access } from 'node:fs/promises';
import { constants as FS } from 'node:fs';
import { join, dirname } from 'node:path';

const stateDir = process.env.LIVE_SESSION_STATE_DIR;
if (!stateDir) {
  console.error('LIVE_SESSION_STATE_DIR not set');
  process.exit(2);
}

// CDP endpoint file. Kept named `wsEndpoint` for back-compat with the shell and
// any external tooling; it now holds an `http://127.0.0.1:PORT` CDP endpoint
// (Playwright's connectOverCDP resolves the ws:// URL from it).
const wsEndpointFile = join(stateDir, 'wsEndpoint');

const port = Number(process.env.LIVE_SESSION_CDP_PORT || 9222);
// Persistent profile lives under live-session/.cache so it survives `stop`.
const profileDir = process.env.LIVE_SESSION_PROFILE_DIR
  || join(stateDir, '..', '.cache', 'chrome-profile');
const startURL = process.env.LIVE_SESSION_URL || '';
const headless = /^(1|true|yes)$/i.test(process.env.LIVE_SESSION_HEADLESS || '');

// Locate a real Google Chrome / Chromium binary across platforms.
async function findChrome() {
  if (process.env.LIVE_SESSION_CHROME) return process.env.LIVE_SESSION_CHROME;
  const candidates = process.platform === 'darwin'
    ? [
        '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
        '/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary',
        '/Applications/Chromium.app/Contents/MacOS/Chromium',
      ]
    : [
        '/usr/bin/google-chrome',
        '/usr/bin/google-chrome-stable',
        '/opt/google/chrome/chrome',
        '/usr/bin/chromium',
        '/usr/bin/chromium-browser',
        '/snap/bin/chromium',
      ];
  for (const c of candidates) {
    try { await access(c, FS.X_OK); return c; } catch {}
  }
  return null;
}

// True once Chrome's DevTools endpoint answers on the debug port.
async function cdpReady() {
  try {
    const r = await fetch(`http://127.0.0.1:${port}/json/version`);
    return r.ok;
  } catch { return false; }
}

const endpoint = `http://127.0.0.1:${port}`;

// If something is already serving the port, refuse rather than spawn a Chrome
// that would silently hand off to the existing instance and exit.
if (await cdpReady()) {
  console.error(`[daemon] port ${port} already has a CDP endpoint; stop it first ` +
    `or set LIVE_SESSION_CDP_PORT to a free port`);
  process.exit(3);
}

const chrome = await findChrome();
if (!chrome) {
  console.error('[daemon] could not find Google Chrome / Chromium. Install it, ' +
    'or set LIVE_SESSION_CHROME to the binary path.');
  process.exit(4);
}

await mkdir(profileDir, { recursive: true });
await mkdir(dirname(wsEndpointFile), { recursive: true });

const args = [
  `--remote-debugging-port=${port}`,
  `--user-data-dir=${profileDir}`,
  '--no-first-run',
  '--no-default-browser-check',
  ...(headless ? ['--headless=new'] : []),
];
if (startURL) args.push(startURL);

console.log(`[daemon] launching ${chrome}`);
console.log(`[daemon] profile: ${profileDir}`);
const child = spawn(chrome, args, { stdio: 'inherit' });

let shuttingDown = false;
const shutdown = async (signal) => {
  if (shuttingDown) return;
  shuttingDown = true;
  console.log(`[daemon] shutting down (${signal})`);
  try { child.kill('SIGTERM'); } catch {}
  try { await unlink(wsEndpointFile); } catch {}
  process.exit(0);
};

// Closing the Chrome window shuts the daemon down cleanly, matching the old
// `browser.on('disconnected')` behavior.
child.on('exit', (code) => shutdown(`chrome-exit:${code}`));
child.on('error', (err) => { console.error('[daemon] chrome spawn error:', err); shutdown('chrome-error'); });
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT',  () => shutdown('SIGINT'));

// Wait for the debug endpoint, then publish it.
for (let i = 0; i < 150; i++) {       // ~30s at 200ms
  if (await cdpReady()) break;
  if (i === 149) { console.error('[daemon] Chrome never opened its CDP port'); await shutdown('cdp-timeout'); }
  await new Promise((r) => setTimeout(r, 200));
}

await writeFile(wsEndpointFile, endpoint, 'utf8');
console.log(`[daemon] browser ready: ${endpoint}`);

// Keepalive — without a pending handle an idle event loop could exit.
setInterval(() => {}, 1 << 30);
