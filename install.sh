#!/bin/bash
set -euo pipefail

# The daemon is a systemd user service, so stop before any change when no user manager runs.
if ! command -v systemctl >/dev/null || ! systemctl --user show-environment >/dev/null; then
  echo "wipsync: install.sh requires Linux with a systemd user manager; on WSL, enable systemd first" >&2
  exit 1
fi

# Define the source directory of the scripts within the wipsync repository
SRC_DIR="$(dirname "$0")/src"

# Define the target directory for installation
TARGET_DIR="$HOME/.local/bin"

# Create the target directory if it doesn't already exist
mkdir -p "$TARGET_DIR"

# Ensure ~/.wipsync directory exists
mkdir -p "$HOME/.wipsync"

# Install the one command; the daemon is its `wipsync daemon` command
cp "$SRC_DIR/wipsync.sh" "$TARGET_DIR/wipsync"
chmod +x "$TARGET_DIR/wipsync"

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
systemctl --user enable wipsync-daemon.service
# Restart, so that a running daemon of an earlier version stops.
systemctl --user restart wipsync-daemon.service
echo "wipsync-daemon service enabled and started."

# --- PATH ---
# Add the target directory to PATH in .bashrc, unless the shell or an earlier run already has it
PATH_LINE="export PATH=\"\$PATH:$TARGET_DIR\""
if ! echo ":$PATH:" | grep -q ":$TARGET_DIR:" && ! grep -Fxq "$PATH_LINE" "$HOME/.bashrc" 2>/dev/null; then
  echo "Adding $TARGET_DIR to PATH in .bashrc"
  echo "$PATH_LINE" >> "$HOME/.bashrc"
fi

echo ""
echo "Installation complete. Please restart your terminal or run 'source ~/.bashrc'."
