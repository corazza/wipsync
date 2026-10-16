# wipsync

This repository holds the `wipsync` command, its prompt snippet, its systemd user service and `install.sh`; `README.md` documents them.
The repository is public, so commit no machine name, account, address, absolute home path or other personal data.
Before a push, scan the tracked files with the private patterns in `~/.config/submit/private.toml`; the command must print nothing:

```bash
git grep -nIiP -e '/home/[^/\s]+/' -e '/Users/[^/\s]+/' -f <(uv run --no-project python -c 'import pathlib, tomllib; print("\n".join(tomllib.loads((pathlib.Path.home() / ".config/submit/private.toml").read_text())["patterns"]))')
```

`wipsync` alone prints the help page and changes nothing; every action needs its command word.
A dotfiles installer can copy `src/wipsync.sh`, `src/wipsync-prompt.bash` and `wipsync-daemon.service` from a pinned commit, so a rename of one of them needs a change of that declaration too.
Run `uv run --no-project python -m unittest discover -s tests -v` before each commit.
The tests run the commands and `install.sh` in a temporary home with a recording `systemctl`, and they check the resulting files and calls, never the source text.
