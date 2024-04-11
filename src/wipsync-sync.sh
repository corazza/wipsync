#!/bin/bash

DIR_LIST="$HOME/.wipsync/dir_list"

# Ensure the dir_list file exists
if [ ! -f "$DIR_LIST" ]; then
    echo "The dir_list file does not exist."
    exit 1
fi

commit_and_push() {
    local repo=$1
    cd "$repo" || return
    
    # Check for uncommitted changes using git status
    if [ -n "$(git status --porcelain)" ]; then
        echo "Adding uncommitted changes in $repo..."
        git add .
        git commit -m "WipSync auto-commit on $(date)"
        has_new_commit=1
    else
        has_new_commit=0
    fi
    
    # Check if there are commits to push. This considers both the new auto-commit and any previous unpushed commits.
    local to_push=$(git rev-list @{u}..HEAD 2>/dev/null)
    
    if [[ -n $to_push || $has_new_commit -eq 1 ]]; then
        echo "Pushing from $repo..."
        git push
    else
        echo "$repo is fully synced. No push needed."
    fi
    cd - > /dev/null
}

# Iterate over parent directories to find and process all Git repositories
while IFS= read -r dir; do
    # Check if directory exists
    if [ ! -d "$dir" ]; then
        echo "Directory $dir does not exist. Skipping..."
        continue
    fi
    
    # Find and commit & push changes in all Git repositories within the directory
    while IFS= read -r gitdir; do
        repo=$(dirname "$gitdir")
        commit_and_push "$repo"
    done < <(find "$dir" -type d -name ".git")
done < "$DIR_LIST"
