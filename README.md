# WIPSync

Automatically sync repo progress across devices to a WIP branch.

## Installation

To install `wipsync`, run the provided installation script:

```bash
./install.sh
```

This script will:
1. Create a `~/.local/bin` directory if it doesn't exist.
2. Copy the scripts to `~/.local/bin` and remove the `.sh` extension.
3. Add `~/.local/bin` to your `PATH` in `~/.bashrc` if it's not already there.

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

This will list all repositories found within the tracked directories. Repositories with uncommitted changes will be marked with `(*)`.

## Extras

### Reminder Image Generator

A Python script is included in `py/main.py` that generates a `reminder.png` image with the text "Did you commit and push your code today?".

To use it, ensure you have `Pillow` installed:

```bash
pip install Pillow
```

Then run the script:

```bash
python3 py/main.py
```