#!/usr/bin/env bash
# Updates all tools managed by this dotfiles repo.
# Safe to run repeatedly.
#
# Usage:
#   ./update.sh

set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
. "$DOTFILES/common.sh"

BREW_PKGS=(jq tree htop ncdu colordiff bat eza zsh-autosuggestions zsh-syntax-highlighting glow gh vault)
BREW_CASKS=(docker)
APT_PKGS=(jq tree htop ncdu colordiff bat eza xclip zsh-autosuggestions zsh-syntax-highlighting glow gh vault docker-ce docker-ce-cli)

# ── Homebrew (macOS) ──────────────────────────────────────────────────────────

if command -v brew &>/dev/null; then
    header "Homebrew"
    warn "Fetching updates..."
    brew update -q
    for pkg in "${BREW_PKGS[@]}"; do
        brew list --formula "$pkg" &>/dev/null || continue
        brew upgrade "$pkg" 2>/dev/null && ok "$pkg updated" || ok "$pkg"
    done
    for cask in "${BREW_CASKS[@]}"; do
        brew list --cask "$cask" &>/dev/null || continue
        brew upgrade --cask "$cask" 2>/dev/null && ok "$cask updated" || ok "$cask"
    done
fi

# ── apt (Linux) ───────────────────────────────────────────────────────────────

if command -v apt-get &>/dev/null; then
    header "apt"
    warn "Fetching updates..."
    sudo apt-get update -q
    for pkg in "${APT_PKGS[@]}"; do
        dpkg -s "$pkg" &>/dev/null || continue
        sudo apt-get install -y --only-upgrade "$pkg" && ok "$pkg" || true
    done
fi

# ── ble.sh (GitHub nightly) ───────────────────────────────────────────────────

if [[ -f "$HOME/.local/share/blesh/ble.sh" ]]; then
    header "ble.sh"
    warn "Updating ble.sh..."
    tmp="$(mktemp -d)"
    curl -fsSL https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz \
        | tar xJf - -C "$tmp"
    bash "$tmp/ble-nightly/ble.sh" --install "$HOME/.local/share/blesh"
    rm -rf "$tmp"
    ok "ble.sh updated"
fi

# ── Kitty (Linux) ─────────────────────────────────────────────────────────────

if command -v kitty &>/dev/null && [[ "$(uname)" == "Linux" ]]; then
    header "Kitty"
    warn "Updating kitty..."
    kitty +update-kitty || true
    ok "kitty"
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo -e "\n${BOLD}${GREEN}Done!${RESET}"
