import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import Mock, patch
import urllib.parse

from package import build, promote
from provider import FORGEBOX, GITHUB, Publisher
from promote_qualified import promote_qualified, release_context


class ProviderHTTP:
    def __init__(self, candidate):
        self.candidate = candidate
        self.calls, self.stored, self.published, self.release = [], None, False, False
        self.corrupt = False
        self.fail_publish = False
        self.metadata = None
        self.release_request = None
        self.before_request = lambda method, url: None

    def request(self, method, url, headers, body=None):
        self.before_request(method, url)
        self.calls.append((method, url, headers, body))
        def result(data, status=200): return status, json.dumps(data).encode()
        def forge(data): return result({'error': False, 'data': data})
        if url == 'https://storage.example.invalid/quick.zip?signed_secret=1':
            # API tokens must never be forwarded to signed storage URLs.
            assert 'Authorization' not in headers and 'X-Api-Token' not in headers
            if method == 'PUT':
                self.stored = body
                return 200, b''
            return 200, b'corrupt' if self.corrupt else self.stored
        if url.startswith(FORGEBOX):
            assert headers['X-Api-Token'] == 'FORGEBOX_SECRET'
            path = url[len(FORGEBOX):]
            if path == 'entry/quick':
                version = '1.0.1' if self.published else '1.0.0'
                return forge({'entryID': 'quick-entry', 'latestVersion': {'version': version, 'binaryHash': 'old-hash'},
                              'versions': [{'version': '1.0.0'}] + ([{'version': '1.0.1'}] if self.published else [])})
            if path == 'storage/quick/1.0.1':
                return forge('https://storage.example.invalid/quick.zip?signed_secret=1') if self.stored else (404, b'')
            if path == 'storage/storeURL/quick/1.0.1':
                return forge('https://storage.example.invalid/quick.zip?signed_secret=1')
            if path == 'publish' and method == 'POST':
                self.metadata = {key: values[0] for key, values in urllib.parse.parse_qs(body.decode(), keep_blank_values=True).items()}
                if self.fail_publish:
                    return 503, b''
                self.published = True
                return forge({'version': '1.0.1'})
        if url.startswith(GITHUB):
            assert headers['Authorization'] == 'Bearer GITHUB_SECRET'
            path = url[len(GITHUB):]
            if path == 'git/ref/heads/main': return result({'object': {'type': 'commit', 'sha': self.candidate}})
            if path == 'releases/latest': return result({'id': 123, 'tag_name': 'v1.0.0', 'draft': False, 'prerelease': False})
            if path == 'git/ref/tags/v1.0.0': return result({'object': {'type': 'tag', 'sha': 'b'*40}})
            if path == 'git/tags/' + 'b'*40: return result({'object': {'type': 'commit', 'sha': 'c'*40}})
            if path == 'git/ref/tags/v1.0.1':
                return result({'object': {'type': 'commit', 'sha': self.candidate}}) if self.release else (404, b'')
            if path == 'releases/tags/v1.0.1': return (404, b'')
            if path == 'releases' and method == 'POST':
                self.release_request = json.loads(body)
                self.release = True
                return result({'id': 456, 'tag_name': 'v1.0.1'}, 201)
        raise AssertionError('Unexpected fake-provider request: ' + method + ' ' + url)


class ProviderTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.repo = self.root / 'repo'
        self.repo.mkdir()
        self.git('init', '-q')
        self.git('config', 'user.name', 'Test')
        self.git('config', 'user.email', 'test@example.invalid')
        for name, value in {'box.json': json.dumps({'slug': 'quick', 'version': '1.0.0', 'location': 'forgeboxStorage'}),
                            'ModuleConfig.cfc': 'component {}', 'README.md': 'readme', 'LICENSE': 'license', 'CHANGELOG.md': 'history'}.items():
            (self.repo / name).write_text(value)
        self.git('add', '.')
        self.git('commit', '-qm', 'fixture')
        self.sha = self.git('rev-parse', 'HEAD')
        self.http = ProviderHTTP(self.sha)
        self.publisher = self.new_publisher('journal')
        self.last = self.publisher.last_release()
        self.artifact = self.root / 'artifact'
        self.manifest = build(self.repo, {'candidateSha': self.sha, 'version': '1.0.1', 'lastRelease': self.last,
                              'notes': '## 1.0.1\nTested fix.'}, self.artifact)
        self.http.calls.clear()

    def git(self, *args):
        return subprocess.check_output(['git', '-C', str(self.repo), *args], stderr=subprocess.STDOUT, text=True).strip()

    def new_publisher(self, journal):
        return Publisher(forgebox_token='FORGEBOX_SECRET', github_token='GITHUB_SECRET', branch='main',
                         journal=self.root / journal, transport=self.http)

    def writes(self):
        return [call for call in self.http.calls if call[0] in ('PUT', 'POST')]

    def test_missing_qualification_never_instantiates_or_contacts_provider(self):
        factory = Mock(return_value=self.publisher)
        with self.assertRaises(FileNotFoundError):
            promote_qualified(self.root / 'missing-run', self.sha, self.root / 'baseline.json', factory)
        factory.assert_not_called()
        self.assertEqual(self.http.calls, [])

    def test_rejected_qualification_never_reaches_provider(self):
        for reason in ('Qualification assessments did not all pass', 'Accepted baseline changed after validation',
                       'Qualified evidence changed: k6.ndjson', 'Qualification candidate mismatch'):
            with self.subTest(reason=reason), patch('promote_qualified.verify_qualification', side_effect=ValueError(reason)):
                factory = Mock(return_value=self.publisher)
                with self.assertRaisesRegex(ValueError, reason):
                    promote_qualified(self.root, self.sha, self.root / 'baseline.json', factory)
                factory.assert_not_called()
        self.assertEqual(self.http.calls, [])

    def test_verified_evidence_is_bound_to_actual_adapter_publication_receipt(self):
        # The qualification verifier is independently exercised on raw evidence;
        # this test covers orchestration and the real adapter with fake HTTP.
        run = self.root / 'run'
        run.mkdir()
        self.artifact.rename(run / 'package')
        qualification = dict(packageSha256=self.manifest['packageSha256'], baselineSha256='a'*64, evidenceSha256='b'*64,
                             files={'package/package-manifest.json': hashlib.sha256((run / 'package/package-manifest.json').read_bytes()).hexdigest()})
        with patch('promote_qualified.verify_qualification', return_value=qualification) as verify:
            result = promote_qualified(run, self.sha, self.root / 'baseline.json', lambda: self.publisher)
        verify.assert_called_once_with(run, self.sha, self.root / 'baseline.json')
        self.assertEqual(result['packageSha256'], qualification['packageSha256'])
        self.assertEqual(result['downloadSha256'], qualification['packageSha256'])
        self.assertEqual(result['evidenceSha256'], qualification['evidenceSha256'])
        self.assertEqual(json.loads((self.publisher.journal / 'publication-receipt.json').read_text()), result)
        self.assertEqual(json.loads((self.publisher.journal / '01-qualification-verified.json').read_text())['baselineSha256'], 'a'*64)
        self.assertEqual(self.http.stored, (run / 'package/quick.zip').read_bytes())

    def test_consistently_rebuilt_artifact_after_qualification_cannot_be_promoted(self):
        run = self.root / 'run'
        run.mkdir()
        self.artifact.rename(run / 'package')
        qualification = dict(packageSha256=self.manifest['packageSha256'], baselineSha256='a'*64, evidenceSha256='b'*64,
                             files={'package/package-manifest.json': hashlib.sha256((run / 'package/package-manifest.json').read_bytes()).hexdigest()})
        def changed_before_promotion():
            (run / 'package').rename(run / 'original')
            build(self.repo, {'candidateSha': self.sha, 'version': '1.0.1', 'lastRelease': self.last,
                             'notes': 'Different notes and ZIP'}, run / 'package')
            return self.publisher
        with patch('promote_qualified.verify_qualification', return_value=qualification):
            with self.assertRaisesRegex(ValueError, 'differs from qualification'):
                promote_qualified(run, self.sha, self.root / 'baseline.json', changed_before_promotion)
        self.assertEqual(self.http.calls, [])

    def test_release_context_rejects_local_pr_tag_and_other_candidate(self):
        env = dict(GITHUB_ACTIONS='true', GITHUB_REPOSITORY='coldbox-modules/quick', GITHUB_EVENT_NAME='push',
                   GITHUB_REF='refs/heads/main', GITHUB_SHA=self.sha)
        self.assertEqual(release_context(env, self.sha), 'main')
        for field, value in (('GITHUB_ACTIONS', 'false'), ('GITHUB_REPOSITORY', 'fork/quick'),
                             ('GITHUB_EVENT_NAME', 'pull_request'), ('GITHUB_REF', 'refs/tags/v1.0.1'),
                             ('GITHUB_SHA', 'a'*40)):
            with self.subTest(field=field), self.assertRaisesRegex(ValueError, 'matching Quick release-branch'):
                release_context({**env, field: value}, self.sha)

    def test_actual_adapter_promotes_exact_zip_without_directory_rebuild(self):
        receipt = promote(self.artifact, self.sha, self.publisher)
        data = (self.artifact / 'quick.zip').read_bytes()
        self.assertEqual(self.http.stored, data)
        self.assertEqual(receipt['downloadSha256'], self.manifest['packageSha256'])
        self.assertEqual(self.http.metadata['binaryHash'], hashlib.md5(data).hexdigest())
        self.assertEqual(self.http.metadata['forceUpload'], 'false')
        self.assertEqual(json.loads(self.http.metadata['boxJSON'])['version'], '1.0.1')
        self.assertEqual(self.http.release_request['target_commitish'], self.sha)
        self.assertFalse(self.http.release_request['generate_release_notes'])
        self.assertEqual(len(self.writes()), 3)
        stages = [json.loads(path.read_text())['stage'] for path in sorted((self.root / 'journal').glob('*.json'))]
        self.assertEqual(stages, ['before-storage-upload', 'storage-uploaded', 'before-forgebox-publish', 'forgebox-published',
                                 'download-verified', 'before-github-release', 'complete'])

    def test_notes_are_snapshotted_before_any_provider_request(self):
        notes = json.loads((self.artifact / 'prepared.json').read_text())['notes']
        def mutate_metadata(method, url):
            if method == 'PUT':
                prepared = json.loads((self.artifact / 'prepared.json').read_text())
                prepared['notes'] = 'Unverified replacement'
                (self.artifact / 'prepared.json').write_text(json.dumps(prepared))
        self.http.before_request = mutate_metadata
        promote(self.artifact, self.sha, self.publisher)
        self.assertEqual(self.http.release_request['body'], notes)

    def test_corrupt_download_prevents_github_publication(self):
        self.http.corrupt = True
        with self.assertRaisesRegex(ValueError, 'download differs'):
            promote(self.artifact, self.sha, self.publisher)
        self.assertFalse(self.http.release)
        self.assertEqual(len(self.writes()), 2)

    def test_uncertain_publish_is_not_retried_or_overwritten(self):
        self.http.fail_publish = True
        with self.assertRaisesRegex(RuntimeError, 'HTTP 503'):
            promote(self.artifact, self.sha, self.publisher)
        self.assertEqual(len(self.writes()), 2)
        with self.assertRaises(FileExistsError):
            self.new_publisher('journal')
        self.http.fail_publish = False
        with self.assertRaisesRegex(ValueError, 'already exists'):
            promote(self.artifact, self.sha, self.new_publisher('new-journal'))
        self.assertEqual(len(self.writes()), 2)
        self.assertFalse(self.http.release)

    def test_new_candidate_stops_before_any_provider_write(self):
        self.http.candidate = 'd'*40
        with self.assertRaisesRegex(ValueError, 'superseded'):
            promote(self.artifact, self.sha, self.publisher)
        self.assertEqual(self.writes(), [])

    def test_api_tokens_and_signed_urls_are_not_retained_in_journal(self):
        promote(self.artifact, self.sha, self.publisher)
        contents = ''.join(path.read_text() for path in (self.root / 'journal').glob('*'))
        for secret in ('GITHUB_SECRET', 'FORGEBOX_SECRET', 'signed_secret'):
            self.assertNotIn(secret, contents)

    def test_publicizing_without_exact_download_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'download must be verified'):
            self.publisher.publicize(self.manifest, 'notes')
        self.assertEqual(self.writes(), [])

    def test_provider_divergence_stops_before_write(self):
        self.http.published = True
        with self.assertRaisesRegex(ValueError, 'identities disagree'):
            promote(self.artifact, self.sha, self.publisher)
        self.assertEqual(self.writes(), [])

    def test_checkpoint_is_durable_before_each_write(self):
        observed = []
        def check(method, url):
            if method in ('PUT', 'POST'):
                paths = sorted((self.root / 'journal').glob('*.json'))
                observed.append(json.loads(paths[-1].read_text())['stage'])
        self.http.before_request = check
        promote(self.artifact, self.sha, self.publisher)
        self.assertEqual(observed, ['before-storage-upload', 'before-forgebox-publish', 'before-github-release'])

    def test_candidate_is_rechecked_at_upload_boundary(self):
        count = 0
        def change(method, url):
            nonlocal count
            if url.endswith('git/ref/heads/main'):
                count += 1
                if count == 2:
                    self.http.candidate = 'd'*40
        self.http.before_request = change
        with self.assertRaisesRegex(ValueError, 'changed before upload'):
            promote(self.artifact, self.sha, self.publisher)
        self.assertEqual(self.writes(), [])


if __name__ == '__main__':
    unittest.main()
