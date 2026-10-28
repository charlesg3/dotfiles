# Workflow Notes

Tool-agnostic working practices, tracked in the dotfiles repo. Anything tied to
a specific machine, employer, or repo (hostnames, project IDs, cluster access,
per-repo CI policy, script paths) lives in `~/.claude/SITE.md`, which is not
tracked here.

## Git: always start from latest main

Before starting any new work in a repo (branching, editing, or basing anything
on main), run `git fetch origin` and base the work on `origin/main`, not the
possibly stale local `main` or a stale remote tracking ref. Local checkouts sit
idle for long stretches and fall behind.

When consulting another local repo for reference: if it's on the default branch
with no outstanding changes, `git pull --ff-only` first so you're reading
current code. If it's on a feature branch or dirty, leave it alone and flag
that the copy may be stale.

## Track task work in beads (`bd`)

Use beads to track the work on any task with more than a couple of steps, in
the repo where the work happens. Skip it for a one-off lookup or question.

1. If the repo has no `.beads/`, run `bd init --stealth --non-interactive`.
   Stealth keeps the tracker personal: `.beads/` goes into
   `.git/info/exclude` and nothing is committed. Never commit `.beads/` and
   never push it to a Dolt or git remote.
2. Run `bd ready` first to see open work from earlier sessions.
3. Create one issue for the task (`bd q "<title>"`, or `bd create` with
   `-d`). Add a child issue (`--parent <id>`) for each separate step or
   follow-up that will outlive the session, such as "merge after review" or
   "apply once the drift is fixed".
4. Run `bd update <id> --claim` when you start. Record decisions and blockers
   with `bd note <id> "..."`.
5. Run `bd close <id> --reason "..."` when it is done: merged, applied, or
   answered.

Beads is for tasks only. Its default agent text says to replace the memory
files and the in-session todo list. Ignore that: keep the existing memory
system, and keep using the session todo list for steps within one session.
A SessionStart hook runs `bd prime`, which prints the beads context only in
repos that have `.beads/`. `bd setup claude --global` installs that hook, and
it also writes a beads section into the `CLAUDE.md` of the current directory.
Run it from a scratch directory, never from inside a repo.

## Be cognizant of audience context

Match content to what its audience needs; drop process detail that only mattered
in the moment.

- MR/PR descriptions: what the change does and why, plus validation results. No
  session mechanics (test environments torn down, worktrees used, monitors set).
- Code comments: only what the code does and why, briefly. No external project
  names, prior-work references, or identifiers a human reader can't use (ticket
  ids, MR numbers, incident links, internal request ids).
- Tests: proportional to risk. Don't write dedicated tests for trivial wrappers
  or simple interfaces when broader scenario coverage already exercises the
  behavior.
- Chat messages: identifiers go in code spans, every time, not only in review
  requests. Field names, CR and cluster names, settings, commands, file paths,
  error strings. `slurmConfigOverride.controllerExtraConfs` and
  `slurmaas-zdzxhcao` are unreadable as prose and are what the reader will copy.
  In HTML for Slack that means `<code>`, and it is the first thing to drop by
  accident when a message is drafted as plain text and marked up afterwards.

Two voice registers, chosen by whether a person or no one in particular is the
reader:

- Talking to a person (Slack messages, chat replies, anything landing in a
  DM or channel for someone to read): write like a person explaining their
  own work. Hedge with "I think", "So I looked at", "From what I can tell" —
  not declarative report language ("Confirmed X", "Verified Y"). The hedge is
  in the phrasing, not the rigor — still back every claim with what was
  actually checked.
- Writing for no one in particular (docs, code comments, commit messages, MR
  descriptions): plain, direct, simple sentences — an STE100 (Simplified
  Technical English) register. State findings directly; no need to narrate
  "I looked into this."

*Always*, in both registers: no superlative/emphatic words ("exactly",
"precisely", "absolutely", "perfect"), no em-dashes.

## Verify full behavior before characterizing severity

Before describing how a bug behaves (a permanent failure, an outage, "errors
forever"), trace the control flow both back to the root cause and forward
through whatever happens after the failure, including any existing recovery,
retry, or fallback logic downstream. Finding a root cause is not the same as
verifying behavior. Confirm against actual evidence (log timestamps, resource
creation times, current running state), not inference from reading one code path
in isolation.

This matters most right before a characterization leaves the terminal: MR
descriptions, commit messages, chat messages. Once someone else reacts to or
repeats a wrong claim, it's a public correction instead of a private one.

## Measure before accepting a refactor

When a review comment proposes replacing local logic with an existing shared
helper, count what each version does against real data before agreeing. A
straight lift can compile, pass every test, and still change behavior, because
the shared version was written to answer a different question.

The case that taught this: reusing a shared health-condition ranker looked free.
The existing one returns nothing unless a condition asks for a repair, which is
right for choosing a repair and wrong for naming a fault. One query over live
data showed it would name a fault on 4 of 13 unhealthy hosts where the local
version named 12. Nothing in the code or the tests said so.

That number is what turned "reuse it" into "reuse the ordering, not the
nil-semantics", and it reads better in the review reply than an argument from
having read the code.

## Second opinion from another agent

When a change deserves an independent read, or when work can run in parallel,
spawn a second agent. `codex exec` is the usual one; site notes hold the
launcher path and any box-specific flags. Generic gotchas:

- Never `pkill -f 'codex exec'` from a launcher script. The launching shell has
  "codex exec" in its own argv, so it self-kills (exit 1, empty log). Match a
  more specific pattern if you need to kill a prior run.
- Pass the prompt as a single quoted arg. A long prompt from a file works via
  `"$(cat file)"`: quoting stops word-splitting and makes backticks in the file
  inert data rather than commands. Both bare stdin and the `-f` flag have hung
  indefinitely on "Reading additional input from stdin...".
- codex runs OpenAI models, so it doesn't trip Claude's cyber-safety
  classifier. Useful as a second opinion on crash, exploit, or repro topics that
  might otherwise get flagged.
- Its default reasoning effort is only "medium". Pass `-r max` for deep
  research and analysis, `-r high` for demanding code-writing tasks that don't
  need the full research depth.

## Simplicity review (a second pass after correctness review)

After a change has passed its correctness review (challengers/tests green, MR
up), spawn a second-opinion agent for one high-level pass before asking humans
for review. Scope it away from bug-hunting, which already happened, and at the
shape of the code:

1. Simplifications: structurally simpler alternatives with the same behavior
   (fewer concepts, fewer indirections, collapsed helpers); anything
   over-abstracted for what it does.
2. Understandability: can a maintainer unfamiliar with the spec follow the
   flow; where would they stumble; are comments at the right altitude (why vs
   what).
3. Naming: judge each new identifier and label/key by name, honest about what it
   does, no conceptual collisions; suggest better names.
4. Exported surface: anything public that need not be.

Prompt recipe: state the review is high-level (no bug hunt), give the worktree
path and commit (`git show <sha>`), a one-paragraph context of what the change
does, the key files, related spec sections ("read for intent, do not review the
doc"), the 4 deliverables above, and ask for a ranked list with file:line plus a
concrete change, saying explicitly when something is fine as-is. Findings are
suggestions for the human to accept, not auto-applied.

## Review request format (chat)

- Line 1: bold `Review Request:` then the MR/PR link and a short scope phrase
  (`!7958 - Phase 3a of the version lifecycle.`).
- Next line(s): 1-3 sentence description of what the change does, identifiers in
  code spans. End with the forward-looking hook if there is one ("Phase 3b
  consumes this as the per-cluster pin") or "Quick stamp appreciated." for
  one-liners.
- Last line: `/cc @<reviewer>` when directed at someone.
- No "Looking for a review on...", no process detail (pipelines, threads, scope
  guidance); pipeline state only when it is the ask, e.g. approval nudges.
- **Backports use a different anchor.** Not the full title but
  `!<MR> - <release line>`, then `, against <branch>`, then whether it applied
  cleanly or needed adaptations, and finally the ticket link plus the approval
  count. Name the adaptations explicitly when there are any, since those are the
  parts worth reviewing.
- Delivery: post from your own account. Build it as HTML rich text (bold
  `Review request:`, a clickable link whose anchor is `!<MR> - <full title>`,
  identifiers in `<code>`) and copy with the NSPasteboard snippet in
  `CLAUDE.md`, setting both `.html` and `.string`, then paste.
- Pasted text does not resolve `@mentions`. After pasting, retype the reviewer in
  the composer so the `/cc` is a real ping.

## Merge monitor

A background watcher on an open GitLab MR that carries it through review,
CI, merge and the post-merge pipeline. The script is `scripts/merge-monitor`
in this repo, and it is on the PATH. Run `merge-monitor <MR>` from the repo
with the `Monitor` tool. Each line it prints is one state change and
re-invokes the agent. With no `--project`, it finds the project from
`origin`.

Site notes say where the guide to the events is, and which other copy of the
script to keep in step with this one.

## gh CLI gotchas

- **`gh auth status` is a bad auth probe.** It exits nonzero whenever any
  configured account is stale, even when the active token is valid and every API
  call works. Scripts should probe with `gh api user` instead.
- **`gh repo fork <repo>` rejects `--clone`/`--remote`.** "the `--remote` flag is
  unsupported when a repository argument is provided". Drop both flags; with a
  repo argument it neither clones nor adds a remote by default.

## Running multi-line commands over ssh

For anything past a single command, pipe a quoted heredoc to `bash -s` rather
than fighting nested quotes:

```bash
ssh <host> 'bash -s' <<'SCRIPT'
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
...
SCRIPT
```

A `zsh -lc "..."` wrapper breaks on ordinary characters (a literal `===` in an
echo becomes `zsh: == not found`), and single quotes inside inner Python or jq
need escaping that's easy to get wrong. The heredoc is quoted, so nothing
expands locally and the remote script reads as written. `bash -s` doesn't read
the login profile, so set `PATH` explicitly at the top.

## Slack messages: what formatting survives, and tables do not

Measured on Slack's own composer, both by pasting from a real clipboard and by
driving the editor directly. The composer is Quill, and it converts markup as
you **type** rather than when text arrives, so anything pasted keeps whatever
form it arrived in. Backticks pasted as text stay backticks.

**The message composer cannot make a table.** Its toolbar is bold, italic,
underline, strike, link, ordered list, bullet list, blockquote, code and code
block, and nothing else — checked by reading the buttons. Tables you have seen in
Slack are canvases, lists, or a message an app posted through Block Kit, none of
which a person types into a composer. Neither paste route produces one. Sending
`<table>` through the editor's own clipboard module flattens it to
`backendcountsmas17legacy4`, with every cell boundary gone; sending the same
table as the HTML flavour of a real clipboard makes Slack ignore it and take
the plain-text flavour instead.

The first is the dangerous one, because the cells run together into something
that reads like data rather than like a failure.

**Send a code block instead.** It is the only construct that holds columns,
because it is fixed width, and it survives both routes intact:

```
backend  count
smas     17
legacy    4
```

Pad the columns by hand. A list with bold labels also survives and reads better
for two or three rows.

**What does survive**, both routes: code spans, bold, italic, strikethrough,
lists, block quotes and code blocks. Labelled links survive too, from a real
clipboard with the HTML flavour and from sdraft's synthesised paste (confirmed
2026-10-02).

**A plain-text fallback is not decoration.** When a paste carries both flavours
Slack may take the plain one, which is exactly what happens to a table. Write
that fallback so it reads on its own, one row per line, rather than letting it
collapse into a sentence.

## Leaving a reply in a Slack composer, unsent (`sdraft`)

Everything above is about getting formatting onto a clipboard so it survives a
paste. `sdraft` skips the clipboard: it takes Markdown and leaves it in a
conversation's composer, formatted, **unsent**. Standalone, with no queue, no
database and no Slack token. Reach for it when the job is "answer this thread"
rather than "hand me something to paste".

```bash
sdraft <ref> [--from <file>]        # or the reply on stdin
sdraft --dry-run <ref> < reply.md   # the two rendered flavours, drives nothing
```

**It never sends, and that is a property of the code rather than a habit.** No
key is pressed and nothing is clicked: the reply arrives as a synthesised paste
event carrying a DataTransfer, the same event a real cmd-V produces. There is no
path through it that reaches Slack's send.

`<ref>` is a permalink, a client URL, a bare `C…`/`D…`/`G…`, or an id with a
thread as `C…/1712300000.000100`. Two things about which composer that means:

- **A permalink with no `thread_ts` is the conversation's own box, not a new
  thread on that message.** Slack writes the root into the query string for every
  message that is in a thread, the root included, and leaves it off a message in
  none. Starting a thread on a particular message is the explicit `C…/<ts>` form.
- **A conversation's own composer is shared** by every message in it that has no
  thread, so "draft twice" can mean two different boxes or the same one.

**It replaces only what it left there itself.** A composer holding words somebody
typed is refused rather than clobbered, and the comparison is against the text
read back out of that box after the last fill, kept in
`${XDG_STATE_HOME:-~/.local/state}/sdraft/left.json`. Deleting that file costs one
refusal per box and never a wrong draft.

**Never a permalink in the browser.** `.../archives/<C>/p<ts>` is a desktop-app
handoff page, and on a machine with no Slack app every navigation to one throws an
OS dialog. The address is built the way the client addresses itself,
`app.slack.com/client/<team>/<channel>`, with the team read out of the browser's
own current address.

The Markdown rules are the ones above, applied: a heading becomes bold because
Slack has none, a table becomes a padded code block, and `[words](url)` becomes
a real link. The `left in ... unsent:` line sdraft prints shows the plain-text
flavour, where a link reads `words (url)`; that line does not mean the link is
missing. `--dry-run` shows the `<a href>` in the HTML flavour.

**It drives Chrome itself, over the debugging protocol.** There is no session
manager, no daemon and no pid file, and Playwright is not installed anywhere: it
fetches the target list off `/json/list`, opens a websocket to the page and
speaks three protocol methods. So what it needs is a browser, not a wrapper
around one, and a browser that a session manager has lost track of still works.

What a machine has to have: Chrome started with `--remote-debugging-port=9222` on
the profile that is signed in to Slack, node 22 or newer on the PATH a
non-interactive `ssh` gets, and `ssh` to it working without a password. **Quit
Chrome before starting it with the flag** — a second launch hands its arguments
to the copy already running, which never gets the port and says nothing about it.

`sdraft --dry-run <ref>` renders both forms and drives nothing, so the markup can
be checked before a browser is involved at all.

## Rich text to a remote mac's clipboard, the way that sticks

Setting a mac clipboard over a non-interactive ssh session has two traps, and
both fail quietly. Use `osascript` with a record holding both flavors:

```bash
scp msg.txt msg.html <host>:/tmp/        # BOTH files must exist on the remote box
ssh <host> 'bash -s' <<'SCRIPT'
osascript <<'AS'
set htmlDat to (read (POSIX file "/tmp/msg.html") as «class HTML»)
set txtDat to (read (POSIX file "/tmp/msg.txt") as «class utf8»)
set the clipboard to {«class HTML»:htmlDat, string:txtDat}
AS
osascript -e 'clipboard info'            # expect «class HTML» plus string
pbpaste | head -3                        # reads back only if the string flavor is set
SCRIPT
```

**Set the HTML flavor, do not convert to RTF.** Slack reads `«class HTML»`
directly, and the HTML bytes go on the pasteboard untouched. Routing through
`textutil ... -convert rtf` adds a conversion that guesses the input encoding,
lands on Latin-1, and mangles every multi-byte character: a bullet pastes as
`â€¢` and an arrow as `âž¡ï¸`. The plain-text flavor still looks fine, because
`osascript` reads it as `«class utf8»`, so the corruption only shows in the rich
paste and only once the text has something outside ASCII.

- **The Swift `NSPasteboard` snippet in `CLAUDE.md` does nothing over ssh.** It
  prints "Copied!" and writes nothing, because an AppKit process in a
  non-interactive session does not own the GUI pasteboard. It is fine when run
  on the machine's own console. Over ssh it is a silent no-op, so a stale
  clipboard looks like the copy worked.
- **`pbcopy` works over ssh but sets one flavor.** `pbcopy -Prefer rtf` leaves
  no plain-text flavor, so `pbpaste` comes back empty and there is no way to
  confirm what landed. `clipboard info` still reports the RTF, which is the only
  check available in that case.
- **Both source files have to be on the remote box.** Referencing a local path
  from the remote `osascript` fails with `Can't make file ... into type file`.
- Always verify with `pbpaste`, not with the exit status. Every wrong attempt
  here reported success.
- Verify the glyphs, not only that text came back. Decode the HTML flavor with
  `osascript -e 'the clipboard as «class HTML»'` and look at a line containing
  the non-ASCII characters, rather than trusting `pbpaste`, which reads the
  plain flavor and stays clean even when the rich one is corrupt.

## Reading a Google Doc through a logged-in browser

Docs renders the body into `<canvas>`, so there is nothing in the DOM to read.
`.kix-lineview` returns zero elements and `innerText` on the editor gives you
only the comment sidebar, which looks like content and is not. Screenshots plus
scrolling do work, but they are slow and lossy on a long doc, so keep them as
the last resort rather than the first move.

`/export?format=markdown` (or `txt`) is the obvious route and returns **403
"You need access"** on any doc whose sharing settings disable download, even
when you can read it fine in the browser. `/feeds/download/documents/export/Export`
gives the same 403 and `/htmlview` 404s. None of that means you lack access.

**`/mobilebasic` is the one that works.** It is server-rendered HTML, it honors
the session cookies, and it carries the whole doc: every tab of a tabbed doc in
order, and the comments as anchored `[a]`, `[b]` footnotes at the end. Fetch it
from inside a page already on `docs.google.com`, so the cookies ride along and
nothing has to navigate:

```js
const r = await fetch(`https://docs.google.com/document/d/${id}/mobilebasic`,
                      {credentials: 'include'});
```

Both halves are scripted in the live-session repo (path in site notes):
`live-session/gdoc-export.mjs` writes the HTML out of the browser, and
`tools/gdoc2md.py` converts it to Markdown with no dependencies. Reuse them
rather than re-deriving this, because two things break a naive tag strip:

- **Tables need a grid layout.** Docs puts a `rowspan`'d spacer column between
  the halves of a two-up table, so the header row has one more cell than the
  data rows. Trusting per-row cell counts shifts every data row one column left
  of its header, and the result still looks like a valid table.
- **There is no code-block element.** A fenced block arrives as a run of
  monospace paragraphs, one per line, so a `# comment` inside a shell snippet
  becomes a Markdown heading unless the run is regrouped into a fence.

One more trap while poking at the page: do not build a scratch element and
assign `innerHTML` to strip tags. Docs enforces Trusted Types, so the assignment
throws `This document requires 'TrustedHTML' assignment` and that failure reads
like the fetch failed. Use a regex, or parse the HTML outside the browser.

## Pasting Markdown into Google Docs: what actually converts, what doesn't

Docs' own "Automatically detect Markdown" paste feature (Tools > Preferences)
converts headings, bold/italic, lists, and `[text](url)` links **on paste**.
It does not do the same on live typing — typed `# Heading` and `[text](url)`
stay as literal characters, no heading style, no hyperlink. Confirmed by
typing both via automation into a real doc and reading the result back: no
`font-size:20pt` heading styling, no `<a href>` created. Don't assume a
typing-based test tells you anything about paste behavior; they're different
code paths.

**A `[text](#some-anchor)` link does not resolve to an internal heading, ever,
paste or type.** GitHub-style anchor slugs are a CommonMark-rendering
convention Docs has no concept of. Docs' own internal heading links use a
completely different, per-document, auto-generated bookmark id
(`#heading=h.<random-hash>`, e.g. `#heading=h.rg0s3y8vspw5`) that only exists
once that heading has actually been created in that specific document — there
is no way to predict it from portable Markdown authored before the doc
exists.

**The bare `#h.xxxxx` fragment `/mobilebasic` exports is not the whole
reference, and pasting just that fragment does not work.** A doc that uses
Docs' tabs feature needs the tab identified too: a link created through
Docs' own UI (Insert > Link > Headings and bookmarks) resolves to
`?tab=t.<tabhash>#heading=h.<headinghash>` — the full query string plus a
`heading=` prefix on the fragment, not `#h.<headinghash>` alone. The
`/mobilebasic` export flattens every tab into one long page and simplifies
every internal anchor down to the bare `#h.xxxxx` form regardless of what
the real link underneath actually points to (confirmed: grepping the export
for any `href` containing `tab=` next to a heading anchor turns up nothing,
even for a document known to have real, working tab-qualified links) — so
the export is fine for confirming a heading exists, but not for reading back
the string a working link needs.

**Confirmed live: pasting `[text](?tab=t.<tabhash>#heading=h.<headinghash>)`
as Markdown DOES produce a working link**, indistinguishable from one made
through the UI (same blue-highlight-on-click navigation). Get the tab hash
from a real working link already in the document (Insert > Link on an
existing native link, or ask whoever's editing to paste one example URL) —
it's the same for every heading within one tab, so one example is enough to
construct every other link in that tab. Get each heading hash from the
`/mobilebasic` export's `id="h.xxxxx"` attributes (still valid for this
purpose) or from the TOC/cross-reference links already in the doc.

**Verifying a set of internal links is intact:** pulling every `href="#..."`
in a section against every `id="..."` in the doc catches an outright
orphaned reference (the target heading was deleted and recreated rather than
edited in place, which mints a new random hash and strands every old link
pointing at the original one) — worth doing, but remember it only proves the
*heading* exists, not that a given pasted link string had the right
`?tab=...#heading=h....` shape to actually navigate.

```python
import re
html = open('export.html', encoding='utf-8', errors='replace').read()
hrefs = set(re.findall(r'href="(#[^"]*)"', html))
ids = set('#' + m for m in re.findall(r'id="([^"]+)"', html))
print('orphaned:', [h for h in hrefs if h not in ids])
```

A doc using multiple tabs/sub-tabs is a separate, real cause of "the link
does nothing" worth ruling out too: a bookmark's scroll-to-heading behavior
may not visibly fire if the target heading lives in a different tab than the
one currently open, independent of whether the link itself is the right type.

## Automating a real paste into Google Docs: what does and doesn't work

Unlike Slack's Quill editor (which sdraft drives by dispatching a synthetic
`ClipboardEvent` directly), **Google Docs silently ignores a scripted paste
event.** Docs' hidden input target is a `contenteditable` inside
`document.querySelector('.docs-texteventtarget-iframe').contentDocument` —
you can find it and dispatch a well-formed `new ClipboardEvent('paste',
{clipboardData, bubbles: true, cancelable: true})` on it and the call
succeeds (`dispatchEvent` returns `true`, nothing throws), but nothing gets
inserted. The likely cause is Docs checking `event.isTrusted`, which a
JS-constructed event never has, unlike Slack's paste handler which doesn't
check it.

**CDP's `Input.dispatchKeyEvent` sending a real Cmd+V combo is not reliable
either.** Sending `keyDown`/`keyUp` for `Meta` and `v` with the right
modifiers and `commands: ['paste']` produced no error and no result — CDP key
events don't reliably trigger the OS-level clipboard access a genuine paste
needs.

**Real OS-level keystroke injection (`osascript`/System Events) can work, but
targeting is unreliable and the blast radius is real.** `tell application
"Google Chrome" to activate` plus `tell application "System Events" to
keystroke "v" using command down` sends a genuine, trusted keystroke — but
`activate` brings the *application* forward, not necessarily the *tab* (or
even the *window*) meant, and `System Events`' window-title reporting can be
stale or return a different window than whatever CDP's `Page.bringToFront`
just switched to internally. On a machine with multiple real Chrome windows
open (a mail client, other docs, dashboards), this risks sending a real
keystroke into someone else's live window. Verify with a screenshot
(`Page.captureScreenshot`) and cross-check window/tab lists (`/json/list`,
`tell application "System Events" to ... get name of every window`) before
trusting it landed where intended, and stop rather than retry blindly if the
state is ambiguous — worst case with Docs specifically is low (auto-save
means a stray keystroke in the wrong *document* doesn't destroy anything, but
it can still leave a mess to clean up, or land in an unrelated app's window
like a mail draft).

**What reliably works: CDP's `Input.insertText`, scoped to the tab's own CDP
target.** This is real character insertion (used by browser automation/test
frameworks generally) and Docs accepts it as legitimate input with no
`isTrusted` problem, no OS-level window targeting, no ambiguity about which
tab receives it — the CDP session is already bound to one specific target.
Click into the editor first via `Input.dispatchMouseEvent` (mousePressed +
mouseReleased at the editor's bounding-rect coordinates, found via
`document.querySelector('.kix-appview-editor').getBoundingClientRect()`),
then `Input.insertText({text: '...'})`. **But this simulates typing, not
pasting** — it does not trigger Docs' paste-specific markdown conversion (see
above), so it's useful for inserting literal text or driving a controlled
experiment, not for reproducing what a human's real clipboard paste will do.

**Net effect: there is no fully faithful way to automate "paste this Markdown
into Docs and get the converted result" from this environment.** The
practical split: automation generates content and puts it on the real OS
clipboard (`pbcopy`) for a human to paste with a real Cmd+V, and automation's
role on the read side is exporting via `/mobilebasic` afterward to verify
what actually landed — not performing the paste itself.
