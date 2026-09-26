from pathlib import Path
import subprocess
import sys
import traceback
import unittest
from unittest.mock import Mock
import urllib.error

sys.path.insert(0, str(Path(__file__).parents[1]))
from controller import Controller


class DiagnosticHttpTests(unittest.TestCase):
    def test_process_timeout_preserves_failure_without_recording_authentication(self):
        controller = Controller.__new__(Controller)
        controller.app = 'owned-application'
        controller.env = {'SOAK_TOKEN': 'private-test-token'}
        controller.docker = Mock(side_effect=subprocess.TimeoutExpired(
            ['curl', '-H', 'X-Soak-Token: private-test-token'], 7))
        try:
            controller.http('/diagnostics', timeout=5)
            self.fail('A timed-out diagnostic request must not succeed')
        except urllib.error.URLError as error:
            self.assertIn('7-second process deadline', str(error))
            self.assertNotIn('private-test-token', traceback.format_exc())
        self.assertEqual(controller.docker.call_args.kwargs['timeout'], 7)


if __name__ == '__main__':
    unittest.main()
