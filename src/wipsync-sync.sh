#!/bin/bash

# Define the file to store repositories
REPO_LIST="$HOME/.wipsync_repos"

# Ensure the repository list file exists
if [ ! -f "$REPO_LIST" ]; then
  echo "No repositories have been added."
  exit 1
fi

while IFS= read -r repo_path; do
  repo=$(realpath "$repo_path")
  echo "Attempting to sync working changes for: $repo"
  
  if [ -d "$repo" ]; then
    pushd "$repo" > /dev/null || exit

    # Save current branch name
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    # Stash any uncommitted work with a unique stash message for identification
    stash_name="wipsync-$(date +%s)"
    git stash push -m "$stash_name"

    # Check out or create wip-branch
    git checkout wip-branch || git checkout -b wip-branch

    # Apply the stash if it exists
    stash_list=$(git stash list)
    if [[ $stash_list == *"$stash_name"* ]]; then
      git stash pop --index $(git stash list | grep -m 1 "$stash_name" | cut -d: -f1)
    fi

    # Commit and push if there were changes
    if [ -n "$(git status --porcelain)" ]; then
      git add .
      git commit -m "WIP sync on $(date)"
      git push origin wip-branch --force
      echo "Synced changes to wip-branch: $repo"
    else
      echo "No changes to sync for: $repo"
    fi

    # Return to the original branch
    git checkout "$current_branch"

    # If the original stash was applied, there's no need to pop it
    # as it has already been handled

    popd > /dev/null
  else
    echo "Directory does not exist: $repo"
  fi
done < "$REPO_LIST"
