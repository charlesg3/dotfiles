#!/usr/bin/env bash
# Sets up the nvim config and updates all plugins to latest.
# Initialises the nvim submodule, symlinks it to ~/.config/nvim,
# updates each plugin to remote HEAD with coloured progress output,
# and optionally installs system dependencies.
#
# Usage:
#   ./install_nvim.sh [--deps] [--python] [--clojure] [--go]
#
# Flags:
#   --deps      Also install system dependencies (ctags, tree-sitter, fonts, etc.)
#   --python    Install Python-specific dependencies (implies --deps)
#   --clojure   Install Clojure-specific dependencies (implies --deps)
#   --go        Install Go-specific dependencies (implies --deps)

set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
. "$DOTFILES/common.sh"

INSTALL_DEPS=false
DEPS_ARGS=()
for arg in "$@"; do
    case $arg in
        --deps)                  INSTALL_DEPS=true ;;
        --python|--clojure|--go) INSTALL_DEPS=true; DEPS_ARGS+=("$arg") ;;
        *)
            err "Unknown option: $arg"
            echo "Usage: $0 [--deps] [--python] [--clojure] [--go]"
            exit 1
            ;;
    esac
done

# ── Nvim submodule ────────────────────────────────────────────────────────────

header "Nvim config"

NVIM_DIR="$DOTFILES/nvim"
nvim_before="$(git -C "$NVIM_DIR" rev-parse --short HEAD 2>/dev/null || echo "")"
_spin "nvim"
git -C "$DOTFILES" submodule update --init --remote -- nvim 2>/dev/null
nvim_after="$(git -C "$NVIM_DIR" rev-parse --short HEAD 2>/dev/null || echo "?")"
_clear_spin
if [[ -z "$nvim_before" || "$nvim_before" == "$nvim_after" ]]; then
    ok "nvim ${DIM}$nvim_after${RESET}"
else
    ok "nvim ${DIM}$nvim_after${RESET} ${DIM}(was $nvim_before)${RESET}"
fi

# Symlink ~/.config/nvim → dotfiles/nvim
CONFIG_NVIM="$HOME/.config/nvim"
if [ -d "$CONFIG_NVIM" ] && [ ! -L "$CONFIG_NVIM" ]; then
    warn "$CONFIG_NVIM is a regular directory — removing and replacing with symlink"
    rm -rf "$CONFIG_NVIM"
fi
mkdir -p "$HOME/.config"
ln -sfn "$NVIM_DIR" "$CONFIG_NVIM"
ok "~/.config/nvim → $NVIM_DIR"

# ── Nvim plugins (nested submodules inside nvim/) ─────────────────────────────

header "Nvim plugins"

updated_plugins=()

for bundle_path in "$NVIM_DIR/bundle"/*/; do
    [ -d "$bundle_path" ] || continue
    name="$(basename "$bundle_path")"

    before_sha="$(git -C "$bundle_path" rev-parse --short HEAD 2>/dev/null || echo "")"

    _spin "$name"
    if git -C "$NVIM_DIR" submodule update --init --remote --depth=1 -- "bundle/$name" 2>/dev/null; then
        after_sha="$(git -C "$bundle_path" rev-parse --short HEAD 2>/dev/null || echo "?")"
        _clear_spin
        if [[ -z "$before_sha" ]]; then
            ok "$name ${DIM}$after_sha${RESET}"
            updated_plugins+=("$name")
        elif [[ "$before_sha" != "$after_sha" ]]; then
            ok "$name ${DIM}$after_sha${RESET} ${DIM}(was $before_sha)${RESET}"
            updated_plugins+=("$name")
        else
            ok "$name ${DIM}$after_sha${RESET}"
        fi
    else
        _clear_spin
        warn "$name (could not update)"
    fi
done

if [[ ${#updated_plugins[@]} -gt 0 ]]; then
    plugin_list="$(IFS=", "; echo "${updated_plugins[*]}")"
    _spin "committing plugin updates"
    git -C "$NVIM_DIR" add bundle/
    git -C "$NVIM_DIR" commit -m "chore: update plugins ($(date +%Y-%m-%d))

Updated: $plugin_list" 2>/dev/null || true
    git -C "$DOTFILES" add nvim
    git -C "$DOTFILES" commit -m "chore: bump nvim ($(date +%Y-%m-%d))" 2>/dev/null || true
    _clear_spin; ok "committed ${#updated_plugins[@]} plugin update(s)"
elif [[ "$nvim_before" != "$nvim_after" ]]; then
    _spin "committing nvim update"
    git -C "$DOTFILES" add nvim
    git -C "$DOTFILES" commit -m "chore: bump nvim ($(date +%Y-%m-%d))" 2>/dev/null || true
    _clear_spin; ok "committed nvim update"
fi

# ── Nvim dependencies ─────────────────────────────────────────────────────────

if [[ "$INSTALL_DEPS" == true ]]; then
    header "Nvim dependencies"
    bash "$NVIM_DIR/scripts/install.sh" "${DEPS_ARGS[@]}"
fi

echo -e "\n${BOLD}${GREEN}Done!${RESET}"
