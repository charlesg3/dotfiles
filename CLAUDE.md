# Dotfiles

Personal shell and tool configuration files for macOS and Linux.

## What this is

This repo manages dotfiles and installs CLI tools via `install.sh`. It symlinks configs for zsh, bash, git, kitty, and nvim.

## Guidelines

- **Cross-platform**: all changes should work on both macOS and Linux where possible. Use OS checks (`$OSTYPE == darwin*` in zsh, `$(uname) == Darwin` in bash) when behavior must differ.
- **Both shells**: changes to shell config should be applied to both `zsh/zshrc` and `bash/bashrc`.
- **install.sh**: new CLI tool dependencies should be added to `install.sh` using the existing `install_pkg` helper, which handles both Homebrew and apt.
- **update.sh**: tools installed out-of-band (not via brew/apt) must also be updated in `update.sh`. This includes GitHub release downloads (e.g. ble.sh) and curl-installed tools (e.g. kitty on Linux). Brew/apt packages are also updated here by name.

## Related repos

- **Neovim config**: https://github.com/charlesg3/nvim.git — installed to `~/.config/nvim` via `install.sh --nvim`
