#!/bin/bash

# File to store repositories
REPO_LIST="$HOME/.wipsync_repos"

# Check if the path is provided
if [ $# -eq 0 ]; then
  echo "Usage: wipsync add <path/to/repo>"
  exit 1
fi

REPO_PATH=$1

# Add repository path to the list, avoiding duplicates
if ! grep -Fxq "$REPO_PATH" "$REPO_LIST"; then
  # Check if the given path is a valid Git repository
  if [ ! -d "$REPO_PATH/.git" ]; then
    echo "The given path does not appear to be a Git repository: $REPO_PATH"
    exit 1
  fi

  # Navigate to the repository directory
  cd "$REPO_PATH" || exit
  
  # Check if the wip-branch exists in the local repository
  if ! git rev-parse --verify wip-branch >/dev/null 2>&1; then
    # Branch doesn't exist, so let's create it without switching to it
    git branch wip-branch
    echo "wip-branch created in $REPO_PATH"
  else
    echo "wip-branch already exists in $REPO_PATH"
  fi
  
  # Add the repository to the list
  echo "$REPO_PATH" >> "$REPO_LIST"
  echo "Repository added for WIP syncing: $REPO_PATH"
else
  echo "Repository already in list for WIP syncing: $REPO_PATH"
fi
