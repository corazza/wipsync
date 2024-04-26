#!/bin/bash

DIR_LIST="$HOME/.wipsync/dir_list"
declare -a repos=()
declare -a dirty_repos=()

# Ensure the dir_list file exists
if [ ! -f "$DIR_LIST" ]; then
    echo "The dir_list file does not exist."
    exit 1
fi

# Function to check for uncommitted changes in a repo
check_git_status() {
    local repo=$1
    if [ -n "$(git -C "$repo" status --porcelain)" ]; then
        dirty_repos+=("$repo")
        return 1
    fi
    return 0
}

# Iterate over parent directories to find all Git repositories
while IFS= read -r dir; do
    # Check if directory exists
    if [ ! -d "$dir" ]; then
        echo "Directory $dir does not exist. Skipping..."
        continue
    fi
    
    # Find and process all Git repositories within the directory
    while IFS= read -r gitdir; do
        repo=$(dirname "$gitdir")
        repos+=("$repo")
        check_git_status "$repo"
    done < <(find "$dir" -type d -name ".git")
done < "$DIR_LIST"

# Function that prints the list of all repositories with a star (*) before the dirty ones
print_all_repos_with_dirty_marker() {
    for repo in "${repos[@]}"; do
        local marker="   "
        for dirty in "${dirty_repos[@]}"; do
            if [[ $repo == $dirty ]]; then
                marker="(*)"
                break
            fi
        done
        echo "$marker $repo"
    done
}

# Print all repositories, marking dirty ones
print_all_repos_with_dirty_marker
