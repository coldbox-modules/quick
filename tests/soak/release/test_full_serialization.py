"""Timing decisions after the separately tested full raw-evidence verifier."""
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from verify_full_probe import epoch
from verify_full_serialization import serialization


class FullSerializationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.roots = [Path(self.temp.name) / str(i) for i in (1, 2)]
        for index, root in enumerate(self.roots):
            self.write(root / 'workflow.json', {'id': index+1, 'head_sha': 'a'*40,
                'run_started_at': '2026-01-01T00:00:00Z', 'updated_at': '2026-01-01T01:10:00Z'})
            start, end = ('01:00:00', '01:03:01') if index == 0 else ('01:03:02', '01:06:03')
            start, end = '2026-01-01T' + start + 'Z', '2026-01-01T' + end + 'Z'
            self.write(root / 'jobs.json', {'jobs': [
                {'name': 'Validation / soak /', 'completed_at': '2026-01-01T00:59:59Z'},
                {'name': 'Full receipt publication stub (no provider calls)', 'started_at': start, 'completed_at': end}]})
            self.write(root / 'artifacts/proof/qualified-publication-stub.json', {'holdSeconds': 180,
                'guardStartedAt': epoch(start), 'guardFinishedAt': epoch(end), 'packageSha256': str(index)*64})
            self.write(root / 'artifacts/release-soak-test/supervision/run/package/prepared.json',
                {'lastRelease': {'version': '1.0.0'}, 'version': '1.0.1'})

    def write(self, path, value):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(value))

    def test_separate_preparations_can_have_different_bytes_but_must_actually_contend(self):
        with patch('verify_full_serialization.verify', return_value={'passed': True, 'publicationRequired': True}):
            self.assertTrue(serialization(self.roots)['passed'])
            path = self.roots[1] / 'jobs.json'
            jobs = json.loads(path.read_text())
            jobs['jobs'][0]['completed_at'] = '2026-01-01T01:03:02Z'
            self.write(path, jobs)
            self.assertFalse(serialization(self.roots)['checks']['actualGuardContention'])

    def test_saved_success_does_not_override_raw_verification_failure(self):
        with patch('verify_full_serialization.verify', return_value={'passed': False, 'publicationRequired': True}):
            with self.assertRaisesRegex(ValueError, 'Both full matrices'):
                serialization(self.roots)

    def test_longer_declared_hold_still_requires_its_full_duration(self):
        for index, root in enumerate(self.roots):
            jobs = json.loads((root / 'jobs.json').read_text())
            start, end = ('01:00:00', '01:10:01') if index == 0 else ('01:10:02', '01:20:03')
            start, end = '2026-01-01T' + start + 'Z', '2026-01-01T' + end + 'Z'
            jobs['jobs'][1].update(started_at=start, completed_at=end)
            self.write(root / 'jobs.json', jobs)
            workflow = json.loads((root / 'workflow.json').read_text())
            workflow['updated_at'] = '2026-01-01T01:21:00Z'
            self.write(root / 'workflow.json', workflow)
            path = root / 'artifacts/proof/qualified-publication-stub.json'
            stub = json.loads(path.read_text())
            stub.update(holdSeconds=600, guardStartedAt=epoch(start), guardFinishedAt=epoch(end))
            self.write(path, stub)
        with patch('verify_full_serialization.verify', return_value={'passed': True, 'publicationRequired': True}):
            self.assertTrue(serialization(self.roots)['passed'])
            stub['guardFinishedAt'] = stub['guardStartedAt'] + 599
            self.write(path, stub)
            self.assertFalse(serialization(self.roots)['checks']['bothHeldForDeclaredDuration'])


if __name__ == '__main__':
    unittest.main()
