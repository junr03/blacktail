"""Test the public/private repository boundary checker."""

from __future__ import annotations

import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
CHECKER = ROOT / "scripts" / "check_public.py"
ZERO_SHA = "0" * 40


def git(cwd: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=cwd,
        check=False,
        capture_output=True,
        text=True,
    )


class PublicBoundary(unittest.TestCase):
    def run_checker(
        self,
        cwd: Path,
        *args: str,
        input_text: str | None = None,
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(CHECKER), *args],
            cwd=cwd,
            check=False,
            capture_output=True,
            text=True,
            input="" if input_text is None else input_text,
            env={**os.environ, "GIT_CONFIG_NOSYSTEM": "1"},
        )

    def init_repository(self) -> Path:
        cwd = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, cwd)
        self.assertEqual(git(cwd, "init", "--quiet").returncode, 0)
        self.assertEqual(git(cwd, "config", "user.email", "test@example.invalid").returncode, 0)
        self.assertEqual(git(cwd, "config", "user.name", "Public Boundary Test").returncode, 0)
        self.assertEqual(git(cwd, "config", "commit.gpgsign", "false").returncode, 0)
        return cwd

    def commit_file(self, cwd: Path, relative_path: str, contents: str) -> str:
        destination = cwd / relative_path
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(contents, encoding="utf-8")
        self.assertEqual(git(cwd, "add", relative_path).returncode, 0)
        self.assertEqual(git(cwd, "commit", "--quiet", "-m", "test").returncode, 0)
        commit = git(cwd, "rev-parse", "HEAD")
        self.assertEqual(commit.returncode, 0)
        return commit.stdout.strip()

    def test_current_index_is_public(self) -> None:
        result = self.run_checker(ROOT)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_private_path_is_rejected_without_echoing_contents(self) -> None:
        cwd = self.init_repository()
        private_value = "machine-specific-value-that-must-not-be-public"
        private_path = "hosts/\tpersonal.nix"
        self.commit_file(cwd, private_path, private_value)

        result = self.run_checker(cwd)

        self.assertEqual(result.returncode, 1)
        self.assertIn(private_path, result.stderr)
        self.assertNotIn(private_value, result.stderr)

    def test_regular_private_config_directory_is_rejected(self) -> None:
        cwd = self.init_repository()
        self.commit_file(cwd, "private-config/default.nix", "{ }: { }\n")

        result = self.run_checker(cwd)

        self.assertEqual(result.returncode, 1)
        self.assertIn("private-config/default.nix", result.stderr)

    def test_commit_mode_scans_the_requested_tree(self) -> None:
        cwd = self.init_repository()
        private_path = "private-config/\tdefault.nix"
        commit = self.commit_file(cwd, private_path, "machine-specific-value\n")

        result = self.run_checker(cwd, "--commit", commit)

        self.assertEqual(result.returncode, 1)
        self.assertIn(private_path, result.stderr)

    def test_pre_push_scans_removed_private_files_in_introduced_commits(self) -> None:
        cwd = self.init_repository()
        base = self.commit_file(cwd, "README.md", "safe\n")
        private_value = "machine-specific-value-that-must-not-be-public"
        self.commit_file(cwd, "hosts/personal.nix", private_value)

        private_file = cwd / "hosts/personal.nix"
        private_file.unlink()
        self.assertEqual(git(cwd, "add", "-u").returncode, 0)
        self.assertEqual(git(cwd, "commit", "--quiet", "-m", "remove private file").returncode, 0)
        tip = git(cwd, "rev-parse", "HEAD")
        self.assertEqual(tip.returncode, 0)

        update = f"refs/heads/main {tip.stdout.strip()} refs/heads/main {base}\n"
        result = self.run_checker(
            cwd,
            "--pre-push",
            "--remote-name",
            "origin",
            input_text=update,
        )

        self.assertEqual(result.returncode, 1)
        self.assertIn("hosts/personal.nix", result.stderr)
        self.assertNotIn(private_value, result.stderr)

        result = self.run_checker(cwd, "--range", base, tip.stdout.strip())

        self.assertEqual(result.returncode, 1)
        self.assertIn("hosts/personal.nix", result.stderr)
        self.assertNotIn(private_value, result.stderr)

    def test_pre_push_excludes_history_already_on_another_remote_ref(self) -> None:
        cwd = self.init_repository()
        private_commit = self.commit_file(cwd, "hosts/personal.nix", "already-published\n")

        private_file = cwd / "hosts/personal.nix"
        private_file.unlink()
        self.assertEqual(git(cwd, "add", "-u").returncode, 0)
        self.assertEqual(git(cwd, "commit", "--quiet", "-m", "remove private file").returncode, 0)
        tip = git(cwd, "rev-parse", "HEAD")
        self.assertEqual(tip.returncode, 0)
        self.assertEqual(
            git(cwd, "update-ref", "refs/remotes/origin/main", private_commit).returncode,
            0,
        )

        update = f"refs/heads/new {tip.stdout.strip()} refs/heads/new {ZERO_SHA}\n"
        result = self.run_checker(
            cwd,
            "--pre-push",
            "--remote-name",
            "origin",
            input_text=update,
        )

        self.assertEqual(result.returncode, 0, result.stderr)

    def test_pre_push_allows_branch_deletion(self) -> None:
        cwd = self.init_repository()
        base = self.commit_file(cwd, "README.md", "safe\n")
        update = f"refs/heads/old {ZERO_SHA} refs/heads/old {base}\n"

        result = self.run_checker(
            cwd,
            "--pre-push",
            "--remote-name",
            "origin",
            input_text=update,
        )

        self.assertEqual(result.returncode, 0, result.stderr)

    def test_high_confidence_token_is_rejected_without_echoing_contents(self) -> None:
        cwd = self.init_repository()
        token = "gh" + "p_" + "123456789012345678901234567890123456"
        self.commit_file(cwd, "config.txt", token)

        result = self.run_checker(cwd)

        self.assertEqual(result.returncode, 1)
        self.assertIn("config.txt", result.stderr)
        self.assertIn("GitHub token", result.stderr)
        self.assertNotIn(token, result.stderr)

    def test_binary_token_is_rejected_without_echoing_contents(self) -> None:
        cwd = self.init_repository()
        token = "gh" + "p_" + "123456789012345678901234567890123456"
        destination = cwd / "binary.dat"
        destination.write_bytes(b"\x00" + token.encode() + b"\xff")
        self.assertEqual(git(cwd, "add", "binary.dat").returncode, 0)
        self.assertEqual(git(cwd, "commit", "--quiet", "-m", "test").returncode, 0)

        result = self.run_checker(cwd)

        self.assertEqual(result.returncode, 1)
        self.assertIn("binary.dat", result.stderr)
        self.assertIn("GitHub token", result.stderr)
        self.assertNotIn(token, result.stderr)


if __name__ == "__main__":
    unittest.main()
