# Tmux Session Resume System

This system allows you to save and resume tmux sessions with their Claude context preserved.

## How it works

### Components

1. **tmux-resume** — Starts or resumes a tmux session from saved configuration
   - Looks for `sessions/win-*.json` files and restores them in `.index` order
   - If a session already exists, attaches to it
   - If not, creates a new session with all windows and runs the saved commands
   - If no config found, creates an empty session

2. **tmux-tab-hook** — Captures the current tmux tab state when Claude runs
   - Called via Claude hooks (SessionStart, etc.)
   - Updates the `sessions/win-*.json` file bound to this window, or creates one
   - Detects if running in vim/nvim and modifies the command accordingly
   - Includes the Claude session ID in the command so the session can be resumed

3. **tmux-sync-tabs** — Reconciles the saved files against tmux's live windows
   - Run from the `window-renamed`, `window-linked` and `window-unlinked` hooks in `tmux.conf`
   - Matches each file to a window by its `window_id` field, then updates `name`, `cwd` and `index`
   - Leaves `command` and `claude_session_id` alone: only the Claude hook can produce them
   - Deletes the file when a window this server handed out is gone, which means the user closed it
   - After a server restart the saved ids belong to a dead server, so it rebinds by `index` and deletes nothing

4. **claude-tmux-hook** — Bridge between Claude's hook system and tmux-tab-hook
   - Reads Claude hook JSON input from stdin
   - Extracts session ID and working directory
   - Calls tmux-tab-hook with this information

### Configuration

**Option 1: Automatic installation (recommended)**

```bash
~/src/dotfiles/tmux/tmux-resume install
```

This will:
- Check your `~/.claude/settings.json`
- Create a backup (`settings.json.backup`)
- Add `claude-tmux-hook` to the SessionStart hooks
- Verify the installation

**Option 2: Manual installation**

Add this to the `SessionStart` hooks in `~/.claude/settings.json`:

```json
{
  "type": "command",
  "command": "~/src/dotfiles/tmux/claude-tmux-hook"
}
```

### Usage

#### First-time setup

Install the Claude hook:

```bash
~/src/dotfiles/tmux/tmux-resume install
```

This adds the capture hook to `~/.claude/settings.json` and creates a backup.

#### Starting a new session with resume capability

```bash
# Just use tmux-resume instead of tmux new-session
~/src/dotfiles/tmux/tmux-resume

# Or specify a session name
~/src/dotfiles/tmux/tmux-resume my-session
```

#### Add to your shell config

Add to `~/.zshrc` or `~/.bashrc`:

```bash
alias tmux-resume='~/src/dotfiles/tmux/tmux-resume'
```

Then use:

```bash
tmux-resume
tmux-resume my-project
```

#### What gets saved

When Claude starts in a tmux window, this information is saved to its `sessions/win-*.json` file:

```json
{
  "name": "main",
  "cwd": "/home/user/project",
  "index": 3,
  "window_id": "@2",
  "server_pid": 5893,
  "server_start": "Mon Aug 3 19:55:14 2026",
  "command": "claude --dangerously-skip-permissions --resume abc123def",
  "claude_session_id": "abc123def",
  "timestamp": "2026-08-07T16:00:00Z"
}
```

`command` and `claude_session_id` are only present for windows that ran Claude.

### Session files

One file per window, in `~/src/dotfiles/tmux/sessions/`, named
`win-<epoch>-<rand>.json`. The name is assigned when the file is created and
never changes, so nothing that happens to a window can make a file name wrong.

Three fields do the work the file name used to do:

- `window_id` binds the file to a live window (`@2`). tmux hands these out from
  `@0` again after a server restart, so it is rebindable.
- `server_pid` and `server_start` say which tmux server handed that id out. A
  pid on its own is not enough: pids are recycled, and a new server could get
  the old one.
- `index` is where the window sat, and is what orders a restore.

Naming the files by index instead meant a window that moved took some other
window's file, and with it some other window's Claude session. Naming them by
window id would have gone stale wholesale on every server restart.

### When a file is deleted

A window closing and the tmux server dying look the same from the file: the
saved `window_id` stops resolving. They need opposite treatment, so the server
recorded in the file decides which happened.

- Same server, id gone: the user closed that window. The file is deleted, so
  the window does not come back on the next resume.
- Different server, or no server recorded: the ids belong to a server that is
  gone. Every file is rebound by `index` and none is deleted, which is the
  machine-restart case the tool exists for.

Counting how many ids still resolve cannot separate the two: closing the only
window with a file leaves zero resolving, exactly as a restart does.

A closed window's Claude conversation is not lost with its file. Conversations
live in `~/.claude/projects/<project>/<session-id>.jsonl`; these files only
record how to relaunch one.

### Vim integration

If Claude is running inside nvim (via `vim-claude`), the saved command will be:

```
nvim -c "rightbelow vsplit | terminal claude --dangerously-skip-permissions --resume abc123def" -c "startinsert"
```

This ensures that when the session is resumed, Claude opens in the same vim split layout.

### Example workflow

1. Start a new tmux session with resume capability:
   ```bash
   tmux-resume main
   ```

2. Open a new window in the session:
   ```bash
   tmux new-window -n work
   ```

3. Start Claude in one of the windows (either via `claude` or `vim-claude`)

4. Claude's SessionStart hook automatically captures the window state and saves it

5. Later, if the tmux session dies or you close it, restore everything:
   ```bash
   tmux-resume main
   ```

6. All windows, directories, and Claude sessions (including the specific session ID) are restored

## Troubleshooting

### Sessions aren't being saved

- Check that you're using Claude's CLI in a tmux session
- Verify the hook is configured: `~/.claude/settings.json` should include the `claude-tmux-hook`
- Check that `~/src/dotfiles/tmux/sessions/` directory exists and is writable

### Resume not working

- Verify the session files exist: `ls ~/src/dotfiles/tmux/sessions/win-*.json`
- Check the contents: `jq . ~/src/dotfiles/tmux/sessions/win-*.json`
- Ensure tmux is installed and working

### Session ID not captured

- The hook runs when Claude starts; make sure Claude is actually running when you want to save state
- Check the hook output for errors (you can add debugging to the hook scripts)

## Architecture notes

- The system uses jq for JSON parsing, so jq must be installed
- Works on both macOS and Linux (uses POSIX sh/bash)
- Session files are plain JSON and can be edited manually
- The system is designed to be non-intrusive — it won't break if something goes wrong

## Future enhancements

Possible improvements:
- Auto-save on Stop/SessionEnd hooks in addition to SessionStart
- Web interface to view/manage saved sessions
- Integration with tmux session list commands
- Snapshot of pane contents (for reference when resuming)
- Support for pane layouts (not just windows)
