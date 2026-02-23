# dotfiles

Shell, git, and editor config for setting up a new machine.

## Quick start

```bash
git clone https://github.com/charlesg3/dotfiles ~/src/dotfiles
~/src/dotfiles/install.sh
```

Add `--nvim` to also clone and set up the nvim config:

```bash
~/src/dotfiles/install.sh --nvim
```

## What gets installed

| File | Destination |
|------|-------------|
| `zsh/zshrc` | `~/.zshrc` |
| `zsh/zprofile` | `~/.zprofile` |
| `git/gitconfig` | `~/.gitconfig` (email prompted) |

Shell files are symlinked so edits in `~/src/dotfiles` are reflected immediately.

## Machine-specific config

Anything not suitable for version control (work credentials, machine-specific paths, etc.) goes in `~/.zshrc.local` — it is sourced automatically at the end of `.zshrc` if it exists.
