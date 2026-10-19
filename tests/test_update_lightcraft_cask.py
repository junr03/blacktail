"""Tests for the LightCraft cask updater."""

import importlib.util
from pathlib import Path
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "update_lightcraft_cask", ROOT / "scripts" / "update_lightcraft_cask.py"
)
UPDATER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(UPDATER)


def release(tag="v0.9.1", digest=f"sha256:{'a' * 64}", **overrides):
    result = {
        "tag_name": tag,
        "draft": False,
        "prerelease": False,
        "assets": [
            {
                "name": "lightcraft-0.9.1-macos-universal.dmg",
                "digest": digest,
            }
        ],
    }
    result.update(overrides)
    return result


class LightCraftCaskUpdater(unittest.TestCase):
    def test_reads_release_version_and_digest(self):
        self.assertEqual(
            UPDATER.latest_release_version_and_sha256(release()),
            ("0.9.1", "a" * 64),
        )

    def test_rejects_prereleases(self):
        with self.assertRaises(ValueError):
            UPDATER.latest_release_version_and_sha256(release(prerelease=True))

    def test_rejects_missing_platform_asset(self):
        with self.assertRaises(ValueError):
            UPDATER.latest_release_version_and_sha256(release(assets=[]))

    def test_rejects_invalid_digest(self):
        with self.assertRaises(ValueError):
            UPDATER.latest_release_version_and_sha256(release(digest="sha256:bad"))

    def test_updates_only_version_and_checksum(self):
        old_sha256 = "b" * 64
        new_sha256 = "a" * 64
        original = (
            'cask "lightcraft" do\n'
            '  version "0.2.1"\n'
            f'  sha256 "{old_sha256}"\n\n'
            '  url "https://github.com/storytold/lightcraft/releases/download/v#{version}/lightcraft-#{version}-macos-universal.dmg"\n'
            '  app "LightCraft.app"\n'
            'end\n'
        )
        with tempfile.TemporaryDirectory() as directory:
            cask_path = Path(directory) / "lightcraft.rb"
            cask_path.write_text(original)

            UPDATER.update_cask(cask_path, "0.9.1", new_sha256)

            updated = cask_path.read_text()
        self.assertIn('  version "0.9.1"\n', updated)
        self.assertIn(f'  sha256 "{new_sha256}"\n', updated)
        self.assertIn("v#{version}/lightcraft-#{version}", updated)
        self.assertIn('  app "LightCraft.app"\n', updated)


if __name__ == "__main__":
    unittest.main()
