# live-session

A long-lived real Chrome window, driven from scripts over CDP with Playwright.

The profile is persistent, so logins survive `stop`/`start` and machine
restarts: log into a site by hand once, then keep scripting it for weeks
without touching credentials or storing cookies anywhere.

Driven by `scripts/live-session`. Requires node (`./install.sh --node`) and a
real Google Chrome or Chromium; `playwright-core` installs itself here on first
start.

## Use

```sh
live-session start          # opens Chrome, daemonizes, returns immediately
live-session status
live-session exec FILE.mjs  # run a script in that browser
live-session stop
```

`start` is idempotent. `exec` connects, runs the script, and disconnects
without closing the browser, so tabs, DOM and login state carry over to the
next `exec`.

The script gets four globals and may use top-level await:

| global | what |
|---|---|
| `page` | most recently focused page |
| `context` | its BrowserContext |
| `browser` | the CDP connection |
| `playwright` | the `playwright-core` module |

## Writing the script

Write to a file and pipe it in, rather than using a heredoc or `-c` string:

```sh
live-session exec - < snippet.mjs
```

Anything going through the shell forces escaping of `$`, backticks, `!`,
quotes and backslashes, which gets painful in any non-trivial script. Writing
the file with an editor avoids that entirely.

## Environment

| var | default |
|---|---|
| `LIVE_SESSION_CDP_PORT` | `9222` |
| `LIVE_SESSION_PROFILE_DIR` | `.cache/chrome-profile` |
| `LIVE_SESSION_CHROME` | first Chrome/Chromium found |
| `LIVE_SESSION_URL` | none |
| `LIVE_SESSION_HEADLESS` | unset (headed) |

Set `LIVE_SESSION_CDP_PORT` to run a second session alongside the first; the
daemon refuses to start on a port that already answers CDP, rather than
silently handing off to the browser already there.

## Notes

- `.state/` holds the pid and CDP endpoint, `.cache/` the Chrome profile. Both
  are gitignored; deleting `.cache/` logs you out of everything.
- `exec` never calls `browser.close()`. Over CDP that would kill the daemon's
  Chrome.
- playwright-core 1.62 requires node 20+. On an older node the wrapper installs
  the 1.61 line instead, so it still runs.
