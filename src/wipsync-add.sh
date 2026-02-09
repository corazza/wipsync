#!/bin/bash
set -euo pipefail

[ -z "${1:-}" ] && { echo "Error: No directory specified."; exit 1; }

# Expands the directory name to its absolute path
DIR=$(readlink -f "$1")

# Check if the directory exists
if [ ! -d "$DIR" ]; then
    echo "The directory does not exist."
    exit 1
fi

# Ensure the wipsync directory exists
WIPSYNC_DIR="$HOME/.wipsync"
mkdir -p "$WIPSYNC_DIR"
LIST_FILE="$WIPSYNC_DIR/dir_list"

# Ensure the list file exists before trying to grep it
touch "$LIST_FILE"

# Check if the directory is already in the list
if grep -Fxq "$DIR" "$LIST_FILE"; then
    echo "This directory is already on the list."
    exit 2
else
    # Add the directory to the list
    echo "$DIR" >> "$LIST_FILE"
    echo "Directory added to the list."
fi
