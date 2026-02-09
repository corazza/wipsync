#!/bin/bash
set -euo pipefail

[ -z "${1:-}" ] && { echo "Error: No directory specified."; exit 1; }

# Try to resolve absolute path; fall back to raw argument if dir was deleted
if resolved=$(readlink -f "$1" 2>/dev/null) && [ -n "$resolved" ]; then
    DIR="$resolved"
else
    # Strip trailing slashes for consistent matching
    DIR="${1%/}"
fi

# Define the wipsync directory and list file
WIPSYNC_DIR="$HOME/.wipsync"
LIST_FILE="$WIPSYNC_DIR/dir_list"

# Ensure the list file exists
if [ ! -f "$LIST_FILE" ]; then
    echo "The list file does not exist."
    exit 1
fi

# Use a safe temp file with cleanup trap
TEMP_FILE=$(mktemp "$WIPSYNC_DIR/temp_list.XXXXXX")
trap 'rm -f "$TEMP_FILE"' EXIT

# Check if the directory is in the list and remove it
if grep -Fxq "$DIR" "$LIST_FILE"; then
    # Remove the directory from the list (|| true: grep returns 1 if no lines remain)
    grep -Fxv "$DIR" "$LIST_FILE" > "$TEMP_FILE" || true
    mv "$TEMP_FILE" "$LIST_FILE"
    echo "Directory removed from the list."
else
    echo "This directory is not in the list."
    exit 2
fi
