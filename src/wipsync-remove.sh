#!/bin/bash

# Define the file to store repositories
REPO_LIST="$HOME/.wipsync_repos"

# Check if the path is provided
if [ $# -eq 0 ]; then
  echo "Usage: wipsync remove <path/to/repo>"
  exit 1
fi

# Remove repository path from the list
if grep -Fxq "$1" "$REPO_LIST"; then
  grep -v "$1" "$REPO_LIST" > "$REPO_LIST.tmp" && mv "$REPO_LIST.tmp" "$REPO_LIST"
  echo "Repository removed: $1"
else
  echo "Repository not found in list: $1"
fi
