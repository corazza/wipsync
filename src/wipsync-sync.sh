#!/bin/bash

DIR_LIST="$HOME/.wipsync/dir_list"

# Ensure the dir_list file exists
if [ ! -f "$DIR_LIST" ]; then
    echo "The dir_list file does not exist."
    exit 1
fi

# Function to check and commit uncommitted changes
commit_and_push() {
    local repo=$1
    cd "$repo" || return
    
    # Check for uncommitted changes using git status
    if [ -n "$(git status --porcelain)" ]; then
        echo "Adding uncommitted changes in $repo..."
        git add .
        git commit -m "WipSync auto-commit on $(date)"
    fi
    
    # Push the commits to the default remote's default branch
    echo "Pushing from $repo..."
    git push
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
