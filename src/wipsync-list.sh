#!/bin/bash
set -euo pipefail

DIR_LIST="$HOME/.wipsync/dir_list"

if [ ! -f "$DIR_LIST" ] || [ ! -s "$DIR_LIST" ]; then
    echo "No directories are currently being tracked."
    exit 0
fi

echo "Tracked directories:"
while IFS= read -r dir; do
    [[ -z "$dir" ]] && continue
    if [ -d "$dir" ]; then
        echo "  $dir"
    else
        echo "  $dir  (not found)"
    fi
done < "$DIR_LIST"
