#!/bin/bash

# Define the file to store repositories
REPO_LIST="$HOME/.wipsync_repos"

# Ensure the repository list file exists
if [ ! -f "$REPO_LIST" ]; then
  echo "No repositories have been added."
  exit 1
fi

while IFS= read -r repo; do
  echo "Syncing repository: $repo"
  if [ -d "$repo" ]; then
    cd "$repo" || exit
    git checkout -B wip-branch
    git add .
    git commit -m "WIP commit on $(date)"
    git push -u origin wip-branch --force
    echo "Synced repository: $repo"
  else
    echo "Directory does not exist: $repo"
  fi
done < "$REPO_LIST"
