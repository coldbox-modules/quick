import datetime
import unittest
from traffic import CASES, JOURNEYS, operation_names, report_sizes, evaluate

START = 1790371200000
WORKLOAD = dict(plateauSeconds=2400, windowSeconds=300, rate=24,
                minimumFailuresPerCase=100, minimumLatencySamples=200, requestTimeoutSeconds=10)


def point(metric, value, at, **tags):
    return {'type': 'Point', 'metric': metric, 'data': {'value': value,
        'time': datetime.datetime.fromtimestamp(at / 1000, datetime.timezone.utc).isoformat(),
        'tags': {'scenario': 'plateau', **tags}}}


def healthy(latencies=None, workload=WORKLOAD):
    for i in range(8):
        at = START + i * 300000 + 1000
        for j, journey in enumerate(JOURNEYS):
            count = 650 if j < 10 else 700
            yield point('journey_started', count, at, journey=journey, phaseStart=str(START))
            yield point('journey_completed', count, at, journey=journey)
        for case in CASES:
            for metric in ('expected_failure_attempted', 'expected_failure_verified', 'followup_succeeded'):
                yield point(metric, 288, at, case=case)
        for bucket in ('browse_25', 'browse_100', *(f'report_{size}' for size in report_sizes(workload)), *(f'variant_{n}' for n in range(32))):
            yield point('bucket_completed', 5, at, bucket=bucket)
        for operation in (*operation_names(workload), *('failure:' + case for case in (*CASES, 'post_delete'))):
            for n in range(200):
                metric = 'expected_failure_latency' if operation.startswith('failure:') else 'successful_latency'
                tags = {'case': operation.split(':')[1]} if metric == 'expected_failure_latency' else {'operation': operation}
                value = (latencies or [100] * 8)[i] if operation == 'browse' else 100
                yield point(metric, value, at + n, **tags)


class TrafficTests(unittest.TestCase):
    def test_selected_report_sizes_each_require_their_own_latency_samples(self):
        workload = {**WORKLOAD, 'reportSizes': [25, 100, 250]}
        result = evaluate(healthy(workload=workload), workload)
        self.assertEqual(result['status'], 'passed')
        self.assertEqual(result['latency']['report_250']['counts'], [200] * 8)
        self.assertNotIn('report_1000', result['latency'])
        missing = (row for row in healthy(workload=workload)
                   if row['data']['tags'].get('operation') != 'report_250')
        self.assertIn('insufficient-latency-samples:report_250', evaluate(missing, workload)['invalid'])

    def test_report_sizes_are_bounded_unique_and_keep_historical_defaults(self):
        self.assertEqual(report_sizes({}), [100, 500, 1000])
        for sizes in ([25, 100, 100], [250, 100, 25], [25, 100, 2000], [25, 100], [True, 100, 250]):
            with self.subTest(sizes=sizes), self.assertRaises(ValueError):
                report_sizes({'reportSizes': sizes})

    def test_healthy_matched_load(self):
        result = evaluate(healthy(), WORKLOAD)
        self.assertEqual(result['status'], 'passed', result)
        self.assertEqual(result['startedJourneys'], 57600)
        self.assertEqual(result['latency']['browse']['p95Ms'], [100] * 8)

    def test_sustained_slow_successes_fail_even_when_failures_are_fast(self):
        result = evaluate(healthy([100, 100, 100, 160, 160, 160, 160, 160]), WORKLOAD)
        self.assertIn('sustained-latency-regression:browse', result['failures'])
        self.assertEqual(result['latency']['failure:missing_pk']['p95Ms'], [100] * 8)

    def test_late_regression_is_inconclusive(self):
        result = evaluate(healthy([100] * 7 + [160]), WORKLOAD)
        self.assertEqual(result['status'], 'inconclusive')
        self.assertIn('late-latency-regression-needs-observation:browse', result['invalid'])

    def test_accepted_baseline_detects_flat_shift(self):
        result = evaluate(healthy([180] * 8), WORKLOAD, {'browse': {'p95Ms': 100}})
        self.assertEqual(result['status'], 'failed')

    def test_incorrect_http_green_response_fails(self):
        result = evaluate([*healthy(), point('checks', 0, START + 3000)], WORKLOAD)
        self.assertEqual(result['status'], 'failed')

    def test_missing_failure_case_blocks(self):
        rows = (p for p in healthy() if p['data']['tags'].get('case') != 'rollback')
        result = evaluate(rows, WORKLOAD)
        self.assertEqual(result['status'], 'failed')
        self.assertIn('insufficient-failure-coverage:rollback', result['failures'])

    def test_shortfall_cannot_pass_without_attribution(self):
        rows = (p for p in healthy() if p['metric'] != 'journey_completed')
        result = evaluate(rows, WORKLOAD)
        self.assertEqual(result['status'], 'inconclusive')

    def test_completed_boundary_arrival_is_not_a_shortfall(self):
        points = [*healthy()]
        at = START + WORKLOAD['plateauSeconds'] * 1000 + 5
        points += [point('journey_started', 1, at, journey='detail', phaseStart=str(START)),
                   point('journey_completed', 1, at + 10, journey='detail')]
        result = evaluate(points, WORKLOAD)
        self.assertEqual(result['status'], 'passed', result['invalid'])
        self.assertEqual(result['offeredJourneys'], 57601)
        self.assertEqual(result['nominalOfferedJourneys'], 57600)

    def test_extra_arrival_away_from_boundary_is_not_excused(self):
        points = [*healthy(), point('journey_started', 1, START + 3000, journey='detail', phaseStart=str(START)),
                  point('journey_completed', 1, START + 3010, journey='detail')]
        self.assertEqual(evaluate(points, WORKLOAD)['status'], 'inconclusive')

    def test_missing_latency_evidence_blocks(self):
        rows = (p for p in healthy() if p['data']['tags'].get('operation') != 'browse')
        result = evaluate(rows, WORKLOAD)
        self.assertEqual(result['status'], 'inconclusive')

    def test_hard_failure_survives_missing_telemetry(self):
        result = evaluate([point('http_req_failed', 1, START)], WORKLOAD)
        self.assertEqual(result['status'], 'failed')


if __name__ == '__main__':
    unittest.main()
