"""Exercise DNS recovery without changing the machine's launchd services."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "ensure-dnsmasq"


class DnsmasqActivation(unittest.TestCase):
    def run_check(self, state, start_result="ok", answer="192.0.2.1"):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "state").write_text(state)
            commands = {
                "launchctl": '''#!/bin/bash
if [[ $1 == print ]]; then
  [[ $(cat "$TEST_DIR/state") == running ]] && echo 'state = running'
else
  echo kickstart >> "$TEST_DIR/calls"
  [[ $START_RESULT == ok ]] || exit 1
  echo running > "$TEST_DIR/state"
fi
''',
                "dig": '#!/bin/bash\nprintf "%s\\n" "$ANSWER"\n',
                "sleep": '#!/bin/bash\nexit 0\n',
            }
            for name, content in commands.items():
                path = root / name
                path.write_text(content)
                path.chmod(0o755)
            env = {**os.environ, "PATH": f"{root}:/usr/bin:/bin", "TEST_DIR": directory,
                   "START_RESULT": start_result, "ANSWER": answer}
            result = subprocess.run(["bash", str(SCRIPT), "example.test", "192.0.2.1"],
                                    env=env, capture_output=True, text=True)
            calls = (root / "calls").read_text() if (root / "calls").exists() else ""
            return result, calls

    def test_healthy_service_is_not_restarted(self):
        result, calls = self.run_check("running")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(calls, "")

    def test_stopped_service_is_recovered(self):
        result, calls = self.run_check("stopped")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(calls, "kickstart\n")

    def test_failed_start_fails_activation(self):
        result, _ = self.run_check("stopped", start_result="fail")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Failed to start", result.stderr)

    def test_wrong_dns_answer_fails_activation(self):
        result, calls = self.run_check("running", answer="192.0.2.2")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(calls, "kickstart\n")
        self.assertIn("did not become healthy", result.stderr)


if __name__ == "__main__":
    unittest.main()
