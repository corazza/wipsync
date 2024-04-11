#!/bin/bash

DIR_LIST="$HOME/.wipsync/dir_list"
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
    fi
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
        check_git_status "$repo"
    done < <(find "$dir" -type d -name ".git")
done < "$DIR_LIST"

# Function that prints the list of dirty repositories (takes the list as an argument)
print_dirty_repos() {
    local -n repos=$1
    echo "Dirty repos:"
    for repo in "${repos[@]}"; do
        echo "* $repo"
    done
}


# Print repositories with uncommitted changes
if [ ${#dirty_repos[@]} -eq 0 ]; then
    echo "No repositories with uncommitted changes."
else
    print_dirty_repos dirty_repos

    # Print git status for each dirty repository
    for repo in "${dirty_repos[@]}"; do
        echo -e "\n============================\n$repo:\n============================\n"
        git -C "$repo" status
    done

    echo -e ""
    print_dirty_repos dirty_repos
fi
