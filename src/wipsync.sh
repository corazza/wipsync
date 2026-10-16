#!/bin/bash
set -euo pipefail

WIPSYNC_DIR="$HOME/.wipsync"
DIR_LIST="$WIPSYNC_DIR/dir_list"

usage() {
    echo "Usage: wipsync {add|remove|status|list|daemon|help}"
    echo ""
    echo "Commands:"
    echo "  add <dir>     Add a directory to track for git repositories"
    echo "  remove <dir>  Remove a directory from tracking"
    echo "  status        Show status of all tracked repositories"
    echo "  list          List all currently tracked directories"
    echo "  daemon        Update the prompt indicator every WIPSYNC_INTERVAL seconds (run by the user service)"
    echo "  help          Show this help message (also shown when no command is given)"
    echo ""
    echo "Status markers:"
    echo "  (*)   Uncommitted changes"
    echo "  (^)   Unpushed commits"
    echo "  (*^)  Both uncommitted changes and unpushed commits"
}

# Print each Git repository under the tracked directories, without following symlinks.
# Stop at the first repository on each path, because a repository's own status covers its submodules.
# Clones and test fixtures inside a repository, often in its ignored tmp/, are not separate work.
tracked_repos() {
    local dir
    while IFS= read -r dir; do
        [[ -z "$dir" ]] && continue
        if [ ! -d "$dir" ]; then
            echo "Directory $dir does not exist. Skipping..." >&2
            continue
        fi
        # An unreadable subdirectory makes find fail; the other tracked directories must still be searched.
        find -P "$dir" -type d -exec test -e '{}/.git' ';' -print -prune 2>/dev/null || true
    done < "$DIR_LIST"
}

cmd_add() {
    local dir
    # Expands the directory name to its absolute path
    if ! dir=$(readlink -f -- "$1") || [ ! -d "$dir" ]; then
        echo "The directory does not exist." >&2
        exit 1
    fi
    mkdir -p "$WIPSYNC_DIR"
    touch "$DIR_LIST"
    if grep -Fxq "$dir" "$DIR_LIST"; then
        echo "This directory is already on the list."
        exit 2
    fi
    echo "$dir" >> "$DIR_LIST"
    echo "Directory added to the list."
}

cmd_remove() {
    local dir resolved
    # Try to resolve absolute path; fall back to raw argument if dir was deleted
    if resolved=$(readlink -f "$1" 2>/dev/null) && [ -n "$resolved" ]; then
        dir="$resolved"
    else
        # Strip trailing slashes for consistent matching
        dir="${1%/}"
    fi
    if [ ! -f "$DIR_LIST" ]; then
        echo "The list file does not exist." >&2
        exit 1
    fi
    if ! grep -Fxq "$dir" "$DIR_LIST"; then
        echo "This directory is not in the list."
        exit 2
    fi
    # The EXIT trap runs after this function returns, so temp_file is not local.
    temp_file=$(mktemp "$WIPSYNC_DIR/temp_list.XXXXXX")
    trap 'rm -f "$temp_file"' EXIT
    # || true: grep returns 1 if no lines remain
    grep -Fxv "$dir" "$DIR_LIST" > "$temp_file" || true
    mv "$temp_file" "$DIR_LIST"
    echo "Directory removed from the list."
}

cmd_list() {
    local dir
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
}

cmd_status() {
    local repo marker
    if [ ! -f "$DIR_LIST" ]; then
        echo "The dir_list file does not exist." >&2
        exit 1
    fi
    while IFS= read -r repo; do
        marker=""
        [ -n "$(git -C "$repo" status --porcelain 2>/dev/null)" ] && marker="*"
        # Check for commits that haven't been pushed to upstream
        if git -C "$repo" rev-parse --abbrev-ref '@{u}' &>/dev/null &&
            [ -n "$(git -C "$repo" log --oneline '@{u}..HEAD' 2>/dev/null)" ]; then
            marker="$marker^"
        fi
        if [ -n "$marker" ]; then
            # Pad to 4 chars for alignment
            printf "%-4s %s\n" "($marker)" "$repo"
        else
            printf "     %s\n" "$repo"
        fi
    done < <(tracked_repos)
}

# Write 1 to ~/.wipsync/prompt_status while any tracked repository has uncommitted changes, else 0.
cmd_daemon() {
    local dirty repo
    mkdir -p "$WIPSYNC_DIR"
    while true; do
        dirty=0
        if [ -f "$DIR_LIST" ]; then
            while IFS= read -r repo; do
                if [ -n "$(git -C "$repo" status --porcelain 2>/dev/null)" ]; then
                    dirty=1
                    break
                fi
            done < <(tracked_repos 2>/dev/null)
        fi
        printf '%s' "$dirty" > "$WIPSYNC_DIR/prompt_status"
        sleep "${WIPSYNC_INTERVAL:-30}"
    done
}

# Print the help on stderr and fail when a command has the wrong number of arguments.
require_arguments() {
    if [ "$1" != "$2" ]; then
        echo "Error: wrong number of arguments for this command." >&2
        usage >&2
        exit 1
    fi
}

case "${1-}" in
    ""|help|-h|--help)
        usage
        ;;
    add)
        require_arguments $# 2
        cmd_add "$2"
        ;;
    remove)
        require_arguments $# 2
        cmd_remove "$2"
        ;;
    status)
        require_arguments $# 1
        cmd_status
        ;;
    list)
        require_arguments $# 1
        cmd_list
        ;;
    daemon)
        require_arguments $# 1
        cmd_daemon
        ;;
    *)
        echo "Invalid command: $1" >&2
        usage >&2
        exit 1
        ;;
esac
