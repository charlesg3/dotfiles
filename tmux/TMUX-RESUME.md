# Tmux Session Resume System

This system allows you to save and resume tmux sessions with their Claude context preserved.

## How it works

### Components

1. **tmux-resume** — Starts or resumes a tmux session from saved configuration
   - Looks for `sessions/tab_X.json` files (where X is the tab number)
   - If a session already exists, attaches to it
   - If not, creates a new session with all windows and runs the saved commands
   - If no config found, creates an empty session

2. **tmux-tab-hook** — Captures the current tmux tab state when Claude runs
   - Called via Claude hooks (SessionStart, etc.)
   - Saves tab name, working directory, and resume command to `sessions/tab_X.json`
   - Detects if running in vim/nvim and modifies the command accordingly
   - Includes the Claude session ID in the command so the session can be resumed

3. **claude-tmux-hook** — Bridge between Claude's hook system and tmux-tab-hook
   - Reads Claude hook JSON input from stdin
   - Extracts session ID and working directory
   - Calls tmux-tab-hook with this information

### Configuration

The hook is already wired into `~/.claude/settings.json`:
- SessionStart hook calls `claude-tmux-hook` to capture tab state when Claude starts

### Usage

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

When Claude starts in a tmux window, this information is saved to `sessions/tab_X.json`:

```json
{
  "name": "main",
  "cwd": "/home/user/project",
  "command": "claude --dangerously-skip-permissions --session abc123def",
  "claude_session_id": "abc123def",
  "timestamp": "2026-08-07T16:00:00Z"
}
```

### Session files

Session configuration files are stored in:
- `~/src/dotfiles/tmux/sessions/tab_0.json` (first window)
- `~/src/dotfiles/tmux/sessions/tab_1.json` (second window)
- etc.

These are created automatically and can be manually edited if needed.

### Vim integration

If Claude is running inside nvim (via `vim-claude`), the saved command will be:

```
nvim -c "rightbelow vsplit | terminal claude --dangerously-skip-permissions --session abc123def" -c "startinsert"
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

- Verify the session file exists: `ls ~/src/dotfiles/tmux/sessions/tab_*.json`
- Check the contents: `cat ~/src/dotfiles/tmux/sessions/tab_0.json`
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
