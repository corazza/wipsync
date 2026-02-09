#!/bin/bash
set -euo pipefail

# Define the source directory of the scripts within the wipsync repository
SRC_DIR="$(dirname "$0")/src"

# Define the target directory for installation
TARGET_DIR="$HOME/.local/bin"

# Create the target directory if it doesn't already exist
mkdir -p "$TARGET_DIR"

# Ensure ~/.wipsync directory exists
mkdir -p "$HOME/.wipsync"

# Copy the functional scripts to the target directory and rename them to remove the .sh extension
for script in "$SRC_DIR"/wipsync*.sh; do
  script_basename=$(basename "$script" .sh) # Remove the .sh extension
  cp "$script" "$TARGET_DIR/$script_basename"
done

# Make sure the scripts are executable
chmod +x "$TARGET_DIR"/wipsync*

# --- Prompt integration ---
# Install the prompt snippet to ~/.wipsync/prompt.bash
cp "$SRC_DIR/wipsync-prompt.bash" "$HOME/.wipsync/prompt.bash"

# Source it from .bashrc (only once)
PROMPT_SOURCE_LINE='[ -f "$HOME/.wipsync/prompt.bash" ] && source "$HOME/.wipsync/prompt.bash"'
if ! grep -Fq 'wipsync/prompt.bash' "$HOME/.bashrc" 2>/dev/null; then
  echo "" >> "$HOME/.bashrc"
  echo "# wipsync: show (*) in prompt when tracked repos have uncommitted changes" >> "$HOME/.bashrc"
  echo "$PROMPT_SOURCE_LINE" >> "$HOME/.bashrc"
  echo "Added wipsync prompt integration to .bashrc"
fi

# --- Background daemon (systemd user service) ---
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"
cp "$(dirname "$0")/wipsync-daemon.service" "$SYSTEMD_USER_DIR/wipsync-daemon.service"

systemctl --user daemon-reload
systemctl --user enable --now wipsync-daemon.service
echo "wipsync-daemon service enabled and started."

# --- PATH ---
# Check if the target directory is in the user's PATH (exact match between colons)
if ! echo ":$PATH:" | grep -q ":$TARGET_DIR:"; then
  echo "Adding $TARGET_DIR to PATH in .bashrc"

  # Add the target directory to PATH in .bashrc
  echo "export PATH=\"\$PATH:$TARGET_DIR\"" >> "$HOME/.bashrc"
fi

echo ""
echo "Installation complete. Please restart your terminal or run 'source ~/.bashrc'."
