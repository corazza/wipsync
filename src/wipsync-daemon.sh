#!/bin/bash
# wipsync-daemon: periodically checks tracked repos for uncommitted changes
# and writes status to ~/.wipsync/prompt_status for prompt integration.

DIR_LIST="$HOME/.wipsync/dir_list"
STATUS_FILE="$HOME/.wipsync/prompt_status"
INTERVAL="${WIPSYNC_INTERVAL:-30}"

mkdir -p "$HOME/.wipsync"

while true; do
    dirty=0

    if [ -f "$DIR_LIST" ]; then
        while IFS= read -r dir; do
            [[ -z "$dir" ]] && continue
            [ -d "$dir" ] || continue

            while IFS= read -r gitdir; do
                repo=$(dirname "$gitdir")
                if [ -n "$(git -C "$repo" status --porcelain 2>/dev/null)" ]; then
                    dirty=1
                    break 2
                fi
            done < <(find -P "$dir" -name ".git" -not -path "*/.git/*" -type d 2>/dev/null)
        done < "$DIR_LIST"
    fi

    printf '%s' "$dirty" > "$STATUS_FILE"
    sleep "$INTERVAL"
done
