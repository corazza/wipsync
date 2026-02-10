# WIPSync

Track the status of your git repositories across directories and get reminded of uncommitted or unpushed changes.

> **Note:** Requires GNU coreutils (`readlink -f`). Works on Linux out of the box. macOS users need `brew install coreutils`.

## Installation

To install `wipsync`, run the provided installation script:

```bash
./install.sh
```

This script will:

1. Create a `~/.local/bin` directory if it doesn't exist.
2. Copy the scripts to `~/.local/bin` and remove the `.sh` extension.
3. Add `~/.local/bin` to your `PATH` in `~/.bashrc` if it's not already there.
4. Install a **systemd user service** (`wipsync-daemon`) that periodically checks tracked repos in the background.
5. Add a **prompt integration** to `~/.bashrc` that shows `(*)` in your terminal prompt when any tracked repo has uncommitted changes.

After installation, please restart your terminal or run:

```bash
source ~/.bashrc
```

## Usage

`wipsync` helps you track the status of your git repositories across different directories.

### Add a Directory

To start tracking repositories within a directory, use the `add` command:

```bash
wipsync add /path/to/your/projects
```

This will add the directory to `~/.wipsync/dir_list`.

### Remove a Directory

To stop tracking a directory, use the `remove` command:

```bash
wipsync remove /path/to/your/projects
```

### Check Status

To check the status of all repositories in your tracked directories:

```bash
wipsync status
```

Or simply:

```bash
wipsync
```

This will list all repositories found within the tracked directories.

- `(*)` — repository has uncommitted changes (dirty working tree or staged files)
- `(^)` — repository has commits that haven't been pushed to the upstream branch
- `(*^)` — both uncommitted changes and unpushed commits

### List Tracked Directories

To see all directories currently being tracked:

```bash
wipsync list
```

### Help

To see usage information and available commands:

```bash
wipsync help
```

## Prompt Integration

After installation, your bash prompt will automatically show `(*)` whenever any tracked repository has uncommitted changes. The indicator appears at the beginning of your prompt:

```
(*) yann@host:~/repos/project$         # dirty repos detected
yann@host:~/repos/project$             # all clean
(venv) (*) yann@host:~/repos/project$  # with a Python venv active
```

This works via a background daemon (`wipsync-daemon`) that checks your tracked repos every 30 seconds and writes the result to `~/.wipsync/prompt_status`. The prompt itself just reads that one-byte file — there is zero git overhead per prompt.

### Configuration

Set the `WIPSYNC_INTERVAL` environment variable to change the check interval (in seconds, default: 30):

```bash
# In your systemd override or environment
WIPSYNC_INTERVAL=60
```

### Managing the Daemon

The daemon runs as a systemd user service:

```bash
systemctl --user status wipsync-daemon   # check status
systemctl --user restart wipsync-daemon  # restart
systemctl --user stop wipsync-daemon     # stop
journalctl --user -u wipsync-daemon      # view logs
```

## Extras

### Reminder Image Generator

A Python script is included in `py/main.py` that generates a `reminder.png` image with the text "Did you commit and push your code today?".

To use it, ensure you have `Pillow` >= 10.0 installed:

```bash
pip install Pillow
```

Then run the script:

```bash
python3 py/main.py
```
