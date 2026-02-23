#!/usr/bin/env bash
# Installs macOS-specific tools and apps via Homebrew.
#
# Usage:
#   ./install-macos.sh

set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
. "$DOTFILES/common.sh"

brew_install() {
    local pkg="$1"
    if brew list --formula "$pkg" &>/dev/null; then
        ok "$pkg"
    else
        warn "Installing $pkg..."
        brew install "$pkg"
        ok "$pkg installed"
    fi
}

cask_install() {
    local pkg="$1"
    if brew list --cask "$pkg" &>/dev/null; then
        ok "$pkg"
    else
        warn "Installing $pkg..."
        brew install --cask "$pkg"
        ok "$pkg installed"
    fi
}

# ── Homebrew ──────────────────────────────────────────────────────────────────

if ! command -v brew &>/dev/null; then
    warn "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# ── CLI tools ─────────────────────────────────────────────────────────────────

header "CLI tools"
brew_install ripgrep
brew_install tree
brew_install watch
brew_install coreutils
brew_install glow
brew_install git-lfs

# ── GitHub / GitLab ───────────────────────────────────────────────────────────

header "GitHub / GitLab"
brew_install gh
brew_install glab

# ── Apps ──────────────────────────────────────────────────────────────────────

header "Apps"
cask_install iterm2
cask_install stats

# ── Done ──────────────────────────────────────────────────────────────────────

echo -e "\n${BOLD}${GREEN}Done!${RESET}"
