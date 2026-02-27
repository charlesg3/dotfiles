#!/usr/bin/env bash
# Claude Code status line — single line, left/right sections
#   LEFT:  [⠋ | ● 42s]  📁 dirname   🌿 branch  +N ~N
#   RIGHT: ▓▓░░░░░░░░  12%   💰 $0.04   ⏱️ 2m 15s

input=$(cat)

SESSION_ID=$(echo "$input" | jq -r '.session_id // ""')
DIR=$(echo "$input"        | jq -r '.workspace.current_dir // ""')
PCT=$(echo "$input"        | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
COST=$(echo "$input"       | jq -r '.cost.total_cost_usd // 0')
DURA=$(echo "$input"       | jq -r '.cost.total_duration_ms // 0')

GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; DIM='\033[2m'; RESET='\033[0m'

# ── Spinner / ready ──────────────────────────────────────────────────────────
# Counter-based: each statusline call advances the frame, so it actually animates
# during streaming (called per token) rather than relying on wall-clock seconds.

SPINNERS=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
if [ -n "$SESSION_ID" ] && [ -f "/tmp/claude-start-${SESSION_ID}" ]; then
    SPIN_FILE="/tmp/claude-sl-spin-${SESSION_ID}"
    FRAME=$(( ($(cat "$SPIN_FILE" 2>/dev/null || echo 0) + 1) % 10 ))
    printf '%s' "$FRAME" > "$SPIN_FILE"
    STATE="${SPINNERS[$FRAME]}"
    STATE_PLAIN="${SPINNERS[$FRAME]}"
else
    LAST=""
    [ -n "$SESSION_ID" ] && [ -f "/tmp/claude-last-time-${SESSION_ID}" ] \
        && LAST=" $(cat "/tmp/claude-last-time-${SESSION_ID}")"
    STATE="${GREEN}●${LAST}${RESET}"
    STATE_PLAIN="●${LAST}"
fi

# ── Context bar (green < 70%, yellow 70–89%, red ≥ 90%) ─────────────────────

[ "$PCT" -ge 90 ] && BAR_COLOR="$RED" || { [ "$PCT" -ge 70 ] && BAR_COLOR="$YELLOW" || BAR_COLOR="$GREEN"; }
FILLED=$((PCT / 10)); EMPTY=$((10 - FILLED))
BAR="${BAR_COLOR}$(printf "%${FILLED}s" | tr ' ' '█')${RESET}${DIM}$(printf "%${EMPTY}s" | tr ' ' '░')${RESET}"
BAR_PLAIN="$(printf "%${FILLED}s" | tr ' ' '█')$(printf "%${EMPTY}s" | tr ' ' '░')"

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

# ── Left: [state]  📁 dirname   🌿 branch  +N  ~N ───────────────────────────

L="${STATE}  📁 ${DIR##*/}"
LP="${STATE_PLAIN}  📁 ${DIR##*/}"
if [ -n "$BRANCH" ]; then
    L="${L}   🌿 ${BRANCH}";  LP="${LP}   🌿 ${BRANCH}"
    if [ "${STAGED:-0}" -gt 0 ]; then
        L="${L}  ${GREEN}+${STAGED}${RESET}"; LP="${LP}  +${STAGED}"
    fi
    if [ "${MODIFIED:-0}" -gt 0 ]; then
        L="${L}  ${YELLOW}~${MODIFIED}${RESET}"; LP="${LP}  ~${MODIFIED}"
    fi
fi

# ── Right: ▓▓░░░░░░░░  12%   💰 $0.04   ⏱️ 2m 15s ──────────────────────────

R="${BAR}  ${PCT}%   ${YELLOW}💰 ${COST_FMT}${RESET}   ⏱️ ${MINS}m ${SECS}s"
RP="${BAR_PLAIN}  ${PCT}%   💰 ${COST_FMT}   ⏱️ ${MINS}m ${SECS}s"

# ── Padding (python for correct emoji/wide-char width) ───────────────────────

COLS=$(tput cols 2>/dev/null || echo 80)
read -r LW RW < <(python3 - "$LP" "$RP" <<'PYEOF'
import sys, unicodedata
def vlen(s):
    return sum(
        2 if unicodedata.east_asian_width(c) in ('W', 'F') else
        0 if unicodedata.category(c) in ('Mn', 'Me', 'Cf') else 1
        for c in s)
print(vlen(sys.argv[1]), vlen(sys.argv[2]))
PYEOF
)
PAD=$(( COLS - LW - RW ))
[ "$PAD" -lt 1 ] && PAD=1

# ── Output ────────────────────────────────────────────────────────────────────

printf '%b%*s%b\n' "$L" "$PAD" "" "$R"
