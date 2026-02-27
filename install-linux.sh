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

# ── ble.sh (bash syntax highlighting + autosuggestions) ──────────────────────

header "ble.sh"
if [ -f "$HOME/.local/share/blesh/ble.sh" ]; then
    ok "ble.sh"
else
    warn "Installing ble.sh..."
    tmp="$(mktemp -d)"
    curl -fsSL https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz \
        | tar xJf - -C "$tmp"
    bash "$tmp/ble-nightly/ble.sh" --install "$HOME/.local/share"
    rm -rf "$tmp"
    ok "ble.sh installed"
fi


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

# ── Fonts ─────────────────────────────────────────────────────────────────────

header "Fonts"
if dpkg -s fonts-jetbrains-mono &>/dev/null; then
    ok "fonts-jetbrains-mono"
else
    warn "Installing fonts-jetbrains-mono..."
    sudo apt-get install -y fonts-jetbrains-mono
    fc-cache -f
    ok "fonts-jetbrains-mono installed"
fi

# ── Docker ────────────────────────────────────────────────────────────────────

header "Docker"

if [[ ! -f /etc/apt/sources.list.d/docker.list ]]; then
    warn "Setting up Docker apt repository..."
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    . /etc/os-release
    sudo curl -fsSL "https://download.docker.com/linux/${ID}/gpg" \
        -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -q
    ok "Docker apt repository configured"
else
    ok "Docker apt repository"
fi

apt_install docker-ce
apt_install docker-ce-cli
apt_install containerd.io
apt_install docker-compose-plugin
apt_install docker-buildx-plugin

if ! groups "$USER" | grep -q docker; then
    warn "Adding $USER to docker group (re-login required)..."
    sudo usermod -aG docker "$USER"
    ok "$USER added to docker group"
else
    ok "$USER in docker group"
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo -e "\n${BOLD}${GREEN}Done!${RESET}"
