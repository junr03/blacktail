#!/usr/bin/env python3
"""Reject private Blacktail paths and high-confidence credential material."""

from __future__ import annotations

import argparse
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
        re.compile(rb"-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----"),
    ),
    ("age identity material", re.compile(rb"AGE-" + rb"SECRET-KEY-")),
    (
        "GitHub token",
        re.compile(
            rb"(?<![A-Za-z0-9_])(?:gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,})(?![A-Za-z0-9_])"
        ),
    ),
    (
        "AWS access key",
        re.compile(rb"(?<![A-Za-z0-9])(?:AKIA|ASIA)[0-9A-Z]{16}(?![A-Za-z0-9])"),
    ),
    (
        "Slack token",
        re.compile(rb"(?<![A-Za-z0-9_])xox[baprs]-[0-9A-Za-z-]{20,}(?![A-Za-z0-9_])"),
    ),
)
ZERO_SHA = "0" * 40
SHA_PATTERN = re.compile(r"[0-9a-fA-F]{40}")
GitEntry = tuple[str, str, str]


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


def indexed_entries() -> list[GitEntry]:
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
        metadata, path_bytes = record.split(b"\t", 1)
        fields = metadata.split()
        entries.append(
            (
                fields[0].decode(),
                fields[1].decode(),
                path_bytes.decode(errors="surrogateescape"),
            )
        )
    return entries


def indexed_paths() -> list[tuple[str, str]]:
    return [(mode, path) for mode, _, path in indexed_entries()]


def revision_entries(revision: str) -> list[GitEntry]:
    result = run_git("ls-tree", "-r", "-z", "--full-tree", revision)
    if result.returncode != 0:
        print("Unable to read the requested Git tree.", file=sys.stderr)
        raise SystemExit(2)

    entries: list[tuple[str, str]] = []
    for record in result.stdout.split(b"\0"):
        if not record:
            continue
        metadata, path_bytes = record.split(b"\t", 1)
        fields = metadata.split()
        entries.append(
            (
                fields[0].decode(),
                fields[2].decode(),
                path_bytes.decode(errors="surrogateescape"),
            )
        )
    return entries


def revision_paths(revision: str) -> list[tuple[str, str]]:
    return [(mode, path) for mode, _, path in revision_entries(revision)]


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


def content_violations(entries: list[GitEntry]) -> list[str]:
    """Find credential material in blob contents without echoing blob data."""

    violations: list[str] = []
    blobs: dict[str, bytes] = {}
    for mode, object_id, path in entries:
        if mode == "160000":
            continue
        if object_id not in blobs:
            result = run_git("cat-file", "blob", object_id)
            if result.returncode != 0:
                print(f"Unable to scan indexed content for {path}.", file=sys.stderr)
                if result.stderr:
                    print(result.stderr.decode(errors="replace").strip(), file=sys.stderr)
                raise SystemExit(2)
            blobs[object_id] = result.stdout

        contents = blobs[object_id]
        for label, pattern in CONTENT_PATTERNS:
            for match in pattern.finditer(contents):
                line_number = contents.count(b"\n", 0, match.start()) + 1
                violations.append(f"{path}:{line_number} ({label})")
    return violations


def resolve_commit(sha: str, *, required: bool) -> str | None:
    if not SHA_PATTERN.fullmatch(sha):
        if required:
            print("Unable to resolve a pushed commit.", file=sys.stderr)
            raise SystemExit(2)
        return None
    result = run_git("rev-parse", "--verify", f"{sha}^{{commit}}")
    if result.returncode == 0:
        return result.stdout.decode().strip()
    if required:
        print("Unable to resolve a pushed commit.", file=sys.stderr)
        raise SystemExit(2)
    return None


def remote_tracking_commits(remote_name: str | None) -> list[str]:
    if remote_name is None:
        return []
    if not re.fullmatch(r"[A-Za-z0-9.@_/-]+", remote_name):
        print("The pre-push check received an invalid remote name.", file=sys.stderr)
        raise SystemExit(2)

    result = run_git(
        "for-each-ref",
        "--format=%(objectname)",
        f"refs/remotes/{remote_name}/",
    )
    if result.returncode != 0:
        print("Unable to enumerate remote-tracking refs.", file=sys.stderr)
        raise SystemExit(2)
    return [line.decode().strip() for line in result.stdout.splitlines() if line]


def introduced_commits(
    local_sha: str,
    remote_sha: str,
    remote_name: str | None = None,
) -> list[str]:
    local_commit = resolve_commit(local_sha, required=True)
    assert local_commit is not None

    exclusions: list[str] = []
    if remote_sha != ZERO_SHA:
        remote_commit = resolve_commit(remote_sha, required=False)
        if remote_commit is not None:
            exclusions.append(remote_commit)
    exclusions.extend(remote_tracking_commits(remote_name))

    args = ["rev-list", local_commit]
    if exclusions:
        args.extend(["--not", *dict.fromkeys(exclusions)])

    result = run_git(*args)
    if result.returncode != 0:
        print("Unable to enumerate commits for a pushed ref.", file=sys.stderr)
        raise SystemExit(2)
    return [line.decode().strip() for line in result.stdout.splitlines() if line]


def parse_ref_updates(updates: list[bytes], remote_name: str | None) -> set[str]:
    commits: set[str] = set()
    for update in updates:
        fields = update.split()
        if len(fields) != 4:
            print("The pre-push check received an invalid ref update.", file=sys.stderr)
            raise SystemExit(2)

        local_sha = fields[1].decode(errors="replace")
        remote_sha = fields[3].decode(errors="replace")
        if not SHA_PATTERN.fullmatch(local_sha) or not SHA_PATTERN.fullmatch(remote_sha):
            print("The pre-push check received an invalid commit id.", file=sys.stderr)
            raise SystemExit(2)
        if local_sha == ZERO_SHA:
            continue
        commits.update(introduced_commits(local_sha, remote_sha, remote_name))
    return commits


def pushed_commits(remote_name: str | None) -> list[str]:
    updates = sys.stdin.buffer.read().splitlines()
    if updates:
        return sorted(parse_ref_updates(updates, remote_name))
    print("The pre-push check received no ref updates.", file=sys.stderr)
    raise SystemExit(2)


def check_revision(revision: str) -> list[str]:
    entries = revision_entries(revision)
    violations = path_violations([(mode, path) for mode, _, path in entries])
    violations.extend(content_violations(entries))
    return violations


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    source = parser.add_mutually_exclusive_group()
    source.add_argument(
        "--commit",
        metavar="SHA",
        help="scan a committed tree instead of the current index",
    )
    source.add_argument(
        "--pre-push",
        action="store_true",
        help="read pre-push ref updates and scan all introduced commits",
    )
    source.add_argument(
        "--range",
        nargs=2,
        metavar=("BASE", "HEAD"),
        help="scan every commit reachable from HEAD but not BASE",
    )
    parser.add_argument(
        "--remote-name",
        help="remote name associated with --pre-push ref updates",
    )
    args = parser.parse_args()

    root = repository_root()
    if args.pre_push:
        revisions = pushed_commits(args.remote_name)
        violations: list[str] = []
        for revision in revisions:
            violations.extend(check_revision(revision))
        scope = "pushed commits"
    elif args.range:
        base, head = args.range
        revisions = introduced_commits(head, base)
        violations = []
        for revision in revisions:
            violations.extend(check_revision(revision))
        scope = "commits introduced by the requested range"
    elif args.commit:
        revision = resolve_commit(args.commit, required=True)
        assert revision is not None
        violations = check_revision(revision)
        scope = f"commit {revision}"
    else:
        entries = indexed_entries()
        violations = path_violations([(mode, path) for mode, _, path in entries])
        violations.extend(content_violations(entries))
        scope = "the Git index"

    if violations:
        print("Public boundary check failed:", file=sys.stderr)
        for violation in sorted(set(violations)):
            print(f"- {violation}", file=sys.stderr)
        print(
            "Put machine-specific configuration in blacktail-sensitive; do not bypass this check.",
            file=sys.stderr,
        )
        return 1

    print(f"Public boundary check passed for {root} ({scope})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
