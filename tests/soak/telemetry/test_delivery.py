import copy
import json
from pathlib import Path
import unittest

from delivery import evaluate, SHORTFALL

PROFILE = json.loads((Path(__file__).parents[1] / 'profiles/lucee6-serial.json').read_text())


def traffic():
    return {'status': 'failed', 'failures': ['insufficient-failure-coverage:rollback'],
            'invalid': [SHORTFALL], 'plateauStartMs': 100000,
            'windows': [{'journey_started': {'browse': 7000}, 'journey_completed': {'browse': 6999},
                         'dropped_iterations': {'all': 200}}]}


def rows(generator=10, application=10, mysql=10, start=100000):
    return [{'time': start + i * 10000, 'application': {'jdbcWaiting': 0, 'queuedRequests': 0},
             'database': {'lockWaits': 0}, 'containers': [
                 {'Name': 'run-k6', 'CPUPerc': str(generator) + '%'},
                 {'Name': 'run-app', 'CPUPerc': str(application) + '%'},
                 {'Name': 'run-mysql', 'CPUPerc': str(mysql) + '%'}]} for i in range(4)]


class DeliveryTests(unittest.TestCase):
    def assess(self, data=None, observations=None, state=None):
        return evaluate(data or traffic(), observations or rows(), PROFILE,
                        state or {'ExitCode': 99, 'OOMKilled': False})

    def test_generator_saturation_is_inconclusive_not_a_missing_exception_bug(self):
        result = self.assess(observations=rows(generator=75))
        self.assertEqual(result['status'], 'inconclusive')
        self.assertEqual(result['reasons'], ['delivery-generator-capacity-exhausted'])
        self.assertEqual(result['missingCoverage'], ['insufficient-failure-coverage:rollback'])

    def test_application_saturation_at_offered_load_fails(self):
        result = self.assess(observations=rows(application=190))
        self.assertEqual(result['status'], 'failed')
        self.assertIn('delivery-application-overloaded', result['reasons'])

    def test_database_waiting_with_generator_headroom_is_application_overload(self):
        observations = rows()
        for row in observations: row['application']['jdbcWaiting'] = 3
        self.assertEqual(self.assess(observations=observations)['status'], 'failed')

    def test_both_saturated_or_no_proven_cause_are_inconclusive(self):
        result = self.assess(observations=rows(generator=75, application=200))
        self.assertEqual(result['status'], 'inconclusive')
        self.assertIn('delivery-both-application-and-generator-saturated', result['reasons'])
        self.assertIn('delivery-cause-unresolved', self.assess()['reasons'])

    def test_generator_oom_does_not_manufacture_application_failure(self):
        result = self.assess(state={'ExitCode': 137, 'OOMKilled': True})
        self.assertEqual(result['status'], 'inconclusive')

    def test_correctness_and_http_failures_still_fail_during_generator_saturation(self):
        for reason in ('incorrect-response-contract', 'unexpected-http-failure', 'unexpected-errors'):
            with self.subTest(reason=reason):
                data = traffic()
                data['failures'].append(reason)
                result = self.assess(data=data, observations=rows(generator=75))
                self.assertEqual(result['status'], 'failed')
                self.assertIn(reason, result['reasons'])

    def test_missing_case_without_delivery_shortfall_still_fails(self):
        data = traffic()
        data['invalid'] = []
        result = self.assess(data=data, state={'ExitCode': 0, 'OOMKilled': False})
        self.assertEqual(result['status'], 'failed')
        self.assertIn('insufficient-failure-coverage:rollback', result['reasons'])
        self.assertEqual(self.assess(data=data)['status'], 'failed')

    def test_pressure_outside_shortfall_window_cannot_explain_it(self):
        result = self.assess(observations=rows(application=200, start=900000))
        self.assertEqual(result['status'], 'inconclusive')
        self.assertEqual(result['reasons'], ['delivery-cause-unresolved'])

    def test_a_cpu_spike_or_gapped_samples_do_not_prove_sustained_overload(self):
        observations = rows(application=200)
        observations[1]['containers'][1]['CPUPerc'] = '10%'
        self.assertEqual(self.assess(observations=observations)['status'], 'inconclusive')
        observations = rows(application=200)
        for i, row in enumerate(observations): row['time'] = 100000 + i * 30000
        self.assertEqual(self.assess(observations=observations)['status'], 'inconclusive')

    def test_missing_generator_metrics_cannot_prove_application_only_saturation(self):
        observations = rows(application=200)
        for row in observations: row['containers'].pop(0)
        self.assertEqual(self.assess(observations=observations)['status'], 'inconclusive')

    def test_complete_healthy_delivery_stays_passed(self):
        data = traffic()
        data.update(status='passed', invalid=[], failures=[])
        self.assertEqual(self.assess(data=data, state={'ExitCode': 0, 'OOMKilled': False})['status'], 'passed')


if __name__ == '__main__':
    unittest.main()
