import collections
from pathlib import Path
import re
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).parents[1]))
from fixtures.generate import fixture_settings, generate


class FixtureTests(unittest.TestCase):
    def test_reduced_fanout_preserves_domain_and_matches_actual_sql(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            manifest = generate(root / 'reduced', 60)
            repeated = generate(root / 'repeated', 60)
            self.assertEqual(manifest, repeated)
            sql = (root / 'reduced/seed.sql').read_text()
            comments = re.findall(r"\((\d+),(\d+),'comment-\d+',(\d+),'(Post|User)'\)", sql)
            self.assertEqual(len(comments), 50000)
            self.assertEqual(len({row[0] for row in comments}), 50000)
            kinds = collections.Counter(row[3] for row in comments)
            self.assertEqual(kinds, {'Post': 45000, 'User': 5000})
            counts = collections.Counter(row[2] for row in comments if row[3] == 'Post')
            self.assertEqual(counts['1'], 60)
            self.assertEqual(max(counts.values()), 60)
            self.assertEqual(counts['10000'], 0)
            self.assertEqual(manifest['postCommentCounts'], {str(i): counts[str(i)] for i in range(1, 10001)})
            self.assertEqual(manifest['counts'], {'teams': 20, 'users': 1000, 'posts': 10000,
                'comments': 50000, 'tags': 100, 'post_tags': 17144})
            original = generate(root / 'original')
            self.assertEqual(original['postCommentCounts']['1'], 180)
            self.assertEqual(original['sqlSha256'], 'ee3a967a37010314c26ea97d477c6d9a9e58d9babaf829d54b33518e03404c35')
            for key in ('counts', 'postTags', 'reportChecksums', 'emptyUserIds', 'scratchIdStart', 'missingIdStart'):
                self.assertEqual(manifest[key], original[key])
            self.assertNotEqual(manifest['sqlSha256'], original['sqlSha256'])

    def test_unsupported_fixture_controls_fail_before_writing(self):
        self.assertEqual(fixture_settings({}), {'highFanoutComments': 180})
        for value in ({}, None, {'highFanoutComments': True}, {'highFanoutComments': 60.0},
                      {'highFanoutComments': 1}, {'highFanoutComments': 60, 'ignored': 1}):
            with self.subTest(value=value), self.assertRaises(ValueError):
                fixture_settings({'fixtures': value})
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / 'invalid'
            with self.assertRaises(ValueError):
                generate(output, 1)
            self.assertFalse(output.exists())


if __name__ == '__main__':
    unittest.main()
