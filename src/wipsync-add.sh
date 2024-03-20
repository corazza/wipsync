#!/bin/bash

# Directories for wipsync
WIPSYNC_DIR="$HOME/.wipsync"
REPO_CLONES_DIR="$WIPSYNC_DIR/repo_clones"
REPO_LIST="$WIPSYNC_DIR/repo_list"

# Ensure the wipsync directories exist
mkdir -p "$REPO_CLONES_DIR"

# Check if the path is provided
if [ $# -eq 0 ]; then
  echo "Usage: wipsync add <path/to/repo>"
  exit 1
fi

# Resolve the full path of the repository
REPO_PATH=$(realpath "$1")

# Extract repo name for cloning directory
REPO_NAME=$(basename "$REPO_PATH")

# Validate Git repository
if [ ! -d "$REPO_PATH/.git" ]; then
  echo "The given path does not appear to be a Git repository: $REPO_PATH"
  exit 1
fi

# Check if the repository is already added
if grep -Fq "$REPO_PATH" "$REPO_LIST" &>/dev/null; then
  echo "Repository already in list for WIP syncing: $REPO_PATH"
  exit 1
fi

# Clone the repository
git clone "$REPO_PATH" "$REPO_CLONES_DIR/$REPO_NAME" &>/dev/null

if [ $? -eq 0 ]; then
  # Enter the cloned repository directory
  pushd "$REPO_CLONES_DIR/$REPO_NAME" > /dev/null

  # Set the push URL for 'origin' to ensure it matches the fetch URL
  # This step may be adapted if a different push URL is needed
  git remote set-url --push origin "$REPO_PATH"

  popd > /dev/null

  # Add the repository full path and name to the list
  echo "$REPO_PATH:$REPO_NAME" >> "$REPO_LIST"
  echo "Repository added for WIP syncing: $REPO_PATH"
else
  echo "Failed to clone repository: $REPO_PATH"
fi
