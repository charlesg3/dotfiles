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

A background watcher on an open MR that carries it through review and merge with
minimal babysitting. Armed with the `Monitor` tool running a polling script,
persistent, ~90s poll. It emits an event line only on state changes, and each
event re-invokes Claude to act. Site notes hold the script path and the default
project.

**Post-merge watching only applies where the target branch runs push pipelines.**
Trunk usually does; release branches often don't, and the pipelines attached to
their commits are merge-request-event runs on a train ref. A backport merged
*through a train* therefore has a pipeline at its final sha, because the train
ref's sha becomes the merged commit; one merged *directly* has none and never
will. So the same script can look fine on one release backport and hang after
`[merged]` on the next. Stop at `[merged]` when the target isn't trunk, and
verify by reading the file at the branch ref instead:
`git show origin/<branch>:<path> | grep <the change>`.

Events and the response to each:

- `[note] <author>: ...` — a real comment, from a human or from a bot that posts
  findings; author is not filtered, because a review bot's comment is as
  actionable as a person's. If it's a question or an easy fix, address it: reply
  on the discussion and resolve the thread once answered. If it asks for a real
  design change or is ambiguous, surface it to the human instead of acting.
- `[event] <author>: ...` — the system notes worth reacting to: approvals and
  unapprovals, new or force-pushed commits, draft/ready flips, thread
  resolution, target-branch changes, and auto-merge arm/abort. An approval is a
  system note, so suppressing all of them leaves the monitor blind to one
  landing. The remaining system notes (labels, assignees, milestones, title and
  description edits, review requests, "mentioned in") stay suppressed as noise.
- `[pipeline] X -> Y` — CI state change. Informational.
- `[merge-status] X -> Y` — mergeability changed. This is the signal that
  catches a merge train dropping the MR: the train runs its own pipeline against
  a train ref, which is not the MR's head pipeline, so a drop is otherwise
  invisible. Transient `checking`/`unchecked`/`preparing` transitions are
  suppressed.
- `[job-failed] <id>|<name>|allow_failure=..|<url>` — judge flaky vs real. If
  flaky/infra (network, timeout, known-flaky), retry the job. If a real failure,
  fix it (spawn a coding agent, verify, push); don't land until green.
- `[ready-to-merge]` — CI green, approved, discussions resolved, no conflicts.
  Land it. Where the project uses merge trains, the merge call adds it to the
  train; API-created MRs need `squash=true` or the train drops them
  ("Unexpected commit SHA in train ref").
- `[merged] <sha>` — merged. `<sha>` is the commit that landed on the target
  branch, which with ff plus squash merge trains is the squash commit: the merge
  commit sha is null under that config, and the MR's own sha is the branch head,
  which has no target-branch pipeline. The monitor doesn't exit here; it switches
  to watching that commit's pipeline.
- `[post-pipeline] X -> Y`, `[post-job-failed] <id>|<name>|allow_failure=..|<url>`,
  `[post-failed] <sha> ...` — the merge commit's pipeline on the target branch.
  Treat failures exactly as pre-merge: retry flaky/infra jobs, fix real ones.
  Landing a merge is not the same as landing it green, and a red trunk is not
  something to discover later. `[post-failed]` keeps polling rather than
  exiting, so a retry is picked up.
- `[post-green] <sha>` — the target-branch pipeline for the merge commit is
  green. The monitor exits here. Follow with whatever behavior test the change
  calls for.

Escalate to the human rather than acting autonomously for: design-change
requests, merge conflicts needing judgment, or failures whose fix is not
obvious.

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
