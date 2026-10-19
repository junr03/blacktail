#!/usr/bin/env python3
"""Update the LightCraft Homebrew cask from its latest stable GitHub release."""

import json
import os
from pathlib import Path
import re
import sys
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parents[1]
CASK_PATH = ROOT / "Casks" / "lightcraft.rb"
RELEASE_URL = "https://api.github.com/repos/storytold/lightcraft/releases/latest"
VERSION_RE = re.compile(r"v?(\d+(?:\.\d+)+)\Z")
SHA256_RE = re.compile(r"sha256:([0-9a-f]{64})\Z")


def latest_release_version_and_sha256(release):
    if release.get("draft") or release.get("prerelease"):
        raise ValueError("GitHub returned a draft or prerelease for the latest release")

    tag = release.get("tag_name", "")
    version_match = VERSION_RE.fullmatch(tag)
    if version_match is None:
        raise ValueError(f"Unexpected LightCraft release tag: {tag!r}")
    version = version_match.group(1)

    asset_name = f"lightcraft-{version}-macos-universal.dmg"
    assets = [asset for asset in release.get("assets", []) if asset.get("name") == asset_name]
    if len(assets) != 1:
        raise ValueError(f"Expected one release asset named {asset_name!r}, found {len(assets)}")

    digest_match = SHA256_RE.fullmatch(assets[0].get("digest", ""))
    if digest_match is None:
        raise ValueError(f"GitHub did not provide a valid SHA-256 digest for {asset_name}")

    return version, digest_match.group(1)


def update_cask(cask_path, version, sha256):
    text = cask_path.read_text()
    replacements = (
        (re.compile(r'(?m)^  version "[^"]+"$'), f'  version "{version}"'),
        (re.compile(r'(?m)^  sha256 "[^"]+"$'), f'  sha256 "{sha256}"'),
    )

    for pattern, replacement in replacements:
        matches = list(pattern.finditer(text))
        if len(matches) != 1:
            raise ValueError(f"Expected exactly one {pattern.pattern!r} stanza, found {len(matches)}")
        text = pattern.sub(replacement, text, count=1)

    cask_path.write_text(text)


def fetch_latest_release():
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "blacktail-lightcraft-cask-updater",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"

    request = Request(RELEASE_URL, headers=headers)
    with urlopen(request, timeout=30) as response:
        return json.load(response)


def main():
    try:
        version, sha256 = latest_release_version_and_sha256(fetch_latest_release())
        update_cask(CASK_PATH, version, sha256)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"Could not update the LightCraft cask: {error}", file=sys.stderr)
        return 1

    print(f"Updated the LightCraft cask to {version}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
