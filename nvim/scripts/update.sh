#!/usr/bin/env bash
# Updates nvim itself and all plugins to latest, then commits the pinned SHAs.
# Safe to run repeatedly.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../.." && pwd)"
. "$DOTFILES/common.sh"

OS="$(uname -s)"

# ── Nvim binary ───────────────────────────────────────────────────────────────

header "Nvim"

CURRENT=$(nvim --version 2>/dev/null | head -1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "")
_spin "nvim"
LATEST=$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
    https://github.com/neovim/neovim/releases/latest 2>/dev/null \
    | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "")
_clear_spin

if [[ -z "$LATEST" ]]; then
    warn "nvim ${DIM}$CURRENT${RESET} (could not check latest)"
elif [[ "$CURRENT" == "$LATEST" ]]; then
    ok "nvim ${DIM}$CURRENT${RESET}"
elif [[ "$OS" == "Darwin" ]]; then
    warn "nvim ${YELLOW}$CURRENT → $LATEST${RESET}, upgrading via brew..."
    brew upgrade neovim 2>/dev/null \
        && ok "nvim ${GREEN}$LATEST${RESET} ${DIM}(updated from $CURRENT)${RESET}" \
        || err "nvim update failed"
else
    warn "nvim ${YELLOW}$CURRENT → $LATEST${RESET}, downloading..."
    TMP=$(mktemp -d)
    ARCH=$(uname -m)
    if curl -fsSLo "$TMP/nvim.tar.gz" \
        "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${ARCH}.tar.gz"; then
        sudo tar -xzf "$TMP/nvim.tar.gz" -C /usr/local --strip-components=1
        ok "nvim ${GREEN}$LATEST${RESET} ${DIM}(updated from $CURRENT)${RESET}"
    else
        err "nvim download failed"
    fi
    rm -rf "$TMP"
fi

# ── Plugins ───────────────────────────────────────────────────────────────────

header "Nvim plugins"

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

Updated: $plugin_list" 2>/dev/null || true
    _clear_spin; ok "committed ${#updated_plugins[@]} plugin update(s)"
fi
