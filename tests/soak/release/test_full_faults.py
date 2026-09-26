import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from full_faults import functional, live_soak, live_testbox, mode, read


class FullFaultTests(unittest.TestCase):
    def test_completed_launch_during_teardown_is_not_live_measurement(self):
        job = {'name': 'Validation / soak /', 'status': 'in_progress', 'steps': [
            {'name': 'Launch exact-package qualification and prove live work', 'conclusion': 'success', 'status': 'completed'},
            {'name': 'Observe the complete required soak', 'conclusion': '', 'status': 'in_progress'}]}
        self.assertTrue(live_soak(job))
        job['steps'][-1]['status'] = 'completed'
        self.assertFalse(live_soak(job))

    def test_job_setup_does_not_count_as_real_functional_work(self):
        job = {'name': 'Validation / functional / lucee@6', 'status': 'in_progress', 'steps': [
            {'name': 'Run TestBox Tests', 'status': 'pending'}]}
        self.assertFalse(live_testbox(job))
        job['steps'][0]['status'] = 'in_progress'
        self.assertTrue(live_testbox(job))
        job['status'] = 'completed'
        self.assertFalse(live_testbox(job))

    def test_all_pass_does_not_inject_or_wait(self):
        with tempfile.TemporaryDirectory() as directory, patch.dict(os.environ, {'FULL_PROBE_MODE': 'all-pass'}), \
                patch('full_faults.await_sibling') as wait:
            root = Path(directory)
            functional(root / 'output', root)
            wait.assert_not_called()
            self.assertEqual(list(root.iterdir()), [])

    def test_functional_injection_creates_exclusive_real_spec_after_sibling_boundary(self):
        with tempfile.TemporaryDirectory() as directory, patch.dict(os.environ, {'FULL_PROBE_MODE': 'functional-failure'}), \
                patch('full_faults.await_sibling', return_value={'id': 42}) as wait:
            root = Path(directory)
            (root / 'tests/specs').mkdir(parents=True)
            functional(root / 'output', root)
            wait.assert_called_once_with(live_soak)
            spec = root / 'tests/specs/SoakNativeFailureSpec.cfc'
            self.assertIn('expect( false ).toBeTrue', spec.read_text())
            self.assertEqual(read(root / 'output/functional-injection.json')['soakJobId'], 42)
            with self.assertRaises(FileExistsError):
                functional(root / 'output', root)

    def test_unknown_mode_does_not_silently_become_all_pass(self):
        with patch.dict(os.environ, {'FULL_PROBE_MODE': 'typo', 'GITHUB_REF_NAME': 'soak-release-proof-all-pass-demo'}):
            with self.assertRaises(ValueError):
                mode()


if __name__ == '__main__':
    unittest.main()
