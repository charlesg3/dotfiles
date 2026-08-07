#!/usr/bin/env node
// Connects to the live-session daemon's Chrome over CDP, exposes `browser`,
// `context`, `page`, and `playwright` as globals, then dynamically imports the
// user's .mjs. The user script can use them as bare identifiers and may use
// top-level await.
import * as playwright from 'playwright-core';
import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';

const { chromium } = playwright;

const endpoint = process.env.LIVE_SESSION_WS;
const userScriptPath = process.argv[2];
if (!endpoint || !userScriptPath) {
  console.error('usage: LIVE_SESSION_WS=<cdp-endpoint> runner.mjs <script.mjs>');
  process.exit(2);
}

const browser = await chromium.connectOverCDP(endpoint);
let exitCode = 0;
try {
  // A CDP connection to a real Chrome always exposes its default context at [0];
  // fall back to creating one only if Chrome somehow reported none.
  const context = browser.contexts()[0] ?? await browser.newContext();
  const pages = context.pages();
  const page = pages[pages.length - 1] ?? await context.newPage();
  globalThis.browser = browser;
  globalThis.context = context;
  globalThis.page = page;
  globalThis.playwright = playwright;
  await import(pathToFileURL(resolve(userScriptPath)).href);
} catch (err) {
  console.error(err);
  exitCode = 1;
} finally {
  // We do NOT call browser.close(): over CDP that would tear down the daemon's
  // Chrome. Letting the process exit just drops the CDP connection, leaving the
  // session — tabs, DOM, login state — intact for the next `exec`.
  process.exit(exitCode);
}
