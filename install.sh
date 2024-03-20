#!/bin/bash

# Define the source directory of the scripts within the wipsync repository
SRC_DIR="$(dirname "$0")/src"

# Define the target directory for installation
TARGET_DIR="$HOME/.local/bin"

# Create the target directory if it doesn't already exist
mkdir -p "$TARGET_DIR"

# Copy the functional scripts to the target directory and rename them to remove the .sh extension
for script in "$SRC_DIR"/wipsync*.sh; do
  script_basename=$(basename "$script" .sh) # Remove the .sh extension
  cp "$script" "$TARGET_DIR/$script_basename"
done

# Make sure the scripts are executable
chmod +x "$TARGET_DIR"/wipsync*

# Check if the target directory is in the user's PATH
if ! echo "$PATH" | grep -q "$TARGET_DIR"; then
  echo "Adding $TARGET_DIR to PATH in .bashrc"

  # Add the target directory to PATH in .bashrc
  echo "export PATH=\"\$PATH:$TARGET_DIR\"" >> "$HOME/.bashrc"

  # Inform the user that they need to source their .bashrc or log out and back in
  echo "Installation complete. Please restart your terminal or run 'source ~/.bashrc' to update PATH."
else
  echo "Installation complete. $TARGET_DIR is already in PATH."
fi
