#!/usr/bin/env bash
# Sets up dotfiles on a new machine.
#
# Usage:
#   ./install.sh [--nvim]
#
# Flags:
#   --nvim   Also clone and set up the nvim config

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
INSTALL_NVIM=false

for arg in "$@"; do
    case $arg in
        --nvim) INSTALL_NVIM=true ;;
        *)
            echo -e "${RED}Unknown option: $arg${RESET}"
            echo "Usage: $0 [--nvim]"
            exit 1
            ;;
    esac
done

link() {
    local src="$1"
    local dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        echo -e "  ${YELLOW}~${RESET} $dst exists (not a symlink), backing up to ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi
    ln -sf "$src" "$dst"
    echo -e "  ${GREEN}✓${RESET} $dst"
}

# ── Shell ─────────────────────────────────────────────────────────────────────

echo -e "${BOLD}${CYAN}Shell${RESET}"
link "$DOTFILES/zsh/zshrc"    "$HOME/.zshrc"
link "$DOTFILES/zsh/zprofile" "$HOME/.zprofile"
link "$DOTFILES/bash/bashrc"  "$HOME/.bashrc"

# ── Git ───────────────────────────────────────────────────────────────────────

echo -e "\n${BOLD}${CYAN}Git${RESET}"
read -r -p "  Git email address [charlesg3@gmail.com]: " GIT_EMAIL
GIT_EMAIL="${GIT_EMAIL:-charlesg3@gmail.com}"

sed "s/YOUR_EMAIL_HERE/$GIT_EMAIL/" "$DOTFILES/git/gitconfig" > "$HOME/.gitconfig"
echo -e "  ${GREEN}✓${RESET} ~/.gitconfig (email: $GIT_EMAIL)"

# ── Nvim ──────────────────────────────────────────────────────────────────────

if [[ "$INSTALL_NVIM" == true ]]; then
    echo -e "\n${BOLD}${CYAN}Nvim${RESET}"
    NVIM_DIR="$HOME/.config/nvim"
    if [ -d "$NVIM_DIR" ]; then
        echo -e "  ${GREEN}✓${RESET} $NVIM_DIR already exists"
    else
        echo -e "  ${YELLOW}~${RESET} Cloning nvim config..."
        git clone --depth=1 https://github.com/charlesg3/nvim "$NVIM_DIR"
        echo -e "  ${GREEN}✓${RESET} nvim config cloned"
    fi
    if [ -f "$NVIM_DIR/scripts/install.sh" ]; then
        echo -e "  ${YELLOW}~${RESET} Running nvim install.sh..."
        bash "$NVIM_DIR/scripts/install.sh"
    fi
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo -e "\n${BOLD}${GREEN}Done!${RESET}"
