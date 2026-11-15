"""Check that missing private configuration cannot trigger a system switch."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class BuildHelpers(unittest.TestCase):
    def test_missing_username(self):
        for helper in ("build", "build-switch"):
            with self.subTest(helper=helper), tempfile.TemporaryDirectory() as cwd:
                env = {**os.environ, "BLACKTAIL_HOST_PROFILE": "test-host"}
                env.pop("BLACKTAIL_USERNAME", None)
                result = subprocess.run(["bash", str(ROOT / "apps" / helper)], cwd=cwd,
                                        env=env, capture_output=True, text=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("Set BLACKTAIL_USERNAME", result.stderr)

    def test_missing_private_configuration(self):
        for helper in ("build", "build-switch"):
            with self.subTest(helper=helper), tempfile.TemporaryDirectory() as cwd:
                result = subprocess.run(
                    ["bash", str(ROOT / "apps" / helper)],
                    cwd=cwd,
                    env={**os.environ, "BLACKTAIL_HOST_PROFILE": "test-host", "BLACKTAIL_USERNAME": "test-user"},
                    capture_output=True,
                    text=True,
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("Private configuration is missing", result.stderr)
                self.assertNotIn("Starting", result.stdout)


if __name__ == "__main__":
    unittest.main()
