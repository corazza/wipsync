# wipsync

This repository holds the `wipsync` command, its prompt snippet, its systemd user service and `install.sh`; `README.md` documents them.
The repository is public, so commit no machine name, account, address, absolute home path or other personal data.
Before a push, scan every unpushed commit and its message with the private patterns in `~/.config/submit/private.toml`, which needs Python 3.11 or newer for `tomllib`.
Run the three commands below in one shell.
The first joins the patterns into one expression and prints an error when it cannot read them; then the scan is void, so do not push.
The other two must print nothing:

```bash
pattern="$(uv run --no-project --python '>=3.11' python -c 'import pathlib, tomllib; patterns = tomllib.loads((pathlib.Path.home() / ".config/submit/private.toml").read_text())["patterns"] + [r"/(home|Users)/[\w.-]+"]; print("|".join(f"(?:{p})" for p in patterns))')" || echo 'the private patterns could not be read; do not push' >&2
git grep -nIiP -e "$pattern" HEAD $(git rev-list '@{u}..HEAD')
git log --format='%H %an <%ae> %cn <%ce>%n%B' --name-only '@{u}..HEAD' | grep -niP -e "$pattern"
```

`wipsync` alone prints the help page and changes nothing; every action needs its command word.
The owner's dotfiles install `src/wipsync.sh`, `src/wipsync-prompt.bash` and `wipsync-daemon.service` from a pinned commit of this repository, so a rename of one of these files needs a change in the dotfiles too.
Run `uv run --no-project python -m unittest discover -s tests -v` before each commit.
The tests run the commands and `install.sh` in a temporary home with a recording `systemctl`, and they check the resulting files and calls, never the source text.
