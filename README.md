# WIPSync

Track the status of your git repositories across directories and get reminded of uncommitted or unpushed changes.

> **Note:** `install.sh` and the prompt indicator require Linux with a systemd user manager, which runs the background daemon.
> On WSL, enable systemd before you install.

## Installation

To install `wipsync`, run the provided installation script:

```bash
./install.sh
```

This script will:

1. Create a `~/.local/bin` directory if it doesn't exist.
2. Copy the one command, `src/wipsync.sh`, to `~/.local/bin/wipsync`.
3. Add `~/.local/bin` to your `PATH` in `~/.bashrc` if it's not already there.
4. Install a **systemd user service** (`wipsync-daemon`) that runs `wipsync daemon` to check tracked repos in the background.
5. Add a **prompt integration** to `~/.bashrc` that shows `(*)` in your terminal prompt when any tracked repo has uncommitted changes.

The script stops before it changes anything when no systemd user manager is running.

Earlier versions also installed `wipsync-add`, `wipsync-remove`, `wipsync-list`, `wipsync-status` and `wipsync-daemon` in `~/.local/bin`.
Delete those five files after you install this version.

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

This will list all repositories found within the tracked directories.
The search stops at the first repository on each path, so clones and test fixtures inside a repository, such as those in an ignored `tmp/` directory, are not listed.

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

Running `wipsync` without a command shows the same help and changes nothing.

## Prompt Integration

After installation, your bash prompt will automatically show `(*)` whenever any tracked repository has uncommitted changes.
The indicator appears at the beginning of your prompt:

```
(*) user@host:~/repos/project$         # dirty repos detected
user@host:~/repos/project$             # all clean
(venv) (*) user@host:~/repos/project$  # with a Python venv active
```

This works via a background daemon (`wipsync daemon`, run by the `wipsync-daemon` user service) that checks your tracked repos every 30 seconds and writes the result to `~/.wipsync/prompt_status`.
The prompt itself just reads that one-byte file — there is zero git overhead per prompt.

### Configuration

The daemon reads the check interval from `WIPSYNC_INTERVAL`, in seconds, with a default of 30.
The daemon runs as a systemd user service, so a variable set in your shell does not reach it; set it in a service override instead:

```bash
systemctl --user edit wipsync-daemon
```

Add these lines in the editor that opens, then restart the service:

```ini
[Service]
Environment=WIPSYNC_INTERVAL=60
```

```bash
systemctl --user restart wipsync-daemon
```

### Managing the Daemon

The daemon runs as a systemd user service:

```bash
systemctl --user status wipsync-daemon   # check status
systemctl --user restart wipsync-daemon  # restart
systemctl --user stop wipsync-daemon     # stop
journalctl --user -u wipsync-daemon      # view logs
```

## Tests

```bash
uv run --no-project python -m unittest discover -s tests -v
```

The tests run every command and `install.sh` with a temporary home directory, so they change no real prompt file, tracked list or `~/.bashrc`.
The `install.sh` tests replace `systemctl` with a recorder, so they change no real service.
