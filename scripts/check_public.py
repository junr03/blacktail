#!/usr/bin/env python3
"""Reject private Blacktail paths and high-confidence credential material."""

from __future__ import annotations

import fnmatch
import re
import subprocess
import sys
from pathlib import Path


PRIVATE_PATHS = {".blacktail.local", "hosts", "keys", "secrets"}
PRIVATE_PATH_PREFIXES = (
    "hosts/",
    "keys/",
    "secrets/",
    "private-config/",
)
PRIVATE_PATH_GLOBS = (
    "*.age",
    "**/*.age",
    "*.key",
    "**/*.key",
    "*.pem",
    "**/*.pem",
    "*.p12",
    "**/*.p12",
    "*.pfx",
    "**/*.pfx",
    "*credential*",
    "**/*credential*",
    "*password*",
    "**/*password*",
    "*secret*",
    "**/*secret*",
    "*token*",
    "**/*token*",
)

# Keep the patterns high-confidence. GitHub secret-scanning push protection is
# the provider-aware second layer; this checker also protects private material
# that GitHub cannot infer from a generic filename or token pattern.
CONTENT_PATTERNS = (
    (
        "private key material",
        r"-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----",
    ),
    ("age identity material", r"AGE-" + r"SECRET-KEY-"),
    (
        "GitHub token",
        r"(^|[^[:alnum:]_])(gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,})([^[:alnum:]_]|$)",
    ),
    ("AWS access key", r"(^|[^[:alnum:]])(AKIA|ASIA)[0-9A-Z]{16}([^[:alnum:]]|$)"),
    ("Slack token", r"(^|[^[:alnum:]_])xox[baprs]-[0-9A-Za-z-]{20,}([^[:alnum:]_]|$)"),
)


def run_git(*args: str) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(
        ["git", *args],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def repository_root() -> Path:
    result = run_git("rev-parse", "--show-toplevel")
    if result.returncode != 0:
        print("Public boundary check must run inside a Git repository.", file=sys.stderr)
        raise SystemExit(2)
    return Path(result.stdout.decode().strip())


def indexed_paths() -> list[tuple[str, str]]:
    result = run_git("ls-files", "--stage", "-z")
    if result.returncode != 0:
        print("Unable to read the Git index.", file=sys.stderr)
        if result.stderr:
            print(result.stderr.decode(errors="replace").strip(), file=sys.stderr)
        raise SystemExit(2)

    entries: list[tuple[str, str]] = []
    for record in result.stdout.split(b"\0"):
        if not record:
            continue
        metadata, path_bytes = record.rsplit(b"\t", 1)
        mode = metadata.split(maxsplit=1)[0].decode()
        entries.append((mode, path_bytes.decode(errors="surrogateescape")))
    return entries


def path_violations(entries: list[tuple[str, str]]) -> list[str]:
    violations: list[str] = []
    for mode, path in entries:
        # The submodule gitlink is the deliberate public/private boundary. Its
        # contents are not part of this repository's index.
        if path == "private-config" and mode == "160000":
            continue

        if path == "private-config" or path in PRIVATE_PATHS:
            violations.append(f"{path} (private path)")
            continue
        if any(path.startswith(prefix) for prefix in PRIVATE_PATH_PREFIXES):
            violations.append(f"{path} (private path)")
            continue
        if any(fnmatch.fnmatchcase(path, pattern) for pattern in PRIVATE_PATH_GLOBS):
            violations.append(f"{path} (private-looking path)")
    return violations


def content_violations() -> list[str]:
    violations: list[str] = []
    for label, pattern in CONTENT_PATTERNS:
        result = run_git(
            "grep",
            "--cached",
            "-I",
            "-n",
            "-E",
            "-e",
            pattern,
            "--",
        )
        if result.returncode == 1:
            continue
        if result.returncode != 0:
            print(f"Unable to scan indexed content for {label}.", file=sys.stderr)
            if result.stderr:
                print(result.stderr.decode(errors="replace").strip(), file=sys.stderr)
            raise SystemExit(2)

        for line in result.stdout.splitlines():
            path_bytes, separator, remainder = line.partition(b":")
            if not separator:
                violations.append(f"{path_bytes.decode(errors='replace')} ({label})")
                continue
            line_number, _, _ = remainder.partition(b":")
            violations.append(
                f"{path_bytes.decode(errors='replace')}:{line_number.decode(errors='replace')} ({label})"
            )
    return violations


def main() -> int:
    root = repository_root()
    violations = path_violations(indexed_paths())
    violations.extend(content_violations())
    if violations:
        print("Public boundary check failed:", file=sys.stderr)
        for violation in sorted(set(violations)):
            print(f"- {violation}", file=sys.stderr)
        print(
            "Put machine-specific configuration in blacktail-sensitive; do not bypass this check.",
            file=sys.stderr,
        )
        return 1

    print(f"Public boundary check passed for {root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
