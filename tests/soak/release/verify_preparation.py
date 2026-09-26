"""Exercise the actual pinned semantic-release APIs against disposable Git history."""
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from prepare import prepare

TASK = Path(__file__).with_name('Prepare.cfc')


class PreparationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix='quick-soak-prepare-proof-')
        cls.root = Path(cls.temp.name)
        cls.repo = cls.root / 'repo'
        cls.repo.mkdir()
        cls.git('init', '-q')
        cls.git('config', 'user.email', 'soak@example.invalid')
        cls.git('config', 'user.name', 'Soak fixture')
        (cls.repo / 'box.json').write_text('{"slug":"quick","version":"13.0.4"}')
        cls.git('add', '.')
        cls.git('commit', '-qm', 'fix(base): released fixture')
        cls.base = cls.git('rev-parse', 'HEAD')
        cls.git('tag', 'v13.0.4')
        cls.last = {'version': '13.0.4', 'commitSha': cls.base, 'tag': 'v13.0.4',
                    'tagObjectSha': cls.base, 'forgeboxBinaryHash': 'test-only', 'githubReleaseId': 1}

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    @classmethod
    def git(cls, *args):
        return subprocess.check_output(['git', *args], cwd=cls.repo, stderr=subprocess.PIPE, timeout=30).decode().strip()

    def run_case(self, name, message, expected):
        self.git('checkout', '--detach', self.base)
        if message:
            self.git('commit', '--allow-empty', '-qm', message)
        candidate = self.git('rev-parse', 'HEAD')
        with patch('prepare.identity', return_value=self.last):
            value = prepare(self.repo, candidate, self.root / name, TASK)
        self.assertEqual(value['candidateSha'], candidate)
        self.assertEqual(value['lastRelease'], self.last)
        self.assertEqual(value['semanticReleaseVersion'], '4.1.0')
        self.assertGreater(len(value['semanticReleaseFiles']), 10)
        self.assertEqual(value['noRelease'], expected is None)
        if expected:
            self.assertEqual(value['version'], expected)
            self.assertIn(candidate, value['notes'])
            self.assertIn('UTC', value['notes'])
        self.assertEqual(json.loads((self.repo / 'box.json').read_text())['version'], '13.0.4')
        self.assertEqual(self.git('tag', '--list'), 'v13.0.4')
        self.assertEqual(self.git('status', '--porcelain'), '')

    def test_no_changes(self):
        self.run_case('no-changes', None, None)

    def test_patch(self):
        self.run_case('patch', 'fix(soak): correct output', '13.0.5')

    def test_feature(self):
        self.run_case('feature', 'feat(soak): add lookup', '13.1.0')

    def test_breaking(self):
        self.run_case('breaking', 'feat(soak): remove API\n\nDetails\n\nBREAKING CHANGE: removed', '14.0.0')

    def test_version_update_marker(self):
        self.run_case('skip', '__SEMANTIC RELEASE VERSION UPDATE__', None)

    def test_provider_changed_during_preparation(self):
        self.git('checkout', '--detach', self.base)
        with patch('prepare.identity', side_effect=[self.last, {**self.last, 'githubReleaseId': 2}]):
            with self.assertRaisesRegex(ValueError, 'Release state changed'):
                prepare(self.repo, self.base, self.root / 'changed', TASK)

    def test_local_tag_replaced(self):
        with patch('prepare.identity', return_value={**self.last, 'tagObjectSha': '0' * 40}):
            with self.assertRaisesRegex(ValueError, 'tag differs'):
                prepare(self.repo, self.base, self.root / 'mismatch', TASK)
        self.assertFalse((self.root / 'mismatch').exists())

    def test_abbreviated_candidate(self):
        with self.assertRaisesRegex(ValueError, 'full commit SHA'):
            prepare(self.repo, self.base[:7], self.root / 'short', TASK)


if __name__ == '__main__':
    unittest.main()
