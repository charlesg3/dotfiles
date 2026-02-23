#!/usr/bin/env bash
# Sets up dotfiles on a new machine.
#
# Usage:
#   ./install.sh [--nvim] [--email EMAIL]
#
# Flags:
#   --nvim         Also clone and set up the nvim config
#   --email EMAIL  Git email address (skips interactive prompt)

set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
. "$DOTFILES/common.sh"

INSTALL_NVIM=false
GIT_EMAIL=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --nvim)        INSTALL_NVIM=true ;;
        --email)       GIT_EMAIL="$2"; shift ;;
        --email=*)     GIT_EMAIL="${1#--email=}" ;;
        *)
            err "Unknown option: $1"
            echo "Usage: $0 [--nvim] [--email EMAIL]"
            exit 1
            ;;
    esac
    shift
done

link() {
    local src="$1"
    local dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        warn "$dst exists (not a symlink), backing up to ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi
    ln -sf "$src" "$dst"
    ok "$dst"
}

# ── Shell ─────────────────────────────────────────────────────────────────────

header "Shell"
link "$DOTFILES/zsh/zshrc"    "$HOME/.zshrc"
link "$DOTFILES/zsh/zprofile" "$HOME/.zprofile"
link "$DOTFILES/bash/bashrc"  "$HOME/.bashrc"

# ── Git ───────────────────────────────────────────────────────────────────────

header "Git"
if [[ -z "$GIT_EMAIL" ]]; then
    read -r -p "  Git email address [charlesg3@gmail.com]: " GIT_EMAIL
fi
GIT_EMAIL="${GIT_EMAIL:-charlesg3@gmail.com}"
sed "s/YOUR_EMAIL_HERE/$GIT_EMAIL/" "$DOTFILES/git/gitconfig" > "$HOME/.gitconfig"
ok "~/.gitconfig (email: $GIT_EMAIL)"

# ── GitHub CLI ────────────────────────────────────────────────────────────────

header "GitHub CLI"
if command -v gh &>/dev/null; then
    ok "gh"
elif command -v apt-get &>/dev/null; then
    warn "Installing gh via apt..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update -q && sudo apt-get install -y gh
    ok "gh installed"
else
    warn "gh: no supported package manager — install manually from https://cli.github.com"
fi

# ── Nvim ──────────────────────────────────────────────────────────────────────

if [[ "$INSTALL_NVIM" == true ]]; then
    header "Nvim"
    NVIM_DIR="$HOME/.config/nvim"
    if [ -d "$NVIM_DIR" ]; then
        ok "$NVIM_DIR already exists"
    else
        warn "Cloning nvim config..."
        git clone --recurse-submodules --depth=1 --shallow-submodules https://github.com/charlesg3/nvim.git "$NVIM_DIR"
        ok "nvim config cloned"
    fi
    if [ -f "$NVIM_DIR/scripts/install.sh" ]; then
        warn "Running nvim install.sh..."
        bash "$NVIM_DIR/scripts/install.sh"
    fi
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo -e "\n${BOLD}${GREEN}Done!${RESET}"
