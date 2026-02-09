#!/bin/bash
set -euo pipefail

DIR_LIST="$HOME/.wipsync/dir_list"
declare -a repos=()
declare -A dirty_map=()
declare -A unpushed_map=()

# Ensure the dir_list file exists
if [ ! -f "$DIR_LIST" ]; then
    echo "The dir_list file does not exist."
    exit 1
fi

# Function to check for uncommitted changes in a repo
check_git_status() {
    local repo=$1
    if [ -n "$(git -C "$repo" status --porcelain 2>/dev/null)" ]; then
        dirty_map["$repo"]=1
    fi
    # Check for commits that haven't been pushed to upstream
    if git -C "$repo" rev-parse --abbrev-ref '@{u}' &>/dev/null; then
        if [ -n "$(git -C "$repo" log --oneline '@{u}..HEAD' 2>/dev/null)" ]; then
            unpushed_map["$repo"]=1
        fi
    fi
}

# Iterate over parent directories to find all Git repositories
while IFS= read -r dir; do
    # Skip empty lines
    [[ -z "$dir" ]] && continue

    # Check if directory exists
    if [ ! -d "$dir" ]; then
        echo "Directory $dir does not exist. Skipping..."
        continue
    fi

    # Find and process all Git repositories within the directory
    # -P: don't follow symlinks; prune nested .git dirs to avoid submodule duplicates
    while IFS= read -r gitdir; do
        repo=$(dirname "$gitdir")
        repos+=("$repo")
        check_git_status "$repo"
    done < <(find -P "$dir" -name ".git" -not -path "*/.git/*" -type d 2>/dev/null)
done < "$DIR_LIST"

# Print all repositories with status markers
for repo in "${repos[@]}"; do
    local_dirty=""
    local_unpushed=""
    [[ -n "${dirty_map[$repo]:-}" ]] && local_dirty="*"
    [[ -n "${unpushed_map[$repo]:-}" ]] && local_unpushed="^"
    if [[ -n "$local_dirty" || -n "$local_unpushed" ]]; then
        marker="(${local_dirty}${local_unpushed})"
        # Pad to 4 chars for alignment
        printf "%-4s %s\n" "$marker" "$repo"
    else
        printf "     %s\n" "$repo"
    fi
done
