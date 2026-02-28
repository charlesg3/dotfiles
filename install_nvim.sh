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
    if git -C "$NVIM_DIR" submodule update --init --remote --depth=1 --force -- "bundle/$name" &>/dev/null; then
        after_sha="$(git -C "$bundle_path" rev-parse --short HEAD 2>/dev/null || echo "?")"
        _clear_spin
        if [[ -z "$before_sha" ]]; then
            updated "$name ${DIM}$after_sha${RESET}"
            updated_plugins+=("$name")
        elif [[ "$before_sha" != "$after_sha" ]]; then
            updated "$name ${YELLOW}$before_sha → $after_sha${RESET}"
            updated_plugins+=("$name")
        else
            ok "$name ${DIM}$after_sha${RESET}"
        fi
    else
        _clear_spin
        warn "$name (could not update)"
    fi
done

# ── Local patches ─────────────────────────────────────────────────────────────
PATCHES_DIR="$NVIM_DIR/patches"
if [[ -d "$PATCHES_DIR" ]]; then
    for bundle_patch_dir in "$PATCHES_DIR"/*/; do
        [[ -d "$bundle_patch_dir" ]] || continue
        bundle="$(basename "$bundle_patch_dir")"
        bundle_path="$NVIM_DIR/bundle/$bundle"
        [[ -d "$bundle_path" ]] || continue
        for patch_file in "$bundle_patch_dir"*.patch; do
            [[ -f "$patch_file" ]] || continue
            patch_name="$(basename "$patch_file" .patch)"
            if git -C "$bundle_path" apply --check --reverse "$patch_file" &>/dev/null; then
                ok "$bundle/$patch_name merged upstream — delete $patch_file"
            elif git -C "$bundle_path" apply --check "$patch_file" &>/dev/null; then
                git -C "$bundle_path" apply "$patch_file" &>/dev/null
                ok "$bundle/$patch_name (patch applied)"
            else
                warn "$bundle/$patch_name patch does not apply — manual fix needed"
            fi
        done
    done
fi

if [[ ${#updated_plugins[@]} -gt 0 ]]; then
    plugin_list="$(IFS=", "; echo "${updated_plugins[*]}")"
    _spin "committing plugin updates"
    git -C "$NVIM_DIR" add bundle/
    git -C "$NVIM_DIR" commit -m "chore: update plugins ($(date +%Y-%m-%d))

Updated: $plugin_list" &>/dev/null || true
    git -C "$DOTFILES" add nvim
    git -C "$DOTFILES" commit -m "chore: bump nvim ($(date +%Y-%m-%d))" &>/dev/null || true
    _clear_spin; ok "committed ${#updated_plugins[@]} plugin update(s)"
elif [[ "$nvim_before" != "$nvim_after" ]]; then
    _spin "committing nvim update"
    git -C "$DOTFILES" add nvim
    git -C "$DOTFILES" commit -m "chore: bump nvim ($(date +%Y-%m-%d))" &>/dev/null || true
    _clear_spin; ok "committed nvim update"
fi

# ── Nvim dependencies ─────────────────────────────────────────────────────────

if [[ "$INSTALL_DEPS" == true ]]; then
    header "Nvim dependencies"
    bash "$NVIM_DIR/scripts/install.sh" "${DEPS_ARGS[@]}"
fi

echo -e "\n${BOLD}${GREEN}Done!${RESET}"
