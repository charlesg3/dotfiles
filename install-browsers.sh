#!/usr/bin/env bash
# Install browser extensions for Chrome and Firefox on macOS and Linux.
# Safe to re-run.

set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
. "$DOTFILES/common.sh"

OS="$(uname -s)"

# ── Extension definitions ──────────────────────────────────────────────────────

# Chrome Web Store extension IDs
CHROME_EXT_IDS=(
    "dbepggeogbaibhgnhhndojpepiihcmeb"  # Vimium
    "hdokiejnpimakedhajhdlcegeplioahd"  # LastPass
)
CHROME_EXT_NAMES=(
    "Vimium"
    "LastPass"
)

# Firefox extension XPI URLs (from addons.mozilla.org)
FF_EXT_URLS=(
    "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi"
    "https://addons.mozilla.org/firefox/downloads/latest/lastpass-password-manager/latest.xpi"
)
FF_EXT_NAMES=(
    "Vimium FF"
    "LastPass"
)

# ── Chrome helpers ─────────────────────────────────────────────────────────────

_install_chrome_exts_sudo() {
    local ext_dir="$1"
    local i
    for i in "${!CHROME_EXT_IDS[@]}"; do
        local id="${CHROME_EXT_IDS[$i]}"
        local name="${CHROME_EXT_NAMES[$i]}"
        local json="$ext_dir/$id.json"
        if [[ -f "$json" ]]; then
            ok "$name (already registered)"
        else
            printf '{"external_update_url":"https://clients2.google.com/service/update2/crx"}\n' \
                | sudo tee "$json" > /dev/null
            ok "$name (will prompt on next launch)"
        fi
    done
}

_install_chrome_exts() {
    local ext_dir="$1"
    mkdir -p "$ext_dir"
    local i
    for i in "${!CHROME_EXT_IDS[@]}"; do
        local id="${CHROME_EXT_IDS[$i]}"
        local name="${CHROME_EXT_NAMES[$i]}"
        local json="$ext_dir/$id.json"
        if [[ -f "$json" ]]; then
            ok "$name (already registered)"
        else
            printf '{"external_update_url":"https://clients2.google.com/service/update2/crx"}\n' > "$json"
            ok "$name (will prompt on next launch)"
        fi
    done
}

# ── Firefox helpers ────────────────────────────────────────────────────────────

_install_ff_exts() {
    local policies_file="$1"
    local use_sudo="$2"

    # Build the Install array JSON
    local urls_json
    urls_json="$(printf '"%s",' "${FF_EXT_URLS[@]}")"
    urls_json="[${urls_json%,}]"

    local policy_json
    policy_json="$(printf '{"policies":{"Extensions":{"Install":%s}}}' "$urls_json")"

    # Check if all URLs are already present — policies file is readable without sudo
    if [[ -f "$policies_file" ]] && command -v jq &>/dev/null; then
        local all_present=true
        local url
        for url in "${FF_EXT_URLS[@]}"; do
            if ! jq -e --arg u "$url" 'any(.policies.Extensions.Install[]?; . == $u)' "$policies_file" &>/dev/null; then
                all_present=false
                break
            fi
        done
        if [[ "$all_present" == "true" ]]; then
            local name
            for name in "${FF_EXT_NAMES[@]}"; do
                ok "$name (already registered)"
            done
            return
        fi
    fi

    local dir
    dir="$(dirname "$policies_file")"

    if [[ "$use_sudo" == "true" ]]; then
        if ! sudo -n true 2>/dev/null && ! sudo true 2>/dev/null; then
            warn "Firefox: sudo required to write $policies_file — skipping"
            return
        fi
        sudo mkdir -p "$dir"
        if [[ -f "$policies_file" ]] && command -v jq &>/dev/null; then
            local tmp
            tmp="$(mktemp)"
            sudo jq --argjson p "$policy_json" '. * $p' "$policies_file" > "$tmp"
            sudo mv "$tmp" "$policies_file"
        else
            printf '%s\n' "$policy_json" | sudo tee "$policies_file" > /dev/null
        fi
    else
        mkdir -p "$dir"
        if [[ -f "$policies_file" ]] && command -v jq &>/dev/null; then
            local tmp
            tmp="$(mktemp)"
            jq --argjson p "$policy_json" '. * $p' "$policies_file" > "$tmp"
            mv "$tmp" "$policies_file"
        else
            printf '%s\n' "$policy_json" > "$policies_file"
        fi
    fi

    local name
    for name in "${FF_EXT_NAMES[@]}"; do
        ok "$name"
    done
}

# ── Chrome ─────────────────────────────────────────────────────────────────────

if [[ "$OS" == "Darwin" ]]; then
    if [[ -d "/Applications/Google Chrome.app" ]]; then
        header "Chrome"
        _install_chrome_exts "$HOME/Library/Application Support/Google/Chrome/External Extensions"
    fi
    if [[ -d "/Applications/Brave Browser.app" ]]; then
        header "Brave"
        _install_chrome_exts "$HOME/Library/Application Support/BraveSoftware/Brave-Browser/External Extensions"
    fi
elif [[ "$OS" == "Linux" ]]; then
    if command -v google-chrome &>/dev/null || command -v google-chrome-stable &>/dev/null; then
        header "Chrome"
        EXT_DIR="/opt/google/chrome/extensions"
        # Check if all extensions are already registered
        _all_chrome_exts_present() {
            local id
            for id in "${CHROME_EXT_IDS[@]}"; do
                [[ -f "$EXT_DIR/$id.json" ]] || return 1
            done
            return 0
        }
        if _all_chrome_exts_present; then
            for name in "${CHROME_EXT_NAMES[@]}"; do
                ok "$name (already registered)"
            done
        elif sudo -n true 2>/dev/null || sudo true 2>/dev/null; then
            sudo mkdir -p "$EXT_DIR"
            _install_chrome_exts_sudo "$EXT_DIR"
        else
            warn "Chrome: sudo required to write to $EXT_DIR — skipping"
        fi
    fi
fi

# ── Firefox ────────────────────────────────────────────────────────────────────

if [[ "$OS" == "Darwin" ]]; then
    if [[ -d "/Applications/Firefox.app" ]]; then
        header "Firefox"
        _install_ff_exts "/Library/Application Support/Mozilla/policies.json" "true"
    fi
elif [[ "$OS" == "Linux" ]]; then
    if command -v firefox &>/dev/null; then
        header "Firefox"
        _install_ff_exts "/etc/firefox/policies/policies.json" "true"
    fi
fi
