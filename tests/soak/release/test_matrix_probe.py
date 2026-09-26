"""Exercise the native sibling's decisions with recorded-shape Actions metadata."""
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import matrix_probe


class MatrixSiblingTests(unittest.TestCase):
    def test_sibling_waits_for_observation_before_success_or_intentional_failure(self):
        for mode, expected in (('all-pass', 0), ('functional-failure', 1)):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as directory:
                output = Path(directory) / 'sibling'
                metadata = [json.dumps({'jobs': []}), json.dumps({'jobs': [{
                    'id': 123, 'name': 'probe / soak', 'steps': [{
                        'name': 'Observe live soak', 'status': 'in_progress'}]}]})]
                with patch.dict(os.environ, {'PROBE_MODE': mode, 'GITHUB_REPOSITORY': 'example/quick',
                                             'GITHUB_RUN_ID': '456'}), \
                     patch.object(matrix_probe.subprocess, 'check_output', side_effect=metadata) as api, \
                     patch.object(matrix_probe.time, 'sleep'):
                    self.assertEqual(matrix_probe.functional(output), expected)
                self.assertEqual(api.call_count, 2)
                self.assertEqual(matrix_probe.read(output / 'sibling-live.json')['soakJobId'], 123)

    def test_missing_live_sibling_cannot_pass_on_deadline(self):
        with tempfile.TemporaryDirectory() as directory, \
             patch.dict(os.environ, {'PROBE_MODE': 'all-pass'}):
            with self.assertRaisesRegex(RuntimeError, 'never reached'):
                matrix_probe.functional(Path(directory) / 'sibling', timeout_seconds=0)


if __name__ == '__main__':
    unittest.main()
