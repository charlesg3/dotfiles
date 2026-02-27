#!/usr/bin/env bash
# Sets up the nvim config and updates all plugins to latest.
# Symlinks nvim/ to ~/.config/nvim, then initialises and updates
# each bundle submodule to remote HEAD with coloured progress output.
# Optionally runs nvim/scripts/install.sh to install system dependencies.
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
        --deps)               INSTALL_DEPS=true ;;
        --python|--clojure|--go) INSTALL_DEPS=true; DEPS_ARGS+=("$arg") ;;
        *)
            err "Unknown option: $arg"
            echo "Usage: $0 [--deps] [--python] [--clojure] [--go]"
            exit 1
            ;;
    esac
done

# ── Nvim config symlink ────────────────────────────────────────────────────────

header "Nvim config"

NVIM_DIR="$HOME/.config/nvim"
if [ -d "$NVIM_DIR" ] && [ ! -L "$NVIM_DIR" ]; then
    warn "$NVIM_DIR is a regular directory — removing and replacing with symlink"
    rm -rf "$NVIM_DIR"
fi
mkdir -p "$HOME/.config"
ln -sfn "$DOTFILES/nvim" "$NVIM_DIR"
ok "~/.config/nvim → $DOTFILES/nvim"

# ── Nvim plugins (submodules) ──────────────────────────────────────────────────

header "Nvim plugins"

# For each plugin: init (if new) + update to remote HEAD in one step.
# Captures SHA before and after so we can report what changed.
updated_plugins=()

for bundle_path in "$DOTFILES/nvim/bundle"/*/; do
    [ -d "$bundle_path" ] || continue
    name="$(basename "$bundle_path")"
    rel_path="nvim/bundle/$name"

    before_sha="$(git -C "$bundle_path" rev-parse --short HEAD 2>/dev/null || echo "")"

    _spin "$name"
    if git -C "$DOTFILES" submodule update --init --remote --depth=1 -- "$rel_path" 2>/dev/null; then
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
    git -C "$DOTFILES" add nvim/bundle/
    git -C "$DOTFILES" commit -m "chore: update nvim plugins ($(date +%Y-%m-%d))

Updated: $plugin_list" 2>/dev/null
    _clear_spin; ok "committed ${#updated_plugins[@]} plugin update(s)"
fi

# ── Nvim dependencies ─────────────────────────────────────────────────────────

if [[ "$INSTALL_DEPS" == true ]]; then
    header "Nvim dependencies"
    bash "$DOTFILES/nvim/scripts/install.sh" "${DEPS_ARGS[@]}"
fi

echo -e "\n${BOLD}${GREEN}Done!${RESET}"
