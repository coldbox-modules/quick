"""Test matrix evidence decisions; full receipt validity has separate raw checks."""
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from package import digest
from verify_full_probe import verify, verify_failure


class FullMatrixEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.sha = 'a' * 40
        self.data = b'exact tested zip fixture'
        self.package_hash = digest(self.data)
        self.eligibility = dict(publicationRequired=True, candidateSha=self.sha, packageSha256=self.package_hash)
        self.inspection = patch('verify_full_probe.inspect_artifact', return_value=self.eligibility)
        self.inspection.start()
        self.addCleanup(self.inspection.stop)
        self.write('workflow.json', dict(path='.github/workflows/soak-release-proof.yml',
            status='completed', conclusion='success', head_sha=self.sha, id=123))
        (self.root / 'release.yml.pending').write_text(Path(__file__).with_name('release.yml.pending').read_text())
        self.jobs = []
        for engine in ('lucee@5', 'lucee@6', 'adobe@2021', 'adobe@2023', 'adobe@2025', 'boxlang@1', 'boxlang-cfml@1'):
            for coldbox in ('coldbox@^7', 'coldbox@^8'):
                for null in ('true', 'false'):
                    if engine == 'boxlang@1' and coldbox == 'coldbox@^7':
                        continue
                    if engine.startswith('adobe@') and coldbox == 'coldbox@^8' and null == 'true':
                        continue
                    self.jobs.append(self.job(f'Validation / functional / {engine} / {coldbox} / null={null}',
                        'Run TestBox Tests', '2026-01-01T00:03:00Z', '2026-01-01T00:15:00Z'))
        self.jobs.append(self.job('Validation / soak /  /  / null=', 'Observe the complete required soak',
            '2026-01-01T00:05:00Z', '2026-01-01T01:05:00Z'))
        self.jobs.append(self.job('Full receipt publication stub (no provider calls)', 'Local publication probe',
            '2026-01-01T01:06:00Z', '2026-01-01T01:07:00Z'))
        for index, job in enumerate(self.jobs):
            job['id'] = index + 1000
        self.write('jobs.json', {'jobs': self.jobs})
        for index, job in enumerate(self.jobs[:-2]):
            self.write(f'artifacts/full-functional-{index}-123/row.json', {'name': job['name'], 'workflowRunId': '123'})
            self.write(f'artifacts/full-functional-{index}-123/testbox.json', {'totalPass': 10, 'totalFail': 0, 'totalError': 0})
        receipt = dict(candidateSha=self.sha, packageSha256=self.package_hash, baselineSha256='b'*64, evidenceSha256='c'*64)
        self.write('artifacts/release-soak-123-1/supervision/run/qualification.json', receipt)
        self.stub = 'artifacts/full-publication-proof-123/qualified-publication-stub.json'
        self.write(self.stub, {**self.eligibility, 'fullReceiptVerified': True, 'workflowRunId': '123',
            'published': False, 'providerWrites': 0, 'stubPublished': True,
            'promotionReceipt': {**receipt, 'downloadSha256': self.package_hash}})
        upload = self.root / 'artifacts/full-publication-proof-123/local-publisher/upload.zip'
        upload.parent.mkdir()
        upload.write_bytes(self.data)

    def write(self, name, value):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(value))

    def job(self, name, step, start, end):
        return dict(name=name, conclusion='success', started_at=start, completed_at=end,
                    steps=[dict(name=step, conclusion='success', started_at=start, completed_at=end)])

    def test_all_rows_real_step_overlap_order_and_package_bytes_are_required(self):
        self.assertTrue(verify(self.root)['passed'])
        self.jobs.pop(0)
        self.write('jobs.json', {'jobs': self.jobs})
        result = verify(self.root)
        self.assertFalse(result['passed'])
        self.assertFalse(result['checks']['exactFunctionalMatrix'])

    def test_early_publisher_cannot_pass_even_with_green_jobs(self):
        self.jobs[-1]['started_at'] = '2026-01-01T01:04:00Z'
        self.write('jobs.json', {'jobs': self.jobs})
        self.assertFalse(verify(self.root)['checks']['publisherWaitedForEntireMatrix'])

    def test_setup_overlap_does_not_substitute_for_actual_test_execution(self):
        for job in self.jobs[:-2]:
            job['steps'][0]['completed_at'] = '2026-01-01T00:04:00Z'
        self.write('jobs.json', {'jobs': self.jobs})
        self.assertFalse(verify(self.root)['checks']['actualTestBoxOverlappedFullSoak'])

    def test_stub_checksum_claim_cannot_substitute_for_actual_uploaded_bytes(self):
        (self.root / 'artifacts/full-publication-proof-123/local-publisher/upload.zip').write_bytes(b'changed')
        self.assertFalse(verify(self.root)['checks']['exactUploadedBytes'])

    def test_invalid_raw_receipt_is_never_accepted_from_stub_status(self):
        with patch('verify_full_probe.inspect_artifact', side_effect=ValueError('Changed raw evidence')):
            with self.assertRaisesRegex(ValueError, 'Changed raw evidence'):
                verify(self.root)

    def test_green_job_does_not_hide_a_failed_testbox_report(self):
        self.write('artifacts/full-functional-0-123/testbox.json', {'totalPass': 9, 'totalFail': 1, 'totalError': 0})
        self.assertFalse(verify(self.root)['checks']['everyActualTestBoxReportPassed'])

    def test_functional_failure_requires_the_real_expected_assertion_and_cleanup(self):
        from verify_full_probe import epoch
        run = 'artifacts/release-soak-123-1/supervision/run'
        (self.root / run / 'qualification.json').unlink()
        (self.root / self.stub).unlink()
        self.write('workflow.json', dict(path='.github/workflows/soak-release-proof.yml',
            status='completed', conclusion='failure', head_sha=self.sha, id=123))
        failing = self.jobs[6]
        failing['conclusion'] = failing['steps'][0]['conclusion'] = 'failure'
        self.jobs[-2]['conclusion'] = 'cancelled'
        self.jobs[-1]['conclusion'] = 'skipped'
        self.write('jobs.json', {'jobs': self.jobs})
        self.write(run + '/summary.json', {'status': 'inconclusive', 'state': 'canceled', 'releaseQualified': False})
        self.write('artifacts/release-soak-123-1/supervision/cleanup-verification.json', {'passed': True, 'checks': {
            key: True for key in ('containersRemoved', 'volumesRemoved', 'networksRemoved', 'anonymousDatabaseVolumeRemoved')}})
        self.write('artifacts/release-soak-123-1/supervision/live.json', {'live': True, 'time': epoch('2026-01-01T00:05:00Z')})
        for name in ('k6.ndjson', 'jvm/jvm.ndjson', 'jvm/recording-final.jfr'):
            path = self.root / run / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(b'partial evidence fixture')
        directory = 'artifacts/full-functional-6-123/'
        self.write(directory + 'functional-injection.json', {'soakJobId': self.jobs[-2]['id'], 'time': epoch('2026-01-01T00:06:00Z')})
        report = {'totalFail': 1, 'totalError': 0, 'bundleStats': [{'suiteStats': [{'specStats': [{
            'name': 'fails deliberately after the sibling soak has real HTTP and JVM evidence',
            'status': 'Failed', 'failMessage': 'Intentional full-matrix functional failure'}]}]}]}
        self.write(directory + 'testbox.json', report)
        self.assertTrue(verify_failure(self.root, 'functional-failure')['passed'])
        report['bundleStats'][0]['suiteStats'][0]['specStats'][0]['failMessage'] = 'Unrelated exception'
        self.write(directory + 'testbox.json', report)
        self.assertFalse(verify_failure(self.root, 'functional-failure')['checks']['actualAssertionFailed'])


if __name__ == '__main__':
    unittest.main()
