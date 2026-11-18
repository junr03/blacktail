import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

import tomlkit

SCRIPT = Path(__file__).resolve().parents[1] / "scripts/merge-codex-config.py"


class MergeCodexConfigTest(unittest.TestCase):
    def test_merge_preserves_host_settings_and_is_idempotent(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            shared = root / "shared.toml"
            config = root / "config.toml"
            shared.write_text('approval_policy = "on-request"\napprovals_reviewer = "auto_review"\n[mcp_servers.shared]\nurl = "shared"\n')
            config.write_text('# host comment\napproval_policy = "never"\n[projects.local]\ntrust_level = "trusted"\n[mcp_servers.local]\nurl = "local"\n')
            config.chmod(0o600)
            command = [sys.executable, str(SCRIPT), str(shared), str(config)]
            subprocess.run(command, check=True)
            first = config.read_text()
            data = tomlkit.parse(first)
            self.assertEqual(data["approval_policy"], "on-request")
            self.assertEqual(data["approvals_reviewer"], "auto_review")
            self.assertEqual(data["projects"]["local"]["trust_level"], "trusted")
            self.assertEqual(data["mcp_servers"]["local"]["url"], "local")
            self.assertEqual(data["mcp_servers"]["shared"]["url"], "shared")
            self.assertIn("# host comment", first)
            self.assertEqual(config.stat().st_mode & 0o777, 0o600)
            subprocess.run(command, check=True)
            self.assertEqual(config.read_text(), first)

    def test_symlink_is_not_replaced(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            shared = root / "shared.toml"
            shared.write_text('model = "example"\n')
            target = root / "target.toml"
            target.write_text('model = "old"\n')
            config = root / "config.toml"
            os.symlink(target, config)
            result = subprocess.run([sys.executable, str(SCRIPT), str(shared), str(config)], capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertTrue(config.is_symlink())
            self.assertEqual(target.read_text(), 'model = "old"\n')


if __name__ == "__main__":
    unittest.main()
