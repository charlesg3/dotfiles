#!/usr/bin/env bash
# shell/poll.sh — sourceable generic polling loop with animated countdown.
#
# SOURCE this file; do not execute it directly.
# Requires shell/lib.sh to be sourced first (or sources it automatically).
#
# Usage:
#   source /path/to/shell/poll.sh
#
#   # Define these functions before calling poll_until:
#   poll_test()       — run the check; echo a result string to stdout
#   poll_success()    — receives result as $1; return 0 to stop polling
#   poll_on_result()  — (optional) display status after each attempt
#
#   # Configure (optional — all have defaults):
#   POLL_INTERVAL=300       # seconds between attempts
#   POLL_SPIN_INTERVAL=0.5  # animation refresh rate in seconds
#   POLL_TITLE="Poll"       # OS notification title on success
#   POLL_SUCCESS_MSG="Done" # OS notification message on success
#
#   poll_until

_POLL_SH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Auto-source lib.sh if helpers aren't already loaded
declare -f ok &>/dev/null || source "${_POLL_SH_DIR}/lib.sh"

POLL_INTERVAL="${POLL_INTERVAL:-300}"
POLL_SPIN_INTERVAL="${POLL_SPIN_INTERVAL:-0.5}"
POLL_TITLE="${POLL_TITLE:-Poll}"
POLL_SUCCESS_MSG="${POLL_SUCCESS_MSG:-Done}"

# ---------------------------------------------------------------------------
# _poll_countdown SECONDS
# Animated progress bar + braille spinner + orange clock, refreshing at
# POLL_SPIN_INTERVAL. Clears the line when done.
# ---------------------------------------------------------------------------
_poll_countdown() {
    local total="$1"
    local cols bar_width
    cols=$(tput cols 2>/dev/null || echo 80)
    bar_width=$(( cols - 20 ))
    [[ $bar_width -lt 10 ]] && bar_width=10

    local -a SPINNER=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )
    # Number of animation ticks for the full interval
    local ticks
    ticks=$(awk "BEGIN { printf \"%d\", $total / $POLL_SPIN_INTERVAL }")

    local i j filled empty bar frame=0
    for (( i = ticks; i >= 0; i-- )); do
        filled=$(( (ticks - i) * bar_width / ticks ))
        empty=$(( bar_width - filled ))

        bar="${ANSI_SPIN}"
        for (( j = 0; j < filled; j++ )); do bar+="█"; done
        bar+="${ANSI_DIM}"
        for (( j = 0; j < empty; j++ )); do bar+="░"; done
        bar+="${ANSI_RESET}"

        local remaining
        remaining=$(awk "BEGIN { printf \"%d\", $i * $POLL_SPIN_INTERVAL }")
        local mins=$(( remaining / 60 ))
        local secs=$(( remaining % 60 ))
        local sf="${SPINNER[$(( frame % ${#SPINNER[@]} ))]}"
        (( frame++ )) || true

        printf "\r  %s↻%s  %s  %s%s%s %s%02d:%02d%s " \
            "$ANSI_SPIN" "$ANSI_RESET" \
            "$bar" \
            "$ANSI_SPIN" "$sf" "$ANSI_RESET" \
            "$ANSI_CLOCK" "$mins" "$secs" "$ANSI_RESET"

        sleep "$POLL_SPIN_INTERVAL"
    done
    printf '\r\033[2K'
}

# ---------------------------------------------------------------------------
# poll_until
# Calls poll_test, checks poll_success, loops with countdown until success.
# ---------------------------------------------------------------------------
poll_until() {
    local attempt=0 result

    while true; do
        (( attempt++ )) || true
        spin "Attempt ${attempt}"
        result=$(poll_test 2>&1)
        clear_spin

        POLL_TIME="$(date '+%H:%M:%S')"
        if declare -f poll_on_result &>/dev/null; then
            poll_on_result "$result"
        else
            info "${ANSI_COMMENT}[${POLL_TIME}]${ANSI_RESET} $result"
        fi

        if poll_success "$result"; then
            notify_os "$POLL_TITLE" "$POLL_SUCCESS_MSG"
            ring_bell
            return 0
        fi

        _poll_countdown "$POLL_INTERVAL"
    done
}
