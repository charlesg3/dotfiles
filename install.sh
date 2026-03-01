#!/usr/bin/env bash
# Sets up and updates dotfiles on a machine. Safe to run repeatedly.
#
# Usage:
#   ./install.sh [--nvim] [--node] [--email EMAIL]
#
# Flags:
#   --nvim         Also install nvim system dependencies (ctags, tree-sitter, fonts, etc.)
#                  The nvim config symlink and plugin sync always run regardless.
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

_gen() {
    # Substitute ${PANDA_*} variables from colors.sh into a template file.
    local tmpl="$1" dst="$2"
    (set -a; source "$DOTFILES/shell/colors.sh"; envsubst < "$tmpl" > "$dst")
    ok "$(basename "$dst")"
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
install_pkg gettext
BAT_THEMES_DIR="$HOME/.config/bat/themes"
mkdir -p "$BAT_THEMES_DIR"
_gen "$DOTFILES/shell/panda.tmTheme.tmpl" "$BAT_THEMES_DIR/Panda.tmTheme"
command -v bat     &>/dev/null && bat     cache --build &>/dev/null && ok "bat theme"
command -v batcat  &>/dev/null && batcat  cache --build &>/dev/null && ok "batcat theme"
install_pkg tmux
install_pkg expect
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
if [[ "$(uname)" == "Darwin" ]]; then
    GLOW_CFG="$HOME/Library/Preferences/glow/glow.yml"
else
    GLOW_CFG="$HOME/.config/glow/glow.yml"
fi
GLOW_CFG_DIR="$(dirname "$GLOW_CFG")"
mkdir -p "$GLOW_CFG_DIR"
_gen "$DOTFILES/shell/glamour.json.tmpl" "$GLOW_CFG_DIR/glamour.json"
sed "s|__GLOW_CFG_DIR__|$GLOW_CFG_DIR|" "$DOTFILES/shell/glow.yml" > "$GLOW_CFG" && ok "$GLOW_CFG"

EZA_CFG_DIR="$HOME/.config/eza"
mkdir -p "$EZA_CFG_DIR"
_gen "$DOTFILES/eza/theme.yml.tmpl" "$EZA_CFG_DIR/theme.yml"

# ── Terminal ──────────────────────────────────────────────────────────────────

header "Terminal"
link "$DOTFILES/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
link "$DOTFILES/tmux/tmux.conf"   "$HOME/.tmux.conf"

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
# Always run: symlink nvim/ → ~/.config/nvim and sync plugins.
# Pass --deps only when --nvim was given to also install system dependencies.

if [[ "$INSTALL_NVIM" == true ]]; then
    bash "$DOTFILES/install_nvim.sh" --deps
else
    bash "$DOTFILES/install_nvim.sh"
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
    header "Claude Code"
    link "$DOTFILES/claude/hooks/prompt-start.sh" "$HOME/.claude/hooks/prompt-start.sh"
    link "$DOTFILES/claude/hooks/stop-notify.sh"  "$HOME/.claude/hooks/stop-notify.sh"
    link "$DOTFILES/claude/statusline.sh"          "$HOME/.claude/statusline.sh"

    CLAUDE_SETTINGS="$HOME/.claude/settings.json"
    mkdir -p "$(dirname "$CLAUDE_SETTINGS")"
    [ -f "$CLAUDE_SETTINGS" ] || echo '{}' > "$CLAUDE_SETTINGS"
    tmp=$(mktemp)
    jq --slurpfile h "$DOTFILES/claude/hooks.json" \
       --slurpfile s "$DOTFILES/claude/statusline.json" \
       --slurpfile p "$DOTFILES/claude/permissions.json" \
       '. * $h[0] * $s[0] * $p[0]' "$CLAUDE_SETTINGS" > "$tmp" \
        && mv "$tmp" "$CLAUDE_SETTINGS" && ok "~/.claude/settings.json"

    # claude-status hook dispatcher (if the bundle is present)
    STATUS_DIR="$HOME/.config/nvim/bundle/claude-status"
    STATUS_HOOK_PATH="$STATUS_DIR/hooks/claude-hook.sh"
    STATUS_HOOK_REF="~/.config/nvim/bundle/claude-status/hooks/claude-hook.sh"
    if [[ -f "$STATUS_HOOK_PATH" ]]; then
        # Run claude-status's own install (dep check + git hooks)
        bash "$STATUS_DIR/install.sh" --hooks &>/dev/null
        ok "claude-status install"

        # Link dotfiles user config (overrides claude-status defaults)
        STATUS_CFG_DIR="$HOME/.config/claude-status"
        mkdir -p "$STATUS_CFG_DIR"
        link "$DOTFILES/claude-status/config.json" "$STATUS_CFG_DIR/config.json"

        # Register hook events and statusLine in ~/.claude/settings.json
        STATUS_STATUSLINE_REF="~/.config/nvim/bundle/claude-status/scripts/statusline.sh"
        chmod +x "$STATUS_HOOK_PATH"
        tmp=$(mktemp)
        jq --arg h "$STATUS_HOOK_REF" --arg sl "$STATUS_STATUSLINE_REF" '
            def ensure_hook(ev):
                .hooks[ev] = (
                    [(.hooks[ev] // []) | .[] | select(
                        .hooks | map(.command) | any(. == $h) | not
                    )] + [{"hooks":[{"type":"command","command":$h}]}]
                );
            ensure_hook("SessionStart") | ensure_hook("UserPromptSubmit") |
            ensure_hook("Notification") | ensure_hook("Stop") | ensure_hook("SessionEnd") |
            .statusLine = {"type":"command","command":$sl}
        ' "$CLAUDE_SETTINGS" > "$tmp" && mv "$tmp" "$CLAUDE_SETTINGS"
        ok "claude-status hooks"
    fi
fi

# ── OS-specific ───────────────────────────────────────────────────────────────

OS="$(uname -s)"
if [[ "$OS" == "Darwin" ]]; then
    bash "$DOTFILES/install-macos.sh"
elif [[ "$OS" == "Linux" ]]; then
    bash "$DOTFILES/install-linux.sh"
fi

# ── Remote URL ────────────────────────────────────────────────────────────────
# Convert HTTPS origin to SSH once git is fully configured and SSH auth works.
# Runs last so a missing SSH key never blocks the rest of the install.

header "Git remote"
ORIGIN=$(git -C "$DOTFILES" remote get-url origin 2>/dev/null || true)
if [[ "$ORIGIN" == https://github.com/* ]]; then
    SSH_URL="git@github.com:${ORIGIN#https://github.com/}"
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        git -C "$DOTFILES" remote set-url origin "$SSH_URL"
        ok "remote origin → $SSH_URL"
    else
        warn "SSH auth not available yet — keeping HTTPS origin"
        warn "Once your SSH key is configured, run: git remote set-url origin $SSH_URL"
    fi
else
    ok "remote origin: $ORIGIN"
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo -e "\n${BOLD}${GREEN}Done!${RESET}"
