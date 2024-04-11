#!/bin/bash

[ -z "$1" ] && { echo "Error: No directory specified."; exit 1; }

# Expands the directory name to its absolute path
DIR=$(readlink -f "$1")

# Define the wipsync directory and list file
WIPSYNC_DIR="$HOME/.wipsync"
LIST_FILE="$WIPSYNC_DIR/dir_list"

# Ensure the list file exists
if [ ! -f "$LIST_FILE" ]; then
    echo "The list file does not exist."
    exit 1
fi

# Check if the directory is in the list and remove it
if grep -Fxq "$DIR" "$LIST_FILE"; then
    # Remove the directory from the list
    grep -Fxv "$DIR" "$LIST_FILE" > "$WIPSYNC_DIR/temp_list"
    mv "$WIPSYNC_DIR/temp_list" "$LIST_FILE"
    echo "Directory removed from the list."
else
    echo "This directory is not in the list."
    exit 2
fi
