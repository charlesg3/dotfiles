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
brew_install git-lfs
brew_install docker-buildx
mkdir -p "$HOME/.docker/cli-plugins"
ln -sfn "$(brew --prefix)/opt/docker-buildx/bin/docker-buildx" \
    "$HOME/.docker/cli-plugins/docker-buildx"
ok "docker-buildx cli plugin linked"

# ── GitHub / GitLab ───────────────────────────────────────────────────────────

header "GitHub / GitLab"
brew_install gh
brew_install glab

# ── Apps ──────────────────────────────────────────────────────────────────────

header "Apps"
cask_install iterm2
cask_install kitty
cask_install stats

# ── iTerm2 ────────────────────────────────────────────────────────────────────

header "iTerm2"
ITERM_PROFILES="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
mkdir -p "$ITERM_PROFILES"
ln -sf "$DOTFILES/iterm2/Dotfiles.json" "$ITERM_PROFILES/Dotfiles.json"
ok "Dynamic profile linked"
defaults write com.googlecode.iterm2 "Default Bookmark Guid" "com.charlesg3.dotfiles"
ok "Default profile set to charlesg3"

# ── Stats ─────────────────────────────────────────────────────────────────────

header "Stats"
if [[ -d "/Applications/Stats.app" ]]; then
    defaults import eu.exelban.Stats "$DOTFILES/stats/Stats.plist"
    ok "Stats preferences imported"
    osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Stats.app", hidden:false}' &>/dev/null
    ok "Stats set to launch at login"
else
    warn "Stats.app not found, skipping"
fi

# ── Kitty ─────────────────────────────────────────────────────────────────────

header "Kitty"
brew_install fileicon
if [[ -d "/Applications/kitty.app" ]]; then
    fileicon set /Applications/kitty.app \
        /System/Applications/Utilities/Terminal.app
    if [[ $? -eq 0 ]]; then
        ok "Kitty icon set to Terminal icon"
    else
        warn "Kitty icon swap failed."
    fi
else
    warn "kitty.app not found, skipping icon swap"
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo -e "\n${BOLD}${GREEN}Done!${RESET}"
