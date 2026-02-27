#!/usr/bin/env bash
# Updates all tools managed by this dotfiles repo.
# Safe to run repeatedly.
#
# Usage:
#   ./update.sh [--node] [--docker] [--vault]
#
# Flags:
#   --node    Also upgrade Node.js and npm (otherwise just reports if outdated)
#   --docker  Also upgrade Docker         (otherwise just reports if outdated)
#   --vault   Also upgrade Vault          (otherwise just reports if outdated)

set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
. "$DOTFILES/common.sh"

UPDATE_NODE=false
UPDATE_DOCKER=false
UPDATE_VAULT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --node)   UPDATE_NODE=true ;;
        --docker) UPDATE_DOCKER=true ;;
        --vault)  UPDATE_VAULT=true ;;
        *)
            err "Unknown option: $1"
            echo "Usage: $0 [--node] [--docker] [--vault]"
            exit 1
            ;;
    esac
    shift
done

# Packages to always upgrade
BREW_PKGS=(jq tree htop ncdu colordiff bat eza zsh-autosuggestions zsh-syntax-highlighting glow gh colima fileicon)
APT_PKGS=(jq tree htop ncdu colordiff bat eza xclip zsh-autosuggestions zsh-syntax-highlighting glow gh)

# Compare two semver strings; returns 0 if $1 > $2
_semver_gt() {
    local IFS=.
    read -ra a <<< "$1"
    read -ra b <<< "$2"
    local i=0 max
    max=$(( ${#a[@]} > ${#b[@]} ? ${#a[@]} : ${#b[@]} ))
    while [ "$i" -lt "$max" ]; do
        local av=${a[i]:-0} bv=${b[i]:-0}
        if [ "$av" -gt "$bv" ]; then return 0
        elif [ "$av" -lt "$bv" ]; then return 1
        fi
        i=$(( i + 1 ))
    done
    return 1
}

# ── Homebrew (macOS) ──────────────────────────────────────────────────────────

_brew_update() {
    local pkg="$1" do_upgrade="${2:-true}" hint="${3:-}"
    brew list --formula "$pkg" &>/dev/null || return 0
    local version
    version=$(brew list --versions "$pkg" | awk '{print $NF}')
    _spin "$pkg"
    # --verbose gives "pkg (installed) < candidate"; without it only the name is printed
    local outdated
    outdated=$(brew outdated --verbose --formula "$pkg" 2>/dev/null) || true
    if [[ -n "$outdated" ]]; then
        local candidate
        candidate=$(echo "$outdated" | awk '{for(i=1;i<=NF;i++) if($i~/^[0-9]+\.[0-9]/) print $i}' | tail -1)
        # Guard: skip if candidate isn't actually newer (e.g. tap version mismatch)
        if [[ -z "$candidate" ]] || ! _semver_gt "$candidate" "$version"; then
            _clear_spin; ok "$pkg ${DIM}$version${RESET}"
            return
        fi
        if [[ "$do_upgrade" == true ]]; then
            brew upgrade --quiet "$pkg" 2>/dev/null || true
            local new_version
            new_version=$(brew list --versions "$pkg" | awk '{print $NF}')
            _clear_spin; ok "$pkg ${GREEN}$new_version${RESET} ${DIM}(updated from $version)${RESET}"
        else
            _clear_spin; warn "$pkg: ${YELLOW}$version → $candidate${RESET} available — re-run with $hint to upgrade"
        fi
    else
        _clear_spin; ok "$pkg ${DIM}$version${RESET}"
    fi
}

if command -v brew &>/dev/null; then
    header "Homebrew"
    warn "Fetching updates..."
    brew update -q

    for pkg in "${BREW_PKGS[@]}"; do
        _brew_update "$pkg"
    done

    _brew_update docker         "$UPDATE_DOCKER" "--docker"
    _brew_update docker-buildx  "$UPDATE_DOCKER" "--docker"
    _brew_update vault          "$UPDATE_VAULT"  "--vault"
    _brew_update node   "$UPDATE_NODE"   "--node"
fi

# ── npm ───────────────────────────────────────────────────────────────────────

if command -v npm &>/dev/null; then
    header "npm"
    current=$(npm --version)
    _spin "npm"
    latest=$(npm view npm version 2>/dev/null || echo "")
    _clear_spin
    if [[ "$UPDATE_NODE" == true ]]; then
        npm install -g npm --quiet && ok "npm ${DIM}updated${RESET}" || true
    elif [[ -n "$latest" && "$current" != "$latest" ]]; then
        warn "npm: ${YELLOW}$current → $latest${RESET} available — re-run with --node to upgrade"
    else
        ok "npm ${DIM}$current${RESET}"
    fi
fi

# ── apt (Linux) ───────────────────────────────────────────────────────────────

_apt_update() {
    local pkg="$1" do_upgrade="${2:-true}" hint="${3:-}"
    dpkg -s "$pkg" &>/dev/null || return 0
    local installed candidate
    installed=$(dpkg -s "$pkg" | awk '/^Version:/ {print $2}')
    candidate=$(apt-cache policy "$pkg" 2>/dev/null | awk '/Candidate:/ {print $2}')
    _spin "$pkg"
    if [[ -n "$candidate" && "$installed" != "$candidate" ]]; then
        if [[ "$do_upgrade" == true ]]; then
            sudo apt-get install -y -qq --only-upgrade "$pkg" >/dev/null 2>&1 || true
            _clear_spin; ok "$pkg ${GREEN}$candidate${RESET} ${DIM}(updated from $installed)${RESET}"
        else
            _clear_spin; warn "$pkg: ${YELLOW}$installed → $candidate${RESET} available — re-run with $hint to upgrade"
        fi
    else
        _clear_spin; ok "$pkg ${DIM}$installed${RESET}"
    fi
}

if command -v apt-get &>/dev/null; then
    header "apt"
    warn "Fetching updates..."
    sudo apt-get update -qq

    for pkg in "${APT_PKGS[@]}"; do
        _apt_update "$pkg"
    done

    for pkg in docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; do
        _apt_update "$pkg" "$UPDATE_DOCKER" "--docker"
    done

    # Ubuntu release upgrade check
    if command -v do-release-upgrade &>/dev/null; then
        _spin "ubuntu release"
        release_out=$(do-release-upgrade -c 2>&1 || true)
        _clear_spin
        if echo "$release_out" | grep -q "New release"; then
            new_release=$(echo "$release_out" | grep -oP "'\K[^']+(?=' available)")
            warn "Ubuntu: ${YELLOW}new release $new_release available${RESET} — run: sudo do-release-upgrade"
        else
            ok "ubuntu ${DIM}$(lsb_release -rs)${RESET}"
        fi
    fi

    # Vault: check dpkg first, fall through to binary check below
    if ! dpkg -s vault &>/dev/null; then
        : # handled in the binary vault section below
    else
        _apt_update vault "$UPDATE_VAULT" "--vault"
    fi
fi

# ── Vault binary (Linux, manually installed) ──────────────────────────────────

if command -v vault &>/dev/null && ! dpkg -s vault &>/dev/null; then
    header "Vault"
    installed=$(vault version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    _spin "vault"
    latest=$(curl -fsSL https://checkpoint-api.hashicorp.com/v1/check/vault 2>/dev/null \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['current_version'])" 2>/dev/null || echo "")
    _clear_spin
    if [[ -z "$latest" ]]; then
        warn "vault ${DIM}$installed${RESET} (could not check latest)"
    elif [[ "$installed" == "$latest" ]]; then
        ok "vault ${DIM}$installed${RESET}"
    elif [[ "$UPDATE_VAULT" == true ]]; then
        _spin "vault upgrading to $latest"
        arch=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
        tmp="$(mktemp -d)"
        curl -fsSL "https://releases.hashicorp.com/vault/${latest}/vault_${latest}_linux_${arch}.zip" \
            -o "$tmp/vault.zip"
        unzip -q "$tmp/vault.zip" -d "$tmp"
        sudo mv "$tmp/vault" /usr/local/bin/vault
        rm -rf "$tmp"
        _clear_spin; ok "vault ${GREEN}$latest${RESET} ${DIM}(updated from $installed)${RESET}"
    else
        warn "vault: ${YELLOW}$installed → $latest${RESET} available — re-run with --vault to upgrade"
    fi
fi

# ── ble.sh (GitHub nightly) ───────────────────────────────────────────────────

if [[ -f "$HOME/.local/share/blesh/ble.sh" ]]; then
    header "ble.sh"
    _spin "ble.sh"
    tmp="$(mktemp -d)"
    curl -fsSL https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz \
        | tar xJf - -C "$tmp"
    bash "$tmp/ble-nightly/ble.sh" --install "$HOME/.local/share" >/dev/null 2>&1
    rm -rf "$tmp"
    _clear_spin; ok "ble.sh ${DIM}updated${RESET}"
fi

# ── Kitty (Linux) ─────────────────────────────────────────────────────────────

if command -v kitty &>/dev/null && [[ "$(uname)" == "Linux" ]]; then
    header "Kitty"
    _spin "kitty"
    kitty +update-kitty >/dev/null 2>&1 || true
    _clear_spin; ok "kitty ${DIM}$(kitty --version | awk '{print $2}')${RESET}"
fi

# ── Nvim ──────────────────────────────────────────────────────────────────────

if [ -d "$DOTFILES/nvim" ]; then
    nvim_before="$(git -C "$DOTFILES/nvim" rev-parse --short HEAD 2>/dev/null || echo "")"
    _spin "nvim config"
    git -C "$DOTFILES" submodule update --remote -- nvim 2>/dev/null || true
    nvim_after="$(git -C "$DOTFILES/nvim" rev-parse --short HEAD 2>/dev/null || echo "?")"
    _clear_spin
    if [[ -n "$nvim_before" && "$nvim_before" != "$nvim_after" ]]; then
        ok "nvim config ${DIM}$nvim_after${RESET} ${DIM}(was $nvim_before)${RESET}"
        git -C "$DOTFILES" add nvim
        git -C "$DOTFILES" commit -m "chore: bump nvim ($(date +%Y-%m-%d))" 2>/dev/null || true
    else
        ok "nvim config ${DIM}$nvim_after${RESET}"
    fi
    bash "$DOTFILES/nvim/scripts/update.sh"
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo -e "\n${BOLD}${GREEN}Done!${RESET}"
