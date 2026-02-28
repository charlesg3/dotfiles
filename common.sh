#!/usr/bin/env bash
# Shared utilities sourced by install scripts.

source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/shell/colors.sh"

BOLD="$ANSI_BOLD"
GREEN="$ANSI_OK"        # ✓ success  → Panda cyan
HEADER="$ANSI_HEADER"   # headers    → Panda lavender
YELLOW="$ANSI_WARN"     # ~ warning  → Panda orange
RED="$ANSI_ERR"         # ✗ error    → Panda hot pink
BLUE="$ANSI_UPDATED"    # ↻ spinner  → Panda blue
DIM="$ANSI_DIM"
RESET="$ANSI_RESET"

ok()          { echo -e "  ${GREEN}✓${RESET} $*"; }
updated()     { echo -e "  ${ANSI_UPDATED}↑${RESET} $*"; }
warn()        { echo -e "  ${YELLOW}~${RESET} $*"; }
err()         { echo -e "  ${RED}✗${RESET} $*"; }
header()      { echo -e "\n${BOLD}${HEADER}${*}${RESET}"; }
_spin()       { printf "  ${BLUE}↻${RESET}  %s..." "$1"; }
_clear_spin() { printf "\r\033[2K"; }
