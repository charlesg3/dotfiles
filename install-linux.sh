#!/usr/bin/env bash
# Installs Linux-specific tools.
#
# Usage:
#   ./install-linux.sh

set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
. "$DOTFILES/common.sh"

if ! command -v apt-get &>/dev/null; then
    err "This script requires apt-get"
    exit 1
fi

apt_install() {
    local pkg="$1"
    if dpkg -s "$pkg" &>/dev/null; then
        ok "$pkg"
    else
        warn "Installing $pkg..."
        sudo apt-get install -y "$pkg"
        ok "$pkg installed"
    fi
}

# ── Clipboard ─────────────────────────────────────────────────────────────────

header "Clipboard"
apt_install xclip

# ── Kitty ─────────────────────────────────────────────────────────────────────

header "Kitty"
if command -v kitty &>/dev/null; then
    ok "kitty"
else
    warn "Installing kitty..."
    curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
    sudo ln -sf "$HOME/.local/kitty.app/bin/kitty" /usr/local/bin/kitty
    ok "kitty installed"
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo -e "\n${BOLD}${GREEN}Done!${RESET}"
