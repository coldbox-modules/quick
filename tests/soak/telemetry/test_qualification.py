import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).parents[1]))
from identity import digest, profile_identity
from qualification import accepted_baseline, seal_qualification, verify_qualification, QUALIFICATION_EVIDENCE, seal_validation, validate_package_purpose
from traffic import CASES, operation_names

PROFILE = json.loads((Path(__file__).parents[1] / 'profiles/lucee6-serial.json').read_text())


def reviewed():
    values = {'profile': profile_identity(PROFILE)}
    operations = [*operation_names(PROFILE['workload']), *('failure:' + case for case in (*CASES, 'post_delete'))]
    proposal = {'status': 'proposed-for-review', 'investigations': [], 'accepted': False, 'releaseQualified': False,
        'trials': [{'runId': str(i), 'bootId': str(i), 'jvmStart': i, 'githubRunId': '123', 'evidenceSha256': 'a'*64} for i in range(3)],
        'measurementIdentity': {'values': values, 'sha256': digest(values)}, 'profile': PROFILE,
        'latency': {key: {'p95Ms': 100, 'maxObservedWindowP95Ms': 110} for key in operations},
        'memory': {'noiseBytes': 100000, 'baselineBytes': 100000000}}
    return {'schema': 1, 'status': 'accepted', 'proposal': proposal, 'proposalSha256': digest(proposal),
        'review': {'reviewer': 'Test reviewer', 'reviewedAt': '2020-01-01T00:00:00Z',
                   'url': 'https://example.invalid/review', 'evidenceArchive': 'https://example.invalid/evidence'},
        'latencyBudgetsMs': {key: 200 for key in operations},
        'detectors': {key: {'url': 'https://example.invalid/detector', 'evidenceSha256': 'b'*64}
                      for key in ('retained-growth', 'wrong-contract', 'held-connection', 'latency', 'late-latency', 'saturation')}}


class QualificationTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.directory = Path(self.tmp.name)
        self.path = self.directory / 'baseline.json'

    def load(self, data):
        self.path.write_text(json.dumps(data))
        return accepted_baseline(self.path)

    def test_reviewed_complete_manifest_loads_without_accepting_any_candidate(self):
        result = self.load(reviewed())
        self.assertEqual(result['status'], 'accepted')
        self.assertFalse((self.directory / 'qualification.json').exists())

    def test_proposal_is_not_acceptance(self):
        data = reviewed()
        data['status'] = 'proposed-for-review'
        with self.assertRaisesRegex(ValueError, 'explicitly accepted'):
            self.load(data)

    def test_changed_proposal_does_not_keep_previous_review(self):
        data = reviewed()
        data['proposal']['memory']['noiseBytes'] *= 2
        with self.assertRaisesRegex(ValueError, 'proposal changed'):
            self.load(data)

    def test_unresolved_noise_cannot_be_accepted_by_status_alone(self):
        data = reviewed()
        data['proposal']['investigations'] = ['run-to-run-noise']
        data['proposalSha256'] = digest(data['proposal'])
        with self.assertRaisesRegex(ValueError, 'investigations'):
            self.load(data)

    def test_missing_review_or_durable_evidence_blocks(self):
        for field in ('reviewer', 'url', 'evidenceArchive'):
            data = reviewed()
            data['review'][field] = ''
            with self.assertRaisesRegex(ValueError, 'references'):
                self.load(data)

    def test_missing_absolute_budget_and_missing_detector_block(self):
        data = reviewed()
        del data['latencyBudgetsMs']['report_100']
        with self.assertRaisesRegex(ValueError, 'Every operation'):
            self.load(data)
        for detector in reviewed()['detectors']:
            with self.subTest(detector=detector):
                data = reviewed()
                del data['detectors'][detector]
                with self.assertRaisesRegex(ValueError, 'detector evidence'):
                    self.load(data)

    def test_unbounded_latency_and_development_profiles_block(self):
        for value in (float('nan'), float('inf'), -1, 10001):
            data = reviewed()
            data['latencyBudgetsMs']['graph'] = value
            with self.assertRaisesRegex(ValueError, 'latency budget'):
                self.load(data)
        data = copy.deepcopy(reviewed())
        data['proposal']['profile']['workload']['plateauSeconds'] = 180
        identity = data['proposal']['measurementIdentity']
        identity['sha256'] = digest(identity['values'])
        data['proposalSha256'] = digest(data['proposal'])
        with self.assertRaisesRegex(ValueError, '60-minute'):
            self.load(data)

    def test_development_or_inconclusive_status_cannot_seal_a_receipt(self):
        for status in ('development-passed', 'calibration-passed', 'inconclusive', 'failed'):
            (self.directory / 'summary.json').write_text(json.dumps({'status': status, 'releaseQualified': False, 'reasons': []}))
            with self.assertRaisesRegex(ValueError, 'complete qualified'):
                seal_qualification(self.directory)
        self.assertFalse((self.directory / 'qualification.json').exists())

    def test_validation_package_and_publication_mode_cannot_be_interchanged(self):
        validate_package_purpose({'validationOnly': True}, {'noRelease': True}, True)
        validate_package_purpose({}, {}, False)
        for package, prepared, validation in (({'validationOnly': True}, {'noRelease': True}, False),
                                              ({}, {'noRelease': True}, False), ({}, {}, True),
                                              ({'validationOnly': True}, {}, True)):
            with self.subTest(package=package, validation=validation), self.assertRaises(ValueError):
                validate_package_purpose(package, prepared, validation)

    def test_no_release_validation_receipt_cannot_be_renamed_for_publication(self):
        for name in QUALIFICATION_EVIDENCE:
            path = self.directory / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('{}')
        (self.directory / 'summary.json').write_text(json.dumps({'status': 'validation-passed', 'releaseQualified': False, 'reasons': []}))
        (self.directory / 'package/package-manifest.json').write_text(json.dumps({'candidateSha': 'a'*40, 'packageSha256': 'b'*64, 'validationOnly': True}))
        receipt = seal_validation(self.directory)
        self.assertEqual(receipt['purpose'], 'validation-only')
        self.assertFalse((self.directory / 'qualification.json').exists())
        with self.assertRaisesRegex(ValueError, 'complete qualified'):
            seal_qualification(self.directory)
        (self.directory / 'validation.json').rename(self.directory / 'qualification.json')
        with self.assertRaisesRegex(ValueError, 'purpose mismatch'):
            verify_qualification(self.directory, 'a'*40, self.path)

    def test_receipt_binds_candidate_package_and_raw_evidence(self):
        for name in QUALIFICATION_EVIDENCE:
            path = self.directory / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('{}')
        (self.directory / 'summary.json').write_text(json.dumps({'status': 'passed', 'releaseQualified': True, 'reasons': []}))
        (self.directory / 'package/package-manifest.json').write_text(json.dumps({'candidateSha': 'a'*40, 'packageSha256': 'b'*64}))
        receipt = seal_qualification(self.directory)
        self.assertEqual(receipt['candidateSha'], 'a'*40)
        self.assertEqual(receipt['packageSha256'], 'b'*64)
        with self.assertRaisesRegex(ValueError, 'candidate mismatch'):
            verify_qualification(self.directory, 'c'*40, self.path)
        (self.directory / 'k6.ndjson').write_text('changed')
        with self.assertRaisesRegex(ValueError, 'Qualified evidence changed: k6.ndjson'):
            verify_qualification(self.directory, 'a'*40, self.path)


if __name__ == '__main__':
    unittest.main()
