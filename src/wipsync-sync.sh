#!/bin/bash

WIPSYNC_DIR="$HOME/.wipsync"
REPO_CLONES_DIR="$WIPSYNC_DIR/repo_clones"
REPO_LIST="$WIPSYNC_DIR/repo_list"

# Check for the repository list file's existence
if [ ! -f "$REPO_LIST" ]; then
  echo "No repositories have been added."
  exit 1
fi

# Function to sync changes
sync_changes() {
    local original_repo_path=$1
    local clone_name=$2

    # Determine the current branch in the original repository
    local current_branch=$(git -C "$original_repo_path" rev-parse --abbrev-ref HEAD)
    if [[ $current_branch == "HEAD" ]]; then
        echo "Original repo is in a detached HEAD state, skipping: $original_repo_path"
        return
    fi

    local clone_path="$REPO_CLONES_DIR/$clone_name"

    echo "Syncing changes from $original_repo_path ($current_branch) to $clone_path (wipsync/$current_branch)"

    pushd "$clone_path" > /dev/null || return

    # Ensure the wipsync/ branch exists or create it
    if ! git rev-parse --verify --quiet "wipsync/$current_branch" > /dev/null; then
        echo "Creating branch: wipsync/$current_branch"
        git checkout -b "wipsync/$current_branch"
        # Since the branch is new, no need to pull from it. Skip straight to adding changes.
    else
        git checkout "wipsync/$current_branch"
        # If the branch already exists, it's safe to attempt to pull from it.
        git pull origin "wipsync/$current_branch" --no-edit || true
    fi

    # Rsync changes from the original repo, excluding .git and other non-tracked files
    rsync -av --exclude='.git/' --exclude='.gitignore' --filter=':- .gitignore' "$original_repo_path/" "$clone_path/"

    # Commit and push changes
    git add .
    if ! git diff --cached --quiet; then
        git commit -m "Automatic wipsync commit for $current_branch on $(date)"
        git push origin "wipsync/$current_branch"
    else
        echo "No changes detected, nothing to commit."
    fi

    popd > /dev/null
}

# Iterate over each repository and sync changes
while IFS=: read -r original_repo_path clone_name; do
    if [[ -d "$original_repo_path" && -d "$REPO_CLONES_DIR/$clone_name" ]]; then
        sync_changes "$original_repo_path" "$clone_name"
    else
        echo "Skipping $clone_name, original or clone repository does not exist."
    fi
done < "$REPO_LIST"
