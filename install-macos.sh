#!/usr/bin/env bash
# Installs macOS-specific tools and apps via Homebrew.
#
# Usage:
#   ./install-macos.sh

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RESET='\033[0m'

brew_install() {
    local pkg="$1"
    if brew list --formula "$pkg" &>/dev/null; then
        echo -e "  ${GREEN}✓${RESET} $pkg"
    else
        echo -e "  ${YELLOW}~${RESET} Installing $pkg..."
        brew install "$pkg"
        echo -e "  ${GREEN}✓${RESET} $pkg installed"
    fi
}

cask_install() {
    local pkg="$1"
    if brew list --cask "$pkg" &>/dev/null; then
        echo -e "  ${GREEN}✓${RESET} $pkg"
    else
        echo -e "  ${YELLOW}~${RESET} Installing $pkg..."
        brew install --cask "$pkg"
        echo -e "  ${GREEN}✓${RESET} $pkg installed"
    fi
}

# ── Homebrew ──────────────────────────────────────────────────────────────────

if ! command -v brew &>/dev/null; then
    echo -e "${YELLOW}~${RESET} Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# ── CLI tools ─────────────────────────────────────────────────────────────────

echo -e "${BOLD}${CYAN}CLI tools${RESET}"
brew_install ripgrep
brew_install tree
brew_install watch
brew_install coreutils
brew_install glow
brew_install git-lfs

# ── GitHub / GitLab ───────────────────────────────────────────────────────────

echo -e "\n${BOLD}${CYAN}GitHub / GitLab${RESET}"
brew_install gh
brew_install glab

# ── Apps ──────────────────────────────────────────────────────────────────────

echo -e "\n${BOLD}${CYAN}Apps${RESET}"
cask_install iterm2
cask_install stats

# ── Done ──────────────────────────────────────────────────────────────────────

echo -e "\n${BOLD}${GREEN}Done!${RESET}"
