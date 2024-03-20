#!/bin/bash

# Directories for wipsync
WIPSYNC_DIR="$HOME/.wipsync"
REPO_CLONES_DIR="$WIPSYNC_DIR/repo_clones"
REPO_LIST="$WIPSYNC_DIR/repo_list"

# Check if the path is provided
if [ $# -eq 0 ]; then
  echo "Usage: wipsync remove <path/to/repo>"
  exit 1
fi

# Resolve the full path of the repository
REPO_PATH=$(realpath "$1")

# Extract repo name for removing directory
REPO_NAME=$(basename "$REPO_PATH")

# Validate if the repository is in the list
if ! grep -Fq "$REPO_PATH:$REPO_NAME" "$REPO_LIST"; then
  echo "Repository not found in WIP syncing list: $REPO_PATH"
  exit 1
fi

# Correctly remove the repository from the list
sed -i "/^${REPO_PATH//\//\\/}:$REPO_NAME$/d" "$REPO_LIST"

if [ $? -eq 0 ]; then
    echo "Repository removed from WIP syncing list: $REPO_PATH"
else
    echo "Failed to remove repository from WIP syncing list: $REPO_PATH"
    exit 1
fi

# Optional: Remove the cloned repository to clean up
read -p "Do you also want to remove the cloned repository for $REPO_NAME? (y/N) " answer
case ${answer:0:1} in
    y|Y )
        echo "Removing cloned repository for $REPO_NAME..."
        rm -rf "$REPO_CLONES_DIR/$REPO_NAME"
    ;;
    * )
        echo "Cloned repository kept: $REPO_CLONES_DIR/$REPO_NAME"
    ;;
esac
