# Dotfiles

Personal shell and tool configuration files for macOS and Linux.

## What this is

This repo manages dotfiles and installs CLI tools via `install.sh`. It symlinks configs for zsh, bash, git, kitty, and nvim.

## Guidelines

- **Cross-platform**: all changes should work on both macOS and Linux where possible. Use OS checks (`$OSTYPE == darwin*` in zsh, `$(uname) == Darwin` in bash) when behavior must differ.
- **Both shells**: changes to shell config should be applied to both `zsh/zshrc` and `bash/bashrc`.
- **install.sh**: new CLI tool dependencies should be added to `install.sh` using the existing `install_pkg` helper, which handles both Homebrew and apt.
- **update.sh**: tools installed out-of-band (not via brew/apt) must also be updated in `update.sh`. This includes GitHub release downloads (e.g. ble.sh) and curl-installed tools (e.g. kitty on Linux). Brew/apt packages are also updated here by name.
- **common.sh**: shared helpers (`ok`, `warn`, `err`, `header`, `_spin`, `_clear_spin`) sourced by all install scripts. Add shared utilities here; do not redefine them inline.

## Neovim

Config lives in `nvim/` and is symlinked to `~/.config/nvim` by `install_nvim.sh`. Plugins are tracked as git submodules under `nvim/bundle/` (pathogen-style). Config is primarily Vimscript (`nvim/init.vim`) with Lua in `nvim/after/ftplugin/` for filetype-specific behaviour.

### Scripts

| Script | Purpose |
|--------|---------|
| `install_nvim.sh` | Symlink `nvim/` → `~/.config/nvim`, update all plugins to remote HEAD, commit any SHA changes, then run `nvim/scripts/install.sh`. Run via `install.sh --nvim`. |
| `nvim/scripts/install.sh` | Install system dependencies (ctags, node, tree-sitter CLI, treesitter parsers, Nerd Font). Flags: `--python`, `--clojure`, `--go` for language-specific extras. |
| `nvim/scripts/update.sh` | Update nvim binary and all submodule plugins to latest, then commit pinned SHAs. |
| `nvim/scripts/copy-to.sh [user@host]` | Rsync the full config to a remote machine. |
| `nvim/scripts/package.sh` | Create a self-contained `.tar.gz` for distribution. |
| `nvim/scripts/copy-from.sh` | Pull config back from a remote machine. |

### Guidelines

- **Plugins are submodules**: adding or removing a plugin means `git submodule add/deinit` under `nvim/bundle/`, not copying files.
- **Prefer editing `nvim/init.vim`** for global config. Use `nvim/after/ftplugin/<ft>.lua` for filetype-specific Lua.

### Custom configurations

- **Taglist / outline** (`<C-e>`): toggles a symbol outline sidebar. Uses universal-ctags with custom settings for Clojure and Markdown. For YAML files overridden in `nvim/after/ftplugin/yaml.lua` with a treesitter-based outline.
- **nvim-tree** (`<C-t>`): file explorer; `update_focused_file` keeps tree in sync with current file.
- **EasyMotion** (`s`): 2-char jump to any visible location across all panes.
- **render-markdown**: rich Markdown rendering in normal mode.
- **ALE**: linting on save (not on text change). LSP navigation via `gd`, `gr`, `gh`.
- **Clojure / REPL**: fireplace + paredit. `<C-s>e` sends s-expression to REPL; `<C-s>s` sends visual selection.
- **Treesitter parsers**: installed to `~/.local/share/nvim/site/parser/`. Currently: `markdown`, `markdown_inline`, `yaml`.

### Keymap reference

`nvim/doc/keymap.md` is the human-readable keymap reference, opened with `km` inside nvim. **Regenerate it whenever key bindings change.**
