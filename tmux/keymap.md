# Tmux Keymap Reference

Prefix is `Ctrl-b` (shown as `<p>`).

**Shell helpers:** `t [name]` — create or attach to a named session (default: `main`) · `tms` — same, named after current directory · `tmux-keys` — show this reference

---

## Sessions

| Key | Action |
|-----|--------|
| `<p> $` | Rename current session |
| `<p> s` | List / switch sessions |
| `<p> d` | Detach |

## Windows (tabs)

| Key | Action |
|-----|--------|
| `<p> c` | New window (current dir) |
| `<p> ,` | Rename window |
| `<p> n` | Next window |
| `<p> p` | Previous window |
| `<p> 1–9` | Jump to window N |
| `<p> w` | Interactive window list |
| `<p> &` | Kill window (with confirm) |

## Panes

| Key | Action |
|-----|--------|
| `<p> \|` | Split right |
| `<p> -` | Split down |
| `<p> h/j/k/l` | Navigate panes |
| `<p> H/J/K/L` | Resize pane 5 cells (repeatable) |
| `<p> z` | Zoom / unzoom pane |
| `<p> x` | Kill pane (with confirm) |
| `<p> {` / `}` | Swap pane left / right |
| `<p> q` | Show pane numbers, press number to jump |

## Copy mode (vi)

| Key | Action |
|-----|--------|
| `<p> Enter` | Enter copy mode |
| `q` / `Escape` | Exit |
| `v` | Begin selection |
| `C-v` | Rectangle selection |
| `y` | Yank → clipboard |
| `/` / `?` | Search forward / backward |
| `n` / `N` | Next / previous match |
| `gg` / `G` | Top / bottom of history |

## Misc

| Key | Action |
|-----|--------|
| `<p> r` | Reload `~/.tmux.conf` |
| `<p> :` | Command prompt |
| `<p> ?` | List all key bindings |
| `<p> t` | Show clock |
| `<p> C-b` | Send prefix to nested tmux |
