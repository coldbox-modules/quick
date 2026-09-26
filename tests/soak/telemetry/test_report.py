import json
from pathlib import Path
import tempfile
import unittest

from report import plateau_latency, window_rates


class ReportTests(unittest.TestCase):
    def test_p99_counts_verified_plateau_requests_without_mixing_failure_latency(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / 'k6.ndjson'
            def point(metric, value, **tags):
                return {'type': 'Point', 'metric': metric, 'data': {'value': value, 'tags': tags}}
            points = [point('successful_latency', value, scenario='plateau', operation='graph') for value in range(1, 101)]
            points += [point('expected_failure_latency', 7.2, scenario='plateau', case='missing_pk'),
                       point('successful_latency', 9000, scenario='warmup', operation='graph'),
                       point('successful_latency', 8000, scenario='recovery', operation='graph'),
                       point('http_req_duration', 7000, scenario='plateau', operation='graph'),
                       point('successful_latency', -1, scenario='plateau', operation='graph'),
                       point('successful_latency', 10001, scenario='plateau', operation='graph'),
                       point('successful_latency', 8, scenario='plateau', operation='unbounded-user-label')]
            path.write_text('\n'.join(map(json.dumps, points)) + '\n{"unfinished":')
            result = plateau_latency(path, ['graph', 'failure:missing_pk', 'report_25'], 10000)
            self.assertEqual(result['operations'], {
                'graph': {'count': 100, 'p99Ms': 99},
                'failure:missing_pk': {'count': 1, 'p99Ms': 8},
                'report_25': {'count': 0, 'p99Ms': None}})
            self.assertEqual(result['excluded'], 3)

    def test_rates_use_window_completions_and_never_invent_throughput_for_incomplete_runs(self):
        traffic = {'totals': {'http_reqs': {'all': 1000}}, 'windows': [
            {'journey_completed': {'browse': 7, 'graph': 2}, 'http_reqs': {'all': 23}},
            {'journey_completed': {'browse': 12}, 'http_reqs': {'all': 30}}]}
        self.assertEqual(window_rates(traffic, {'windowSeconds': 2}, True), [
            {'window': 1, 'journeysPerSecond': 4.5, 'httpPerSecond': 11.5},
            {'window': 2, 'journeysPerSecond': 6, 'httpPerSecond': 15}])
        for workload, complete in (({'windowSeconds': 2}, False), ({}, True)):
            result = window_rates(traffic, workload, complete)
            self.assertTrue(all(row['journeysPerSecond'] is row['httpPerSecond'] is None for row in result))


if __name__ == '__main__':
    unittest.main()
