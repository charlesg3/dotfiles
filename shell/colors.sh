#!/usr/bin/env bash
# Panda Syntax color theme — single source of truth.
# Sourced by common.sh, zsh/zshrc, and bash/bashrc.
#
# Structure:
#   1. Raw palette   — hex values, named once
#   2. Semantic map  — feature names → palette names
#   3. Derivations   — ANSI codes, bash PS1 tokens, and zsh PROMPT tokens
#                      all computed from the semantic hex values

# ── 1. Raw palette ────────────────────────────────────────────────────────────
PANDA_BG="#1A1B1C"
PANDA_FG="#E6E6E6"
PANDA_RED="#FF4040"             # pure red (prompt separator)
PANDA_HOT_PINK="#FF2C6D"       # bright magenta-red / error
PANDA_PINK="#FF75B5"            # keywords
PANDA_LIGHT_PINK="#FF9AC1"     # keyword variants / bright magenta
PANDA_CURSOR="#FF4B82"          # cursor
PANDA_CYAN="#8CF0E4"            # strings (pale mint)
PANDA_LIME="#A8F0A6"            # prompt / UI accents (lime green)
PANDA_BLUE="#6FC1FF"            # functions / bright blue
PANDA_LIGHT_BLUE="#45A9F9"     # escape chars / tags
PANDA_ORANGE="#FFB86C"          # constants
PANDA_LIGHT_ORANGE="#FFCC95"   # operators / variables / bright yellow
PANDA_PURPLE="#B084EB"          # tags / class names (medium purple)
PANDA_LAVENDER="#B1B9F5"        # UI accents / branch (light periwinkle lavender)
PANDA_COMMENT="#676B79"         # comments / dim text
PANDA_SELECTION="#31353A"       # selection background / line highlight

# ── 2. Semantic map ───────────────────────────────────────────────────────────
# Syntax
COLOR_BG="$PANDA_BG"
COLOR_FG="$PANDA_FG"
COLOR_KEYWORD="$PANDA_PINK"
COLOR_STRING="$PANDA_CYAN"
COLOR_FUNCTION="$PANDA_BLUE"
COLOR_CONSTANT="$PANDA_ORANGE"
COLOR_VARIABLE="$PANDA_LIGHT_ORANGE"
COLOR_OPERATOR="$PANDA_LIGHT_ORANGE"
COLOR_TAG="$PANDA_PURPLE"
COLOR_BRANCH="$PANDA_LAVENDER"      # git branch / Claude emphasis
COLOR_ESCAPE="$PANDA_LIGHT_BLUE"
COLOR_COMMENT="$PANDA_COMMENT"
COLOR_ERROR="$PANDA_HOT_PINK"
COLOR_WARNING="$PANDA_ORANGE"
COLOR_INFO="$PANDA_BLUE"

# Shell UI
COLOR_OK="$PANDA_LIME"          # ✓ success
COLOR_UPDATED="$PANDA_BLUE"     # ↑ updated
COLOR_WARN="$PANDA_ORANGE"      # ~ warning
COLOR_ERR="$PANDA_HOT_PINK"     # ✗ error
COLOR_HEADER="$PANDA_PINK"      # section headers
COLOR_DIM="$PANDA_COMMENT"      # secondary text

# Prompt
COLOR_PROMPT_OK="$PANDA_LIME"          # ▸ on success
COLOR_PROMPT_ERR="$PANDA_HOT_PINK"    # ▸ on error
COLOR_PROMPT_USER="$PANDA_LIME"
COLOR_PROMPT_SEP="$PANDA_RED"          # @ separator (pure red)
COLOR_PROMPT_HOST="$PANDA_LIME"
COLOR_PROMPT_DIR="$PANDA_BLUE"
COLOR_PROMPT_DOLLAR="$PANDA_ORANGE"

# ── 3. Derivations ────────────────────────────────────────────────────────────

# Helper: hex color → 24-bit ANSI foreground escape sequence
# Usage: _ansi_fg "#RRGGBB"  →  \033[38;2;R;G;Bm
_ansi_fg() {
    local hex="${1#\#}"
    printf '\033[38;2;%d;%d;%dm' \
        "$((16#${hex:0:2}))" "$((16#${hex:2:2}))" "$((16#${hex:4:2}))"
}

# General ANSI codes (for echo/printf in scripts)
ANSI_RESET='\033[0m'
ANSI_BOLD='\033[1m'
ANSI_DIM='\033[2m'
ANSI_OK="$(_ansi_fg "$COLOR_OK")"
ANSI_UPDATED="$(_ansi_fg "$COLOR_UPDATED")"
ANSI_WARN="$(_ansi_fg "$COLOR_WARN")"
ANSI_ERR="$(_ansi_fg "$COLOR_ERR")"
ANSI_HEADER="$(_ansi_fg "$COLOR_HEADER")"

# Bash PS1 tokens — same ANSI codes wrapped in \[...\] for readline
_PS_RESET='\[\033[0m\]'
_PS_PROMPT_OK="\[$(_ansi_fg "$COLOR_PROMPT_OK")\]"
_PS_PROMPT_ERR="\[$(_ansi_fg "$COLOR_PROMPT_ERR")\]"
_PS_PROMPT_USER="\[$(_ansi_fg "$COLOR_PROMPT_USER")\]"
_PS_PROMPT_SEP="\[$(_ansi_fg "$COLOR_PROMPT_SEP")\]"
_PS_PROMPT_HOST="\[$(_ansi_fg "$COLOR_PROMPT_HOST")\]"
_PS_PROMPT_DIR="\[$(_ansi_fg "$COLOR_PROMPT_DIR")\]"
_PS_PROMPT_DOLLAR="\[$(_ansi_fg "$COLOR_PROMPT_DOLLAR")\]"

# Zsh PROMPT tokens — %F{#hex} uses hex directly (requires zsh 5.7+)
ZSH_PROMPT_RESET='%f'
ZSH_PROMPT_OK="%F{$COLOR_PROMPT_OK}"
ZSH_PROMPT_ERR="%F{$COLOR_PROMPT_ERR}"
ZSH_PROMPT_USER="%F{$COLOR_PROMPT_USER}"
ZSH_PROMPT_SEP="%F{$COLOR_PROMPT_SEP}"
ZSH_PROMPT_HOST="%F{$COLOR_PROMPT_HOST}"
ZSH_PROMPT_DIR="%F{$COLOR_PROMPT_DIR}"
ZSH_PROMPT_DOLLAR="%F{$COLOR_PROMPT_DOLLAR}"
ZSH_PROMPT_FG="%F{$COLOR_FG}"

# ── Tool env vars ─────────────────────────────────────────────────────────────
export BAT_THEME="ansi"      # inherit terminal's ANSI palette (set in kitty/theme.conf)
export GLAMOUR_STYLE=~/src/dotfiles/shell/glamour.json
