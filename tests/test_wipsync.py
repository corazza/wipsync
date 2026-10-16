import os
from pathlib import Path
import signal
import subprocess
import tempfile
import time
import unittest


ROOT = Path(__file__).resolve().parents[1]


class WipsyncTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix="wipsync-test-")
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name).resolve()
        self.home = self.directory / "home"
        self.home.mkdir()
        self.state = self.home / ".wipsync"
        self.projects = self.directory / "projects with spaces"
        self.projects.mkdir()
        # Git reads no variable or configuration of the caller, so a run from a Git hook cannot write to this repository's index.
        # Without the user bus, a command that a test forgot to replace cannot reach a real service.
        inherited = {
            name: value for name, value in os.environ.items()
            if not name.startswith("GIT_") and name not in ("XDG_RUNTIME_DIR", "DBUS_SESSION_BUS_ADDRESS")
        }
        self.env = {
            **inherited,
            "HOME": str(self.home),
            "XDG_CONFIG_HOME": str(self.home / ".config"),
            "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_AUTHOR_NAME": "Fixture",
            "GIT_AUTHOR_EMAIL": "fixture@example.invalid",
            "GIT_COMMITTER_NAME": "Fixture",
            "GIT_COMMITTER_EMAIL": "fixture@example.invalid",
        }

    def invoke(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["bash", str(ROOT / "src/wipsync.sh"), *arguments],
            cwd=self.directory, env=self.env, text=True, capture_output=True, timeout=30,
        )

    def git(self, repository: Path, *arguments: str) -> None:
        subprocess.run(["git", "-C", str(repository), *arguments], env=self.env, check=True, capture_output=True)

    def repository(self, path: Path) -> Path:
        path.mkdir(parents=True)
        self.git(path, "init", "--quiet", "--initial-branch=main")
        (path / "README").write_text("fixture\n")
        self.git(path, "add", "README")
        self.git(path, "commit", "--quiet", "-m", "fixture")
        return path

    def published(self, path: Path) -> Path:
        """Create a repository whose main branch tracks a bare origin."""
        origin = self.directory / "origins" / (path.name + ".git")
        origin.mkdir(parents=True)
        self.git(origin, "init", "--quiet", "--bare", "--initial-branch=main")
        self.repository(path)
        self.git(path, "remote", "add", "origin", str(origin))
        self.git(path, "push", "--quiet", "--set-upstream", "origin", "main")
        return path

    def track(self, directory: Path) -> None:
        self.assertEqual(self.invoke("add", str(directory)).returncode, 0)

    def status(self) -> dict[str, str]:
        result = self.invoke("status")
        self.assertEqual(result.returncode, 0, result.stderr)
        lines = result.stdout.splitlines()
        return {line[5:]: line[:4].strip() for line in lines}

    def test_bare_name_and_help_requests_print_help_without_changing_state(self) -> None:
        for arguments in ((), ("help",), ("-h",), ("--help",)):
            result = self.invoke(*arguments)
            self.assertEqual(result.returncode, 0, arguments)
            self.assertIn("Usage: wipsync", result.stdout)
        self.assertFalse(self.state.exists())

    def test_malformed_calls_fail_without_changing_state(self) -> None:
        directory = str(self.projects)
        for arguments in (
            ("bogus",), ("add",), ("add", directory, directory), ("remove",),
            ("status", "now"), ("list", "-a"), ("daemon", "now"),
        ):
            result = self.invoke(*arguments)
            self.assertNotEqual(result.returncode, 0, arguments)
            self.assertIn("Usage: wipsync", result.stderr)
        self.assertFalse(self.state.exists())

    def test_add_remove_and_list_round_trip(self) -> None:
        self.assertIn("No directories", self.invoke("list").stdout)
        self.assertEqual(self.invoke("add", str(self.directory / "missing")).returncode, 1)
        self.track(self.projects)
        self.assertEqual(self.invoke("add", str(self.projects) + "/").returncode, 2)
        listed = self.invoke("list").stdout
        self.assertIn(str(self.projects), listed)
        self.assertEqual(self.invoke("remove", str(self.projects) + "/").returncode, 0)
        self.assertIn("No directories", self.invoke("list").stdout)
        self.assertEqual(self.invoke("remove", str(self.projects)).returncode, 2)

    def test_status_lists_only_the_outermost_repository_on_each_path(self) -> None:
        outer = self.repository(self.projects / "outer")
        (outer / ".gitignore").write_text("tmp/\n")
        self.git(outer, "add", ".gitignore")
        self.git(outer, "commit", "--quiet", "-m", "ignore tmp")
        self.repository(outer / "tmp" / "fixture clone")
        # A nested repository that its parent does not ignore is the parent's untracked work.
        parent = self.repository(self.projects / "parent")
        self.repository(parent / "vendored" / "nested")
        deep = self.repository(self.projects / "group" / "deep")
        (self.projects / "plain").mkdir()
        self.track(self.projects)
        self.assertEqual(self.status(), {str(outer): "", str(parent): "(*)", str(deep): ""})

    def test_markers_report_uncommitted_and_unpushed_work(self) -> None:
        clean = self.published(self.projects / "clean")
        dirty = self.published(self.projects / "dirty")
        (dirty / "draft").write_text("work\n")
        ahead = self.published(self.projects / "ahead")
        self.git(ahead, "commit", "--quiet", "--allow-empty", "-m", "local")
        both = self.published(self.projects / "both")
        self.git(both, "commit", "--quiet", "--allow-empty", "-m", "local")
        (both / "README").write_text("changed\n")
        self.track(self.projects)
        self.assertEqual(
            self.status(), {str(clean): "", str(dirty): "(*)", str(ahead): "(^)", str(both): "(*^)"}
        )

    def test_unreadable_subdirectory_does_not_hide_a_later_tracked_directory(self) -> None:
        first = self.directory / "first"
        locked = first / "locked"
        locked.mkdir(parents=True)
        locked.chmod(0)
        self.addCleanup(locked.chmod, 0o700)
        self.assertFalse(os.access(locked, os.R_OK), "run the tests as a user without root, who cannot read the directory")
        later = self.repository(self.projects / "later")
        self.track(first)
        self.track(self.projects)
        self.assertEqual(self.status(), {str(later): ""})

    def test_daemon_rewrites_the_prompt_status_every_interval(self) -> None:
        repository = self.repository(self.projects / "work")
        self.track(self.projects)
        (repository / "draft").write_text("work\n")
        daemon = subprocess.Popen(
            ["bash", str(ROOT / "src/wipsync.sh"), "daemon"],
            env={**self.env, "WIPSYNC_INTERVAL": "0.2"}, start_new_session=True,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )

        def stop() -> None:
            os.killpg(daemon.pid, signal.SIGTERM)
            daemon.wait(timeout=10)

        self.addCleanup(stop)
        self.wait_for_prompt_status("1")
        (repository / "draft").unlink()
        self.wait_for_prompt_status("0")

    def wait_for_prompt_status(self, expected: str) -> None:
        path = self.state / "prompt_status"
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            if path.is_file() and path.read_text() == expected:
                return
            time.sleep(0.05)
        self.fail(f"prompt_status did not become {expected}")

    def install(self, systemctl_status: int) -> subprocess.CompletedProcess[str]:
        """Run install.sh with a systemctl that records its calls and exits with the given status."""
        bin_directory = self.directory / "bin"
        bin_directory.mkdir(exist_ok=True)
        calls = self.directory / "systemctl-calls"
        systemctl = bin_directory / "systemctl"
        systemctl.write_text(f'#!/usr/bin/env bash\nprintf "%s\\n" "$*" >> "{calls}"\nexit {systemctl_status}\n')
        systemctl.chmod(0o700)
        return subprocess.run(
            ["bash", str(ROOT / "install.sh")],
            cwd=self.directory, text=True, capture_output=True, timeout=30,
            env={**self.env, "PATH": str(bin_directory) + os.pathsep + self.env["PATH"]},
        )

    def test_install_without_a_user_manager_changes_nothing(self) -> None:
        result = self.install(1)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("systemd user manager", result.stderr)
        self.assertEqual(list(self.home.iterdir()), [])
        self.assertEqual((self.directory / "systemctl-calls").read_text().splitlines(), ["--user show-environment"])

    def test_install_copies_the_files_enables_the_daemon_and_can_be_repeated(self) -> None:
        self.assertEqual(self.install(0).returncode, 0)
        self.assertEqual(self.install(0).returncode, 0)
        self.assertEqual((self.home / ".local/bin/wipsync").read_bytes(), (ROOT / "src/wipsync.sh").read_bytes())
        self.assertTrue(os.access(self.home / ".local/bin/wipsync", os.X_OK))
        self.assertEqual(
            (self.home / ".wipsync/prompt.bash").read_bytes(), (ROOT / "src/wipsync-prompt.bash").read_bytes()
        )
        self.assertEqual(
            (self.home / ".config/systemd/user/wipsync-daemon.service").read_bytes(),
            (ROOT / "wipsync-daemon.service").read_bytes(),
        )
        bashrc = (self.home / ".bashrc").read_text()
        self.assertEqual(bashrc.count('source "$HOME/.wipsync/prompt.bash"'), 1)
        self.assertEqual(bashrc.count('export PATH="$PATH:%s"' % (self.home / ".local/bin")), 1)
        calls = (self.directory / "systemctl-calls").read_text().splitlines()
        self.assertIn("--user enable wipsync-daemon.service", calls)
        self.assertIn("--user restart wipsync-daemon.service", calls)


if __name__ == "__main__":
    unittest.main()
