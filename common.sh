#!/usr/bin/env bash
# Shared utilities sourced by install scripts.

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
DIM='\033[2m'
RESET='\033[0m'

ok()          { echo -e "  ${GREEN}✓${RESET} $*"; }
updated()     { echo -e "  ${CYAN}↑${RESET} $*"; }
warn()        { echo -e "  ${YELLOW}~${RESET} $*"; }
err()         { echo -e "  ${RED}✗${RESET} $*"; }
header()      { echo -e "\n${BOLD}${CYAN}${*}${RESET}"; }
_spin()       { printf "  ${DIM}⟳${RESET}  %s..." "$1"; }
_clear_spin() { printf "\r\033[2K"; }
