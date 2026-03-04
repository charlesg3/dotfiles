#!/usr/bin/env bash
# shell/lib.sh — sourceable UI helpers for shell scripts.
#
# SOURCE this file; do not execute it directly.
#
# Pulls the Panda palette from shell/colors.sh, then provides:
#   Output:  ok, info, warn, err, header
#   Spinner: spin, clear_spin
#   Bell:    ring_bell
#   Notify:  notify_os TITLE MESSAGE
#
# Note: colors.sh defines ANSI_RESET/DIM as literal \033 strings (for echo -e).
# This file re-derives them as actual escape bytes so they work with printf too.

_LIB_SH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_LIB_SH_DIR}/colors.sh"

# Actual escape bytes — safe for both printf and echo
ANSI_RESET=$'\033[0m'
ANSI_BOLD=$'\033[1m'
ANSI_DIM=$'\033[2m'
ANSI_UNDERLINE=$'\033[4m'

# Semantic foreground colors (derived from palette via _ansi_fg → real bytes)
ANSI_OK="$(_ansi_fg "$COLOR_OK")"
ANSI_WARN="$(_ansi_fg "$COLOR_WARN")"
ANSI_ERR="$(_ansi_fg "$COLOR_ERR")"
ANSI_HEADER="$(_ansi_fg "$COLOR_HEADER")"
ANSI_SPIN="$(_ansi_fg "$COLOR_INFO")"       # blue    — spinner / progress
ANSI_CLOCK="$(_ansi_fg "$PANDA_ORANGE")"    # orange  — timers / clocks
ANSI_COMMENT="$(_ansi_fg "$COLOR_DIM")"     # #676B79 — muted / secondary text

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------
ok()     { printf "  %s✓%s %s\n"   "$ANSI_OK"     "$ANSI_RESET" "$*"; }
info()   { printf "  %s·%s %s\n"   "$ANSI_SPIN"   "$ANSI_RESET" "$*"; }
warn()   { printf "  %s~%s %s\n"   "$ANSI_WARN"   "$ANSI_RESET" "$*"; }
err()    { printf "  %s✗%s %s\n"   "$ANSI_ERR"    "$ANSI_RESET" "$*" >&2; }
header() { printf "\n%s%s%s\n"     "${ANSI_BOLD}${ANSI_HEADER}" "$*" "$ANSI_RESET"; }
spin()   { printf "  %s↻%s  %s..." "$ANSI_SPIN"   "$ANSI_RESET" "$*"; }
clear_spin() { printf '\r\033[2K'; }

# ---------------------------------------------------------------------------
# ring_bell — terminal bell
# ---------------------------------------------------------------------------
ring_bell() { printf '\a'; }

# ---------------------------------------------------------------------------
# notify_os TITLE MESSAGE — native desktop notification (macOS + Linux)
# ---------------------------------------------------------------------------
notify_os() {
    local title="${1:-}" message="${2:-}"
    if [[ "$(uname)" == "Darwin" ]]; then
        command -v osascript &>/dev/null && \
            osascript -e \
                "display notification \"${message//\"/\\\"}\" with title \"${title//\"/\\\"}\"" \
            &>/dev/null || true
    else
        command -v notify-send &>/dev/null && \
            notify-send "$title" "$message" &>/dev/null || true
    fi
}
