import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).parents[1]))
from baseline import EVIDENCE, propose, seal_trial, trial
from identity import digest


def trials():
    result = []
    for i in range(3):
        values = {'runtime': 'same'}
        result.append({'runId': str(i), 'bootId': 'boot-' + str(i), 'jvmStart': i + 1, 'githubRunId': '123',
            'identity': {'values': values, 'sha256': digest(values)}, 'package': {'candidateSha': 'same'},
            'capacityEvidenceSha256': 'capacity', 'evidenceSha256': 'raw-' + str(i),
            'profile': {'resources': {'application': {'heapMiB': 1024}}},
            'traffic': {'latency': {'browse': {'earlyP95Ms': 100, 'p95Ms': [100]*8}}},
            'memory': {'earlyMedianBytes': 100000000, 'growthBytes': 0,
                       'windows': [{'medianBytes': 100000000}]*8, 'warnings': []},
            'resources': {'recovery': {'threads': {'earlyMedian': 40, 'idleMedian': 40}}}})
    return result


class BaselineTests(unittest.TestCase):
    def test_three_matching_trials_only_propose_never_accept(self):
        proposal = propose(trials())
        self.assertEqual(proposal['status'], 'proposed-for-review')
        self.assertFalse(proposal['accepted'])
        self.assertFalse(proposal['releaseQualified'])
        self.assertEqual(proposal['latency']['browse']['proposedAbsoluteP95Ms'], 150)
        self.assertEqual(len(proposal['trials']), 3)
        self.assertTrue(proposal['reviewRequired'])

    def test_reusing_one_healthy_trial_is_not_three_trials(self):
        with self.assertRaisesRegex(ValueError, 'distinct'):
            propose([trials()[0]]*3)
        with self.assertRaisesRegex(ValueError, 'exactly three'):
            propose(trials()[:2])

    def test_environment_or_package_drift_rejects_proposal(self):
        data = trials()
        data[1]['package']['candidateSha'] = 'different'
        with self.assertRaisesRegex(ValueError, 'same healthy package'):
            propose(data)
        data = trials()
        data[1]['identity']['values']['runtime'] = 'different'
        data[1]['identity']['sha256'] = digest(data[1]['identity']['values'])
        with self.assertRaisesRegex(ValueError, 'recalibration required'):
            propose(data)

    def test_run_to_run_noise_requires_investigation_not_wider_silent_bands(self):
        data = trials()
        data[2]['traffic']['latency']['browse']['earlyP95Ms'] = 115
        proposal = propose(data)
        self.assertEqual(proposal['status'], 'needs-investigation')
        self.assertIn('run-to-run-p95-noise-exceeds-ten-percent:browse', proposal['investigations'])
        self.assertFalse(proposal['accepted'])

    def test_repeatable_retained_growth_cannot_be_absorbed_into_noise(self):
        data = trials()
        data[0]['memory']['warnings'] = ['persistent-positive-retained-trend']
        self.assertIn('healthy-retained-growth-requires-investigation', propose(data)['investigations'])
        data = trials()
        data[0]['memory']['windows'][0] = {'medianBytes': 200000000}
        self.assertIn('healthy-memory-noise-exceeds-provisional-blocking-band', propose(data)['investigations'])

    def test_missing_late_window_cannot_be_ignored(self):
        data = trials()
        data[2]['traffic']['latency']['browse']['p95Ms'].pop()
        with self.assertRaisesRegex(ValueError, 'Missing full trial'):
            propose(data)

    def test_mutated_raw_evidence_is_rejected_before_proposal(self):
        with tempfile.TemporaryDirectory() as tmp:
            run = Path(tmp)
            for name in EVIDENCE:
                path = run / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text('{}')
            (run / 'summary.json').write_text(json.dumps({'status': 'calibration-passed'}))
            seal_trial(run)
            (run / 'k6.ndjson').write_text('changed raw observations')
            with self.assertRaisesRegex(ValueError, 'Trial evidence changed: k6.ndjson'):
                trial(run)


if __name__ == '__main__':
    unittest.main()
