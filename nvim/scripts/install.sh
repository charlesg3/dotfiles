#!/usr/bin/env bash
# Installs system dependencies for nvim plugins.
#
# Usage:
#   ./install.sh [--python] [--clojure] [--go]
#
# Flags:
#   --python    Install Python-specific dependencies (python3, ruff, pyright)
#   --clojure   Install Clojure-specific dependencies (java, clojure cli, clojure-lsp)
#   --go        Install Go-specific dependencies (go, gopls, vim-go binaries)
#
# Only core dependencies are installed by default.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
. "$DOTFILES/common.sh"

INSTALL_PYTHON=false
INSTALL_CLOJURE=false
INSTALL_GO=false

for arg in "$@"; do
    case $arg in
        --python)  INSTALL_PYTHON=true ;;
        --clojure) INSTALL_CLOJURE=true ;;
        --go)      INSTALL_GO=true ;;
        *)
            err "Unknown option: $arg"
            echo "Usage: $0 [--python] [--clojure] [--go]"
            exit 1
            ;;
    esac
done

# ── OS detection ──────────────────────────────────────────────────────────────

OS="$(uname -s)"

install_pkg() {
    local pkg="$1"
    warn "Installing $pkg..."
    if [[ "$OS" == "Darwin" ]]; then
        brew install "$pkg"
    elif command -v apt-get &>/dev/null; then
        sudo apt-get install -y "$pkg"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y "$pkg"
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm "$pkg"
    else
        err "Cannot install $pkg — no supported package manager found"
        return 1
    fi
}

check_or_install() {
    local cmd="$1"
    local pkg="${2:-$1}"
    if command -v "$cmd" &>/dev/null; then
        ok "$cmd"
    else
        install_pkg "$pkg"
        ok "$cmd installed"
    fi
}

# ── Core ──────────────────────────────────────────────────────────────────────

header "Core"
check_or_install git
check_or_install expect
# universal-ctags (supports markdown; macOS is keg-only so check explicit path)
if [[ "$OS" == "Darwin" ]]; then
    if [[ -x /opt/homebrew/opt/universal-ctags/bin/ctags || -x /usr/local/opt/universal-ctags/bin/ctags ]]; then
        ok "universal-ctags"
    else
        install_pkg universal-ctags
        ok "universal-ctags installed"
    fi
else
    UCTAGS=$( (command -v ctags && ctags --version 2>&1 | grep -qi universal && echo yes) 2>/dev/null || true)
    if [[ -n "$UCTAGS" ]]; then
        ok "universal-ctags"
    else
        install_pkg universal-ctags
        ok "universal-ctags installed"
    fi
fi

# Node: require v22+
NODE_MIN=22
install_node_linux() {
    warn "Installing Node.js v${NODE_MIN} via NodeSource..."
    curl -fsSL "https://deb.nodesource.com/setup_${NODE_MIN}.x" | sudo -E bash - 2>/dev/null
    sudo apt-get install -y nodejs
    ok "node $(node --version) installed"
}
if command -v node &>/dev/null; then
    NODE_VER=$(node -e "process.exit(parseInt(process.versions.node))" 2>/dev/null; echo $?)
    if [[ $NODE_VER -lt $NODE_MIN ]]; then
        warn "node $(node --version) is too old (need v${NODE_MIN}+)"
        if [[ "$OS" != "Darwin" ]]; then
            install_node_linux
        else
            err "Run: brew upgrade node"
            exit 1
        fi
    else
        ok "node $(node --version)"
    fi
else
    if [[ "$OS" == "Darwin" ]]; then
        install_pkg node
        ok "node $(node --version) installed"
    else
        install_node_linux
    fi
fi
check_or_install npm
if ! command -v tree-sitter &>/dev/null; then
    warn "tree-sitter CLI not found, installing via npm..."
    sudo npm install -g tree-sitter-cli
    ok "tree-sitter CLI installed"
else
    ok "tree-sitter"
fi

# ── Python ────────────────────────────────────────────────────────────────────

if [[ "$INSTALL_PYTHON" == true ]]; then
    header "Python"
    check_or_install python3
    if command -v ruff &>/dev/null; then
        ok "ruff"
    else
        warn "ruff not found, installing via standalone installer..."
        curl -LsSf https://astral.sh/ruff/install.sh | sudo sh
        ok "ruff installed"
    fi

    if ! command -v pyright-langserver &>/dev/null; then
        warn "pyright not found, installing via npm..."
        sudo npm install -g pyright
        ok "pyright installed"
    else
        ok "pyright"
    fi
fi

# ── Go ────────────────────────────────────────────────────────────────────────

if [[ "$INSTALL_GO" == true ]]; then
    header "Go"
    check_or_install go golang

    warn "Installing vim-go binaries (gopls, etc.)..."
    nvim +GoInstallBinaries +qa
    ok "vim-go binaries"
fi

# ── Clojure ───────────────────────────────────────────────────────────────────

if [[ "$INSTALL_CLOJURE" == true ]]; then
    header "Clojure"
    check_or_install java openjdk
    check_or_install clojure

    if ! command -v clojure-lsp &>/dev/null; then
        warn "clojure-lsp not found, installing..."
        if [[ "$OS" == "Darwin" ]]; then
            brew install clojure-lsp/brew/clojure-lsp
        else
            curl -sLo /tmp/clojure-lsp.zip "https://github.com/clojure-lsp/clojure-lsp/releases/latest/download/clojure-lsp-native-linux-amd64.zip"
            sudo unzip -o /tmp/clojure-lsp.zip -d /usr/local/bin/
            sudo chmod +x /usr/local/bin/clojure-lsp
            rm /tmp/clojure-lsp.zip
        fi
        ok "clojure-lsp installed"
    else
        ok "clojure-lsp"
    fi
fi

# ── Treesitter parsers ────────────────────────────────────────────────────────

header "Treesitter parsers"

PARSER_DIR="$HOME/.local/share/nvim/site/parser"
mkdir -p "$PARSER_DIR"
CACHE_DIR="$HOME/.cache/nvim"

install_ts_parser() {
    local name="$1"
    local src_dir="$2"

    if [ -f "$PARSER_DIR/${name}.so" ]; then
        ok "$name parser"
        return
    fi

    warn "Installing $name parser..."
    nvim --headless -c "TSInstall! $name" -c "sleep 20" -c "qa!" 2>/dev/null
    # Build manually from cached source if nvim didn't finish
    if [ ! -f "$PARSER_DIR/${name}.so" ] && [ -d "$CACHE_DIR/$src_dir" ]; then
        tree-sitter build -o "$PARSER_DIR/${name}.so" "$CACHE_DIR/$src_dir" 2>/dev/null
    fi

    if [ -f "$PARSER_DIR/${name}.so" ]; then
        ok "$name parser installed"
    else
        err "$name parser failed to install"
    fi
}

install_ts_parser "markdown" "tree-sitter-markdown/tree-sitter-markdown"
install_ts_parser "markdown_inline" "tree-sitter-markdown_inline/tree-sitter-markdown-inline"
install_ts_parser "yaml" "tree-sitter-yaml/tree-sitter-yaml"

# ── Nerd Font ─────────────────────────────────────────────────────────────────

header "Nerd Font"

FONT_NAME="JetBrainsMono"

if [[ "$OS" == "Darwin" ]]; then
    if ls "$HOME/Library/Fonts"/JetBrainsMonoNerdFont* &>/dev/null; then
        ok "$FONT_NAME Nerd Font"
    else
        warn "Installing $FONT_NAME Nerd Font via brew..."
        brew tap homebrew/cask-fonts 2>/dev/null || true
        brew install --cask font-jetbrains-mono-nerd-font
        ok "$FONT_NAME Nerd Font installed"
    fi
else
    FONT_DIR="/usr/local/share/fonts/NerdFonts"
    if ls "$FONT_DIR"/JetBrainsMonoNerdFont* &>/dev/null; then
        ok "$FONT_NAME Nerd Font"
    else
        warn "Downloading $FONT_NAME Nerd Font..."
        sudo mkdir -p "$FONT_DIR"
        TMP=$(mktemp -d)
        curl -fLo "$TMP/${FONT_NAME}.zip" \
            "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_NAME}.zip"
        sudo unzip -q "$TMP/${FONT_NAME}.zip" '*.ttf' -d "$FONT_DIR"
        rm -rf "$TMP"
        sudo fc-cache -f "$FONT_DIR"
        ok "$FONT_NAME Nerd Font installed"
    fi
fi

warn "Remember to set your terminal font to '${FONT_NAME} Nerd Font'"
