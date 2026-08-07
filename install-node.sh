#!/usr/bin/env bash
# Ensures Node.js is at the latest LTS, on macOS and Linux.
#
# Both install.sh and update.sh call this, so a machine ends up with the same
# node either way, and "already installed" never means "stuck on whatever major
# happened to be there".
#
# Linux has two paths. NodeSource is preferred because it is a real apt package.
# Some networks block deb.nodesource.com, so when the repo is unreachable this
# falls back to the official tarball from nodejs.org into ~/.local, which is
# ahead of /usr/bin on PATH. The fallback deliberately leaves the distro nodejs
# package alone: on Ubuntu, hundreds of node-* packages depend on it.
#
# Usage:
#   ./install-node.sh          # install or upgrade to latest LTS
#   ./install-node.sh --check  # report only, exit 1 if an upgrade is available

set -euo pipefail

NODE_DIR="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"
source "$NODE_DIR/common.sh"

CHECK_ONLY=false
[[ "${1:-}" == "--check" ]] && CHECK_ONLY=true

NODE_PREFIX="$HOME/.local"
NODE_LIBDIR="$NODE_PREFIX/lib/nodejs"

# Latest LTS version string ("v24.4.1"), from the official release index.
latest_lts() {
    curl -fsSL --max-time 20 https://nodejs.org/dist/index.json 2>/dev/null \
        | jq -r '[.[] | select(.lts != false)][0].version' 2>/dev/null
}

# Major version number of a "vX.Y.Z" string.
_major() { echo "${1#v}" | cut -d. -f1; }

nodesource_reachable() {
    curl -fsS --max-time 10 -o /dev/null https://deb.nodesource.com/setup_lts.x 2>/dev/null
}

# $1 = LTS major, e.g. 24. Homebrew's plain `node` formula tracks Current, and
# npm's engines range skips ageing Current lines: npm 12 accepts
# ^22.22.2 || ^24.15.0 || >=26.0.0, so a machine on v25 cannot install current
# npm at all. Pin the LTS formula so node and npm stay installable together.
install_via_brew() {
    local formula="node@$1"
    if brew list --versions "$formula" &>/dev/null; then
        brew upgrade "$formula" &>/dev/null || true
    else
        brew install "$formula" &>/dev/null
    fi
    # Versioned node formulae are keg-only, so nothing reaches PATH until they
    # are linked, and an unlinked plain `node` would otherwise shadow this one.
    brew unlink node &>/dev/null || true
    brew link --overwrite --force "$formula" &>/dev/null
}

install_via_nodesource() {
    curl -fsSL --max-time 60 https://deb.nodesource.com/setup_lts.x | sudo -E bash - &>/dev/null
    sudo apt-get install -y -qq nodejs &>/dev/null
}

# Official tarball into ~/.local. No sudo, no apt, nothing removed.
install_via_tarball() {
    local version="$1" arch tarball url tmp
    case "$(uname -m)" in
        x86_64)          arch=x64 ;;
        aarch64|arm64)   arch=arm64 ;;
        armv7l)          arch=armv7l ;;
        *) err "unsupported architecture: $(uname -m)"; return 1 ;;
    esac

    tarball="node-${version}-linux-${arch}.tar.xz"
    url="https://nodejs.org/dist/${version}/${tarball}"
    tmp="$(mktemp -d)"

    if ! curl -fsSL --max-time 300 -o "$tmp/$tarball" "$url"; then
        rm -rf "$tmp"
        err "could not download $url"
        return 1
    fi

    mkdir -p "$NODE_LIBDIR" "$NODE_PREFIX/bin"
    tar -xJf "$tmp/$tarball" -C "$NODE_LIBDIR"
    rm -rf "$tmp"

    # `current` lets the symlinks in bin/ stay valid across upgrades, and leaves
    # the previous version in place to fall back to.
    ln -sfn "$NODE_LIBDIR/node-${version}-linux-${arch}" "$NODE_LIBDIR/current"
    local b
    for b in node npm npx; do
        ln -sfn "$NODE_LIBDIR/current/bin/$b" "$NODE_PREFIX/bin/$b"
    done
}

main() {
    header "Node"

    local current="" latest
    command -v node &>/dev/null && current="$(node --version)"

    _spin "checking latest LTS"
    latest="$(latest_lts)"
    _clear_spin

    if [[ -z "$latest" || "$latest" == "null" ]]; then
        if [[ -n "$current" ]]; then
            warn "node ${DIM}$current${RESET} (could not check latest)"
            return 0
        fi
        err "node not installed and nodejs.org is unreachable"
        return 1
    fi

    if [[ "$current" == "$latest" ]]; then
        ok "node ${DIM}$current${RESET}"
        return 0
    fi

    # A newer major is not automatically better: odd majors are Current-only and
    # go end-of-life fast (v25 shipped 2025-10 and was EOL by 2026-06), at which
    # point npm's engines range drops them and the newest npm will not install.
    # Even majors become LTS, so sitting on one briefly is fine and this script
    # picks it up on its own once it is the latest LTS.
    if [[ -n "$current" ]] && (( $(_major "$current") > $(_major "$latest") )); then
        if (( $(_major "$current") % 2 == 0 )); then
            ok "node ${DIM}$current${RESET} (Current, becomes LTS; latest LTS is $latest)"
            return 0
        fi
        warn "node ${YELLOW}$current is an odd/Current release with no LTS phase${RESET} — moving to LTS $latest"
    fi

    if [[ "$CHECK_ONLY" == true ]]; then
        warn "node: ${YELLOW}${current:-none} → $latest${RESET} available — re-run with --node to upgrade"
        return 1
    fi

    if [[ "$(uname)" == "Darwin" ]]; then
        if ! command -v brew &>/dev/null; then
            err "Homebrew not found — install it from https://brew.sh"
            return 1
        fi
        _spin "node (brew)"
        install_via_brew "$(_major "$latest")"
        _clear_spin
    elif command -v apt-get &>/dev/null && nodesource_reachable; then
        _spin "node (NodeSource)"
        install_via_nodesource
        _clear_spin
    else
        command -v apt-get &>/dev/null \
            && warn "deb.nodesource.com unreachable — installing from nodejs.org into $NODE_PREFIX"
        _spin "node $latest (nodejs.org)"
        install_via_tarball "$latest" || { _clear_spin; return 1; }
        _clear_spin
    fi

    hash -r 2>/dev/null || true
    local now
    now="$(command -v node &>/dev/null && node --version || echo "?")"
    if [[ -n "$current" ]]; then
        updated "node ${YELLOW}$current → $now${RESET}"
    else
        ok "node $now installed"
    fi
}

main "$@"
