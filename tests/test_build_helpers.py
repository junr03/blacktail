"""Check build helper validation and sudo authentication without switching a host."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class BuildHelpers(unittest.TestCase):
    def run_switch(self, **overrides):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        cwd = Path(temporary.name)
        (cwd / "private-config").mkdir()
        (cwd / "private-config/default.nix").touch()
        binaries = cwd / "bin"
        binaries.mkdir()
        system = cwd / "system/sw/bin"
        system.mkdir(parents=True)
        scripts = {
            binaries / "sudo": """#!/bin/bash
printf 'sudo %s\\n' "$*" >> "$CALL_LOG"
if [[ "$*" == -v ]]; then
  exit "${AUTH_STATUS:-0}"
elif [[ "$*" == '-n -v' ]]; then
  touch "$REFRESHED"
else
  [[ "$1" == -n ]] && shift
  exec "$@"
fi
""",
            binaries / "sleep": """#!/bin/bash
echo "$$" >> "$SLEEP_PIDS"
if [[ ! -e "$REFRESHED" ]]; then
  exec /bin/sleep 0.01
fi
exec /bin/sleep 60
""",
            binaries / "nix": """#!/bin/bash
echo build >> "$CALL_LOG"
if [[ "${WAIT_FOR_REFRESH:-0}" == 1 ]]; then
  for ((i=0; i<200; i++)); do
    [[ -e "$REFRESHED" ]] && break
    /bin/sleep 0.01
  done
  [[ -e "$REFRESHED" ]] || exit 99
fi
[[ "${BUILD_STATUS:-0}" == 0 ]] || exit "$BUILD_STATUS"
echo "$TEST_SYSTEM"
""",
            system / "darwin-rebuild": """#!/bin/bash
echo switch >> "$CALL_LOG"
""",
        }
        for path, content in scripts.items():
            path.write_text(content)
            path.chmod(0o755)
        # Substitute only the fixed Nix executable; run the actual helper logic.
        helper = cwd / "build-switch"
        helper.write_text((ROOT / "apps/build-switch").read_text().replace(
            '/nix/var/nix/profiles/default/bin/nix', str(binaries / "nix")))
        log = cwd / "calls"
        result = subprocess.run(
            ["bash", str(helper)], cwd=cwd, capture_output=True, text=True, timeout=10,
            env={**os.environ, "PATH": f"{binaries}:{os.environ['PATH']}",
                 "BLACKTAIL_HOST_PROFILE": "test-host", "BLACKTAIL_USERNAME": "test-user",
                 "CALL_LOG": str(log), "TEST_SYSTEM": str(cwd / "system"),
                 "REFRESHED": str(cwd / "refreshed"), "SLEEP_PIDS": str(cwd / "sleep-pids"),
                 **overrides},
        )
        # No refresh timer should survive a completed or failed run.
        if (cwd / "sleep-pids").exists():
            for pid in (cwd / "sleep-pids").read_text().splitlines():
                with self.assertRaises(ProcessLookupError):
                    os.kill(int(pid), 0)
        return result, log.read_text().splitlines()

    def test_switch_authenticates_before_build_and_refreshes(self):
        result, calls = self.run_switch(WAIT_FOR_REFRESH="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls[:2], ["sudo -v", "build"])
        self.assertIn("sudo -n -v", calls)
        self.assertEqual(calls[-1], "switch")
        self.assertTrue(calls[-2].startswith("sudo -n "))

    def test_switch_authentication_failure_prevents_build(self):
        result, calls = self.run_switch(AUTH_STATUS="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(calls, ["sudo -v"])

    def test_failed_build_does_not_switch(self):
        result, calls = self.run_switch(BUILD_STATUS="1", WAIT_FOR_REFRESH="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("switch", calls)

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
