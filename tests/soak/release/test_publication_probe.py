import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from publication_probe import serialization


class NativeSerializationTests(unittest.TestCase):
    def evidence(self, second_start='2026-09-25T00:13:10Z', second_id=2, corrupt=False):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        paths = []
        stub = {'packageCandidateSha': 'b' * 40, 'packageSha256': 'c' * 64,
                'downloadSha256': 'c' * 64, 'holdSeconds': 180,
                'published': False, 'releaseQualified': False}
        for index, start, end, run_id in ((1, '2026-09-25T00:10:00Z', '2026-09-25T00:13:00Z', 1),
                                         (2, second_start, '2026-09-25T00:17:00Z', second_id)):
            directory = root / str(index)
            (directory / 'artifacts').mkdir(parents=True)
            paths.append(directory)
            current = copy.deepcopy(stub)
            current.update(guardStartedAt=index * 200, guardFinishedAt=index * 200 + 180)
            if corrupt and index == 2:
                current['downloadSha256'] = 'd' * 64
            values = {'verification.json': {'passed': True, 'mode': 'all-pass'},
                'workflow.json': {'id': run_id, 'head_sha': 'a' * 40,
                                  'run_started_at': '2026-09-25T00:00:00Z', 'updated_at': end},
                'jobs.json': {'jobs': [{'name': 'Publication stub (no provider calls)',
                                       'started_at': start, 'completed_at': end}]},
                'artifacts/publication-stub.json': current}
            for name, value in values.items():
                (directory / name).write_text(json.dumps(value))
        return paths

    def test_two_overlapping_runs_with_serialized_guards_and_exact_bytes_pass(self):
        self.assertTrue(serialization(self.evidence())['passed'])

    def test_overlapping_guard_jobs_fail_even_if_script_timestamps_do_not_overlap(self):
        result = serialization(self.evidence(second_start='2026-09-25T00:12:00Z'))
        self.assertFalse(result['passed'])
        self.assertFalse(result['checks']['providerGuardJobsDidNotOverlap'])

    def test_reusing_one_run_or_changing_readback_cannot_prove_serialization(self):
        self.assertFalse(serialization(self.evidence(second_id=1))['passed'])
        self.assertFalse(serialization(self.evidence(corrupt=True))['passed'])
