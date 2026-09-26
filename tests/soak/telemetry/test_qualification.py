import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).parents[1]))
from identity import digest, profile_identity, require_match, sha_file
from qualification import baseline_paths, select_baseline, resolve_artifact_baseline, accepted_baseline, seal_qualification, verify_qualification, QUALIFICATION_EVIDENCE, seal_validation, validate_package_purpose
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

    def cohort(self, name, model, rate=6):
        data = copy.deepcopy(reviewed())
        host = {'docker': {'MemTotal': 16722006016, 'NCPU': 4},
                'cpu': {'Model name': model, 'L2 cache': 'fixed'},
                'runnerImage': 'ubuntu24', 'runnerImageVersion': '20260921.1'}
        proposal = data['proposal']
        proposal['profile']['workload']['rate'] = rate
        values = {'profile': profile_identity(proposal['profile']), 'host': host}
        proposal['measurementIdentity'] = {'values': values, 'sha256': digest(values)}
        data['proposalSha256'] = digest(proposal)
        path = self.directory / name
        path.write_text(json.dumps(data))
        return path, host

    def catalog(self, names):
        self.path.write_text(json.dumps({'schema': 1, 'status': 'accepted-catalog', 'baselines': names}))
        return self.path

    def test_selects_reviewed_hardware_and_only_its_calibrated_rate(self):
        provisional = copy.deepcopy(PROFILE)
        provisional['workload']['rate'] = 24
        first, host = self.cohort('n2.json', 'Neoverse-N2', 6)
        second, _ = self.cohort('v3.json', 'Neoverse-V3', 9)
        self.catalog([first.name, second.name])
        host['docker']['MemTotal'] += 4096
        selected, profile = select_baseline(self.path, host, provisional)
        self.assertEqual(selected, first.resolve())
        self.assertEqual(profile['workload']['rate'], 6)
        self.assertEqual(provisional['workload']['rate'], 24)
        self.assertEqual(resolve_artifact_baseline(self.path, sha_file(second)), second.resolve())
        changed = copy.deepcopy(provisional)
        changed['fixtures']['highFanoutComments'] = 180
        with self.assertRaisesRegex(ValueError, 'profile differs'):
            select_baseline(self.path, host, changed)
        host['cpu']['Model name'] = 'unknown'
        with self.assertRaisesRegex(ValueError, 'found 0'):
            select_baseline(self.path, host, provisional)
        host['cpu']['Model name'] = 'Neoverse-V3'
        selected, profile = select_baseline(self.path, host, provisional)
        self.assertEqual(selected, second.resolve())
        self.assertEqual(profile['workload']['rate'], 9)

    def test_catalog_rejects_ambiguity_unsafe_names_and_unaccepted_members(self):
        first, host = self.cohort('n2.json', 'Neoverse-N2')
        second, _ = self.cohort('duplicate.json', 'Neoverse-N2')
        self.catalog([first.name, second.name])
        with self.assertRaisesRegex(ValueError, 'found 2'):
            select_baseline(self.path, host, PROFILE)
        for names in ([], ['../escape.json'], ['/tmp/escape.json'], ['a/b.json'], [first.name, first.name], [self.path.name]):
            self.catalog(names)
            with self.assertRaises(ValueError):
                baseline_paths(self.path)
        self.catalog([first.name])
        with self.assertRaisesRegex(ValueError, 'absent from the catalog'):
            resolve_artifact_baseline(self.path, 'f' * 64)
        data = json.loads(first.read_text())
        data['status'] = 'proposed-for-review'
        first.write_text(json.dumps(data))
        with self.assertRaisesRegex(ValueError, 'explicitly accepted'):
            baseline_paths(self.path)

    def test_receipt_verification_recomputes_hardware_comparison_and_catalog_membership(self):
        leaf, _ = self.cohort('n2.json', 'Neoverse-N2')
        self.catalog([leaf.name])
        accepted = json.loads(leaf.read_text())
        expected = accepted['proposal']['measurementIdentity']
        actual = copy.deepcopy(expected)
        actual['values']['host']['docker']['MemTotal'] += 40960
        actual['sha256'] = digest(actual['values'])
        run = self.directory / 'run'
        for name in QUALIFICATION_EVIDENCE:
            path = run / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('{}')
        def write(name, value):
            (run / name).write_text(json.dumps(value))
        write('accepted-baseline.json', accepted)
        write('baseline-comparison.json', require_match(expected, actual))
        write('summary.json', {'status': 'passed', 'releaseQualified': True, 'reasons': [],
                              'assessments': {'traffic': 'passed', 'resources': 'passed', 'memory': 'passed'}})
        for name in ('traffic', 'delivery', 'resource', 'memory'):
            write(name + '-analysis.json', {'status': 'passed'})
        package = {'candidateSha': 'a' * 40, 'packageSha256': 'b' * 64, 'lastRelease': {}}
        write('package/package-manifest.json', package)
        write('package/prepared.json', {})
        seal_qualification(run)
        with patch('qualification.build_identity', return_value=actual), patch('qualification.verify', return_value=package):
            self.assertEqual(verify_qualification(run, 'a' * 40, self.path)['baselineSha256'], sha_file(leaf))
            for key, value in (('hostMemoryDifferenceBytes', 0), ('hostMemoryToleranceBytes', 65537)):
                comparison = require_match(expected, actual)
                comparison[key] = value
                write('baseline-comparison.json', comparison)
                seal_qualification(run)
                with self.assertRaisesRegex(ValueError, 'Recorded baseline comparison changed'):
                    verify_qualification(run, 'a' * 40, self.path)
            replacement, _ = self.cohort('v3.json', 'Neoverse-V3')
            self.catalog([replacement.name])
            with self.assertRaisesRegex(ValueError, 'absent from the catalog'):
                verify_qualification(run, 'a' * 40, self.path)

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

    def latency_noise_review(self):
        data = copy.deepcopy(reviewed())
        finding = 'run-to-run-p95-noise-exceeds-ten-percent:report_100'
        data['proposal']['status'] = 'needs-investigation'
        data['proposal']['investigations'] = [finding]
        data['proposalSha256'] = digest(data['proposal'])
        data['review']['investigationResolutions'] = {finding: {
            'disposition': 'retain-warning-with-unchanged-gates',
            'rationale': 'Independent healthy trials pass unchanged blocking bands; retain measured warnings.',
            'evidenceUrl': 'https://example.invalid/raw-noise-review',
            'evidenceSha256': 'c' * 64}}
        return data, finding

    def test_explicit_latency_review_preserves_warning_and_proposal(self):
        data, finding = self.latency_noise_review()
        result = self.load(data)
        self.assertEqual(result['proposal'], data['proposal'])
        self.assertEqual(result['proposal']['investigations'], [finding])
        self.assertEqual(result['proposal']['status'], 'needs-investigation')
        self.assertFalse(result['proposal']['releaseQualified'])

    def test_latency_review_rejects_missing_extra_or_unsupported_resolutions(self):
        for mutation in ('missing', 'extra', 'memory', 'unknown-operation', 'wrong-status'):
            with self.subTest(mutation=mutation):
                data, finding = self.latency_noise_review()
                resolutions = data['review']['investigationResolutions']
                if mutation == 'missing':
                    resolutions.clear()
                elif mutation == 'extra':
                    resolutions['unobserved'] = resolutions[finding]
                elif mutation in ('memory', 'unknown-operation'):
                    new = ('healthy-retained-growth-requires-investigation' if mutation == 'memory'
                           else 'run-to-run-p95-noise-exceeds-ten-percent:unobserved')
                    data['proposal']['investigations'] = [new]
                    resolutions[new] = resolutions.pop(finding)
                else:
                    data['proposal']['status'] = 'proposed-for-review'
                data['proposalSha256'] = digest(data['proposal'])
                with self.assertRaisesRegex(ValueError, 'investigations'):
                    self.load(data)

    def test_latency_review_requires_evidence_and_unchanged_gate_disposition(self):
        for field in ('disposition', 'rationale', 'evidenceUrl', 'evidenceSha256'):
            with self.subTest(field=field):
                data, finding = self.latency_noise_review()
                data['review']['investigationResolutions'][finding][field] = ''
                with self.assertRaisesRegex(ValueError, 'investigations'):
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
