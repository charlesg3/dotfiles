# Dotfiles

Personal shell and tool configuration files for macOS and Linux.

## What this is

This repo manages dotfiles and installs CLI tools via `install.sh`. It symlinks configs for zsh, bash, git, kitty, and nvim.

## Commits

- Do not add `Co-Authored-By: Claude` or any AI attribution to commit messages.

## Philosophy

- **Always up to date**: `install.sh` and `update.sh` pull the latest versions of everything — packages, submodules, and tools. Prefer `--remote` submodule updates over pinned SHAs.
- **Clean output**: all scripts use the helpers from `common.sh` (`ok`, `warn`, `err`, `header`, `_spin`/`_clear_spin`). Never redefine these inline; never emit raw git/brew/apt noise to the user.
- **Cross-platform**: all changes should work on both macOS and Linux. Use `$OSTYPE == darwin*` (zsh) or `$(uname) == Darwin` (bash) for OS-specific branches.
- **Both shells**: changes to shell config go in both `zsh/zshrc` and `bash/bashrc`.

## Key files

| File | Purpose |
|------|---------|
| `install.sh` | Main setup — symlinks, packages, nvim, Claude hooks, OS-specific. Safe to re-run. |
| `install_nvim.sh` | Pull latest nvim submodule, symlink `~/.config/nvim`, update plugins, optionally install deps. |
| `update.sh` | Update all tools to latest (brew/apt packages, nvim, plugins, ble.sh, kitty). |
| `common.sh` | Shared output helpers sourced by every install/update script. |
| `install-macos.sh` | macOS-specific installs (Homebrew, apps, icon swap). |
| `install-linux.sh` | Linux-specific installs (ble.sh, Kitty, Docker). |
| `scripts/copy-to` | Rsync full dotfiles tree (incl. `.git`) to a remote machine. |

## Adding things

- **New CLI tool**: add `install_pkg <name>` to `install.sh` and the package name to the appropriate array in `update.sh`.
- **Out-of-band tool** (GitHub release / curl install): add install logic to `install.sh` or `install-{macos,linux}.sh` and an update block to `update.sh`.

## Neovim

`nvim/` is a git submodule pointing to `charlesg3/nvim.git`. It is symlinked to `~/.config/nvim` by `install_nvim.sh`. Plugins are nested git submodules under `nvim/bundle/` (pathogen-style).

Both repos can be used independently: the nvim repo works standalone; dotfiles just orchestrates it.

### Scripts

| Script | Purpose |
|--------|---------|
| `install_nvim.sh` | Pull latest nvim submodule → symlink → update all plugins → commit SHAs. Called by `install.sh`. Pass `--nvim` to `install.sh` to also run system deps. |
| `nvim/scripts/install.sh` | Install system deps (ctags, node, tree-sitter, parsers, Nerd Font). Flags: `--python`, `--clojure`, `--go`. |
| `nvim/scripts/update.sh` | Update nvim binary + plugins, commit to nvim repo, bump dotfiles pointer. Called by `update.sh`. |
| `nvim/scripts/package.sh` | Create a self-contained `.tar.gz` for distribution without git access. |
| `nvim/scripts/common.sh` | Same helpers as `common.sh` — sourced by nvim scripts for standalone use. |

### Guidelines

- **nvim is a submodule**: changes to nvim config are committed in `nvim/` and pushed to `charlesg3/nvim.git`. Then dotfiles tracks the new pointer.
- **Plugins are submodules**: add/remove plugins with `git submodule add/deinit` under `nvim/bundle/`.
- **Prefer editing `nvim/init.vim`** for global config. Use `nvim/after/ftplugin/<ft>.lua` for filetype-specific Lua.

### Custom configurations

- **Taglist / outline** (`<C-e>`): symbol outline sidebar via universal-ctags. YAML overridden in `after/ftplugin/yaml.lua` with a treesitter outline.
- **nvim-tree** (`<C-t>`): file explorer; always synced to current file.
- **EasyMotion** (`s`): 2-char jump to any visible location across all panes.
- **render-markdown**: rich Markdown rendering in normal mode.
- **ALE**: linting on save. LSP navigation via `gd`, `gr`, `gh`.
- **Clojure / REPL**: fireplace + paredit. `<C-s>e` sends s-expression; `<C-s>s` sends selection.
- **Treesitter parsers**: installed to `~/.local/share/nvim/site/parser/`. Currently: `markdown`, `markdown_inline`, `yaml`.

### Keymap reference

`nvim/doc/keymap.md` — opened with `km` inside nvim. Regenerate whenever key bindings change.
