#!/usr/bin/env bash
# Packages nvim config for distribution to other machines.
# Bundle plugins are shallow-cloned (depth=1) to minimize size while
# keeping git remotes intact so the update script still works.

NVIM_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT="$HOME/nvim-config-$TIMESTAMP.tar.gz"
TMPDIR=$(mktemp -d)
DEST="$TMPDIR/.config/nvim"

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

echo -e "${BOLD}Packaging nvim config...${RESET}\n"

# Copy personal config files (not bundle/ or runtime junk)
mkdir -p "$DEST"
echo -e "${CYAN}Copying config files...${RESET}"
for item in init.vim after autoload plugin colors scripts bin macros doc; do
    if [ -e "$NVIM_DIR/$item" ]; then
        cp -r "$NVIM_DIR/$item" "$DEST/"
        echo -e "  ${GREEN}✓${RESET} $item"
    fi
done

# Shallow-clone each bundle plugin from its real remote
echo -e "\n${CYAN}Cloning bundle plugins (shallow)...${RESET}"
mkdir -p "$DEST/bundle"
FAILED=()
for dir in "$NVIM_DIR"/bundle/*/; do
    name="$(basename "$dir")"
    if [ -d "$dir/.git" ]; then
        remote=$(git -C "$dir" remote get-url origin)
        if git clone --depth=1 --quiet "$remote" "$DEST/bundle/$name" 2>/dev/null; then
            echo -e "  ${GREEN}✓${RESET} $name"
        else
            echo -e "  ${RED}✗${RESET} $name (clone failed)"
            FAILED+=("$name")
        fi
    else
        cp -r "$dir" "$DEST/bundle/$name"
        echo -e "  ${YELLOW}~${RESET} $name (no git, copied as-is)"
    fi
done

# Create the archive
echo -e "\n${CYAN}Creating archive...${RESET}"
tar -czf "$OUTPUT" -C "$TMPDIR" .config
rm -rf "$TMPDIR"

SIZE=$(du -sh "$OUTPUT" | cut -f1)
echo -e "\n${BOLD}${GREEN}Done!${RESET} ${OUTPUT} ${CYAN}(${SIZE})${RESET}"

if [ ${#FAILED[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}Warning: failed to clone: ${FAILED[*]}${RESET}"
fi
