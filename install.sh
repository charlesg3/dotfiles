#!/usr/bin/env bash
# Sets up and updates dotfiles on a machine. Safe to run repeatedly.
#
# Usage:
#   ./install.sh [--nvim] [--node] [--email EMAIL]
#
# Flags:
#   --nvim         Also install/update the nvim config
#   --node         Also install Node.js (LTS) and npm
#   --email EMAIL  Git email address (skips interactive prompt)

set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
. "$DOTFILES/common.sh"

INSTALL_NVIM=false
INSTALL_NODE=false
GIT_EMAIL=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --nvim)        INSTALL_NVIM=true ;;
        --node)        INSTALL_NODE=true ;;
        --email)       GIT_EMAIL="$2"; shift ;;
        --email=*)     GIT_EMAIL="${1#--email=}" ;;
        *)
            err "Unknown option: $1"
            echo "Usage: $0 [--nvim] [--node] [--email EMAIL]"
            exit 1
            ;;
    esac
    shift
done

install_pkg() {
    local pkg="$1"
    if command -v brew &>/dev/null; then
        brew list --formula "$pkg" &>/dev/null && ok "$pkg" || { warn "Installing $pkg..."; brew install "$pkg" && ok "$pkg installed"; }
    elif command -v apt-get &>/dev/null; then
        dpkg -s "$pkg" &>/dev/null && ok "$pkg" || { warn "Installing $pkg..."; sudo apt-get install -y "$pkg" && ok "$pkg installed"; }
    else
        warn "$pkg: no supported package manager"
    fi
}

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

# ── Self-update ───────────────────────────────────────────────────────────────

header "Dotfiles"
if git -C "$DOTFILES" pull --ff-only 2>/dev/null; then
    ok "dotfiles up to date"
else
    warn "could not pull dotfiles (offline or diverged?)"
fi

# ── Shell ─────────────────────────────────────────────────────────────────────

header "Shell"
link "$DOTFILES/zsh/zshrc"    "$HOME/.zshrc"
link "$DOTFILES/zsh/zprofile" "$HOME/.zprofile"
link "$DOTFILES/bash/bashrc"  "$HOME/.bashrc"

# ── Git ───────────────────────────────────────────────────────────────────────

header "Git"
if [[ -z "$GIT_EMAIL" ]]; then
    # Non-interactive: skip prompt if email already configured
    CURRENT_EMAIL=$(git config --global user.email 2>/dev/null || true)
    if [[ -n "$CURRENT_EMAIL" ]]; then
        GIT_EMAIL="$CURRENT_EMAIL"
    else
        read -r -p "  Git email address [charlesg3@gmail.com]: " GIT_EMAIL
    fi
fi
GIT_EMAIL="${GIT_EMAIL:-charlesg3@gmail.com}"
sed "s/YOUR_EMAIL_HERE/$GIT_EMAIL/" "$DOTFILES/git/gitconfig" > "$HOME/.gitconfig"
ok "~/.gitconfig (email: $GIT_EMAIL)"

# ── CLI tools ─────────────────────────────────────────────────────────────────

header "CLI tools"
install_pkg jq
install_pkg tree
install_pkg htop
install_pkg ncdu
install_pkg colordiff
install_pkg bat
install_pkg eza
[[ "$(uname)" == "Linux" ]] && install_pkg xclip
[[ "$(uname)" == "Linux" ]] && install_pkg mpg123
install_pkg zsh-autosuggestions
install_pkg zsh-syntax-highlighting

if command -v glow &>/dev/null; then
    ok "glow"
elif command -v brew &>/dev/null; then
    warn "Installing glow..."; brew install glow && ok "glow installed"
elif command -v apt-get &>/dev/null; then
    warn "Installing glow..."
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" \
        | sudo tee /etc/apt/sources.list.d/charm.list > /dev/null
    sudo apt-get update -q && sudo apt-get install -y glow
    ok "glow installed"
fi

# ── Kitty ─────────────────────────────────────────────────────────────────────

header "Kitty"
link "$DOTFILES/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"

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
    if [ -d "$NVIM_DIR/.git" ]; then
        warn "Updating nvim config..."
        git -C "$NVIM_DIR" pull --ff-only 2>/dev/null && ok "nvim config updated" || warn "could not pull nvim config"
        git -C "$NVIM_DIR" submodule update --remote --depth=1 2>/dev/null && ok "plugins updated" || true
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

# ── Node ──────────────────────────────────────────────────────────────────────

if [[ "$INSTALL_NODE" == true ]]; then
    header "Node"
    if command -v node &>/dev/null; then
        ok "node ($(node --version))"
    elif command -v brew &>/dev/null; then
        warn "Installing node..."
        brew install node
        ok "node installed ($(node --version))"
    elif command -v apt-get &>/dev/null; then
        warn "Installing node via NodeSource..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
        ok "node installed ($(node --version))"
    else
        warn "node: no supported package manager"
    fi
fi

# ── Claude Code hooks ─────────────────────────────────────────────────────────

if command -v claude &>/dev/null; then
    header "Claude Code hooks"
    link "$DOTFILES/claude/hooks/prompt-start.sh" "$HOME/.claude/hooks/prompt-start.sh"
    link "$DOTFILES/claude/hooks/stop-notify.sh"  "$HOME/.claude/hooks/stop-notify.sh"

    CLAUDE_SETTINGS="$HOME/.claude/settings.json"
    mkdir -p "$(dirname "$CLAUDE_SETTINGS")"
    [ -f "$CLAUDE_SETTINGS" ] || echo '{}' > "$CLAUDE_SETTINGS"
    tmp=$(mktemp)
    jq --slurpfile patch "$DOTFILES/claude/hooks.json" '. * $patch[0]' "$CLAUDE_SETTINGS" > "$tmp" \
        && mv "$tmp" "$CLAUDE_SETTINGS" && ok "~/.claude/settings.json (hooks)"
fi

# ── OS-specific ───────────────────────────────────────────────────────────────

OS="$(uname -s)"
if [[ "$OS" == "Darwin" ]]; then
    bash "$DOTFILES/install-macos.sh"
elif [[ "$OS" == "Linux" ]]; then
    bash "$DOTFILES/install-linux.sh"
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo -e "\n${BOLD}${GREEN}Done!${RESET}"
