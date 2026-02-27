#!/usr/bin/env bash
# Claude Code status line
#   Line 1:  [◐◓◑◒ | ○ 42s]  📁 dirname   🌿 branch  +staged  ~modified
#   Line 2:  ▓▓▓░░░░░░░  30%   💰 $0.04   ⏱️ 2m 15s

input=$(cat)

SESSION_ID=$(echo "$input" | jq -r '.session_id // ""')
DIR=$(echo "$input"        | jq -r '.workspace.current_dir // ""')
PCT=$(echo "$input"        | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
COST=$(echo "$input"       | jq -r '.cost.total_cost_usd // 0')
DURA=$(echo "$input"       | jq -r '.cost.total_duration_ms // 0')

GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; DIM='\033[2m'; RESET='\033[0m'

# ── Spinner / ready state ────────────────────────────────────────────────────

SPINNERS=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
if [ -n "$SESSION_ID" ] && [ -f "/tmp/claude-start-${SESSION_ID}" ]; then
    FRAME=$(( $(date +%s) % 10 ))
    STATE="${SPINNERS[$FRAME]}"
else
    LAST=""
    [ -n "$SESSION_ID" ] && [ -f "/tmp/claude-last-time-${SESSION_ID}" ] \
        && LAST=" $(cat "/tmp/claude-last-time-${SESSION_ID}")"
    STATE="${DIM}○${LAST}${RESET}"
fi

# ── Context bar ──────────────────────────────────────────────────────────────

[ "$PCT" -ge 90 ] && BAR_COLOR="$RED" || { [ "$PCT" -ge 70 ] && BAR_COLOR="$YELLOW" || BAR_COLOR="$GREEN"; }
FILLED=$((PCT / 10)); EMPTY=$((10 - FILLED))
BAR="$(printf "%${FILLED}s" | tr ' ' '█')$(printf "%${EMPTY}s" | tr ' ' '░')"

# ── Cost and duration ────────────────────────────────────────────────────────

COST_FMT=$(printf '$%.2f' "$COST")
MINS=$((DURA / 60000)); SECS=$(((DURA % 60000) / 1000))

# ── Git (5s cache per project) ───────────────────────────────────────────────

CACHE="/tmp/claude-sl-$(printf '%s' "$DIR" | cksum | cut -d' ' -f1)"
_mtime() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0; }
if [ ! -f "$CACHE" ] || [ $(( $(date +%s) - $(_mtime "$CACHE") )) -gt 5 ]; then
    if git -C "$DIR" rev-parse --git-dir &>/dev/null; then
        BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
        S=$(git -C "$DIR" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
        M=$(git -C "$DIR" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
        printf '%s|%s|%s' "$BRANCH" "$S" "$M" > "$CACHE"
    else
        printf '||' > "$CACHE"
    fi
fi
IFS='|' read -r BRANCH STAGED MODIFIED < "$CACHE"

# ── Line 1: [state]  📁 dirname   🌿 branch  +N  ~N ─────────────────────────

GIT=""
if [ -n "$BRANCH" ]; then
    GIT="   🌿 ${BRANCH}"
    [ "${STAGED:-0}" -gt 0 ]   && GIT="${GIT}  ${GREEN}+${STAGED}${RESET}"
    [ "${MODIFIED:-0}" -gt 0 ] && GIT="${GIT}  ${YELLOW}~${MODIFIED}${RESET}"
fi
printf '%b\n' "${STATE}  📁 ${DIR##*/}${GIT}"

# ── Line 2: ▓▓▓░░░░░░░  30%   💰 $0.04   ⏱️ 2m 15s ─────────────────────────

printf '%b\n' "${BAR_COLOR}${BAR}${RESET}  ${PCT}%%   ${YELLOW}${COST_FMT}${RESET}   ⏱️ ${MINS}m ${SECS}s"
