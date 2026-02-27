#!/usr/bin/env bash
# Claude Code status line — single line, left/right sections
#   LEFT:  [⠋ | ↻ | ● 42s]  📁 dirname   🌿 branch  +N *N
#   RIGHT: ▓▓░░░░░░░░  92%   💰 $0.04   ⏱️ 2m 15s

input=$(cat)

SESSION_ID=$(echo "$input" | jq -r '.session_id // ""')
DIR=$(echo "$input"        | jq -r '.workspace.current_dir // ""')
# Use remaining_percentage to match Claude's "Context left" display
PCT=$(echo "$input" | jq -r '(100 - (.context_window.remaining_percentage // 100)) | floor')
COST=$(echo "$input"       | jq -r '.cost.total_cost_usd // 0')
DURA=$(echo "$input"       | jq -r '.cost.total_duration_ms // 0')

# shellcheck source=../shell/colors.sh
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../shell/colors.sh"
LIME="$ANSI_OK"; GREEN="$ANSI_OK"; YELLOW="$ANSI_WARN"; RED="$ANSI_ERR"
BLUE="$(_ansi_fg "$COLOR_INFO")"; PURPLE="$(_ansi_fg "$COLOR_BRANCH")"
DIM="$ANSI_DIM"; RESET="$ANSI_RESET"

# ── Working / ready ──────────────────────────────────────────────────────────

if [ -n "$SESSION_ID" ] && [ -f "/tmp/claude-start-${SESSION_ID}" ]; then
    STATE="${BLUE}↻ working${RESET}"; STATE_PLAIN="↻ working"
else
    if [ -n "$SESSION_ID" ] && [ -f "/tmp/claude-last-time-${SESSION_ID}" ]; then
        LAST=" $(cat "/tmp/claude-last-time-${SESSION_ID}")"
    else
        LAST=" ready"
    fi
    STATE="${LIME}●${LAST}${RESET}"
    STATE_PLAIN="●${LAST}"
fi

# ── Context bar (green < 70%, yellow 70–89%, red ≥ 90%) ─────────────────────

[ "${PCT:-0}" -ge 90 ] && BAR_COLOR="$RED" || { [ "${PCT:-0}" -ge 70 ] && BAR_COLOR="$YELLOW" || BAR_COLOR="$LIME"; }
FILLED=$(( ${PCT:-0} / 10 )); EMPTY=$((10 - FILLED))
_rep() { local s="$1" n="$2" r=""; for ((i=0; i<n; i++)); do r+="$s"; done; printf '%s' "$r"; }
BAR="${BAR_COLOR}$(_rep '█' "$FILLED")${RESET}${DIM}$(_rep '░' "$EMPTY")${RESET}"
BAR_PLAIN="$(_rep '█' "$FILLED")$(_rep '░' "$EMPTY")"

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

# ── Left: [state]  📁 dirname   🌿 branch  +N *N ────────────────────────────

L="${STATE}  📁 ${DIR##*/}"
LP="${STATE_PLAIN}  📁 ${DIR##*/}"
if [ -n "$BRANCH" ]; then
    L="${L}   🌿 ${PURPLE}${BRANCH}${RESET}";  LP="${LP}   🌿 ${BRANCH}"
    if [ "${STAGED:-0}" -gt 0 ]; then
        L="${L}  ${GREEN}+${STAGED}${RESET}"; LP="${LP}  +${STAGED}"
    fi
    if [ "${MODIFIED:-0}" -gt 0 ]; then
        L="${L}  ${YELLOW}*${MODIFIED}${RESET}"; LP="${LP}  *${MODIFIED}"
    fi
fi

# ── Right: ▓▓░░░░░░░░  92%   💰 $0.04   ⏱️ 2m 15s ──────────────────────────

R="${BAR}  ${PCT}%   ${YELLOW}💰 ${COST_FMT}${RESET}   ⏱️ ${MINS}m ${SECS}s"
RP="${BAR_PLAIN}  ${PCT}%   💰 ${COST_FMT}   ⏱️ ${MINS}m ${SECS}s"

# ── Padding (python for correct emoji/wide-char width) ───────────────────────

read -r LW RW COLS < <(python3 - "$LP" "$RP" <<'PYEOF'
import sys, unicodedata, os
def vlen(s):
    width = 0
    i = 0
    while i < len(s):
        c = s[i]
        # U+FE0F (variation selector-16) forces emoji presentation (2-wide)
        next_vs16 = (i + 1 < len(s) and s[i+1] == '\uFE0F')
        cat = unicodedata.category(c)
        ew  = unicodedata.east_asian_width(c)
        if cat in ('Mn', 'Me', 'Cf'):
            pass  # combining/format: zero width
        elif ew in ('W', 'F') or next_vs16:
            width += 2
        else:
            width += 1
        i += 1
    return width
cols = 120
try:
    fd = os.open('/dev/tty', os.O_RDONLY)
    cols = os.get_terminal_size(fd).columns
    os.close(fd)
except Exception:
    pass
print(vlen(sys.argv[1]), vlen(sys.argv[2]), cols)
PYEOF
)
LW=${LW:-0}; RW=${RW:-0}; COLS=${COLS:-120}
PAD=$(( COLS - LW - RW - 4 ))
[ "$PAD" -lt 1 ] && PAD=1

# ── Output ────────────────────────────────────────────────────────────────────

printf '%b%*s%b ' "$L" "$PAD" "" "$R"
