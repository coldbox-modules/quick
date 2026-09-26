import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).parents[1]))
from capacity import complete_rows, recommendation, step_profile

PROFILE = json.loads((Path(__file__).parents[1] / 'profiles/lucee6-serial.json').read_text())


class CapacityTests(unittest.TestCase):
    def step(self, rate, clean=True, p99=500):
        return {'rate': rate, 'clean': clean, 'journeyP99Ms': p99}

    def test_sixty_percent_of_highest_clean_step(self):
        result = recommendation([self.step(n) for n in (5, 10, 20, 40)], PROFILE)
        self.assertEqual(result['rate'], 24)
        self.assertEqual(result['requiredVUsWithDoubleHeadroom'], 24)
        self.assertTrue(result['trialProfileEligible'])

    def test_failed_step_is_never_selected(self):
        result = recommendation([self.step(5), self.step(10), self.step(20, False)], PROFILE)
        self.assertEqual(result['rate'], 6)
        self.assertEqual(result['highestCleanRate'], 10)

    def test_slow_journeys_require_vu_headroom_without_silent_rate_reduction(self):
        result = recommendation([self.step(40, p99=5000)], PROFILE)
        self.assertEqual(result['rate'], 24)
        self.assertEqual(result['requiredVUsWithDoubleHeadroom'], 240)
        self.assertFalse(result['trialProfileEligible'])

    def test_low_rate_cannot_waive_production_latency_sample_floor(self):
        result = recommendation([self.step(5)], PROFILE)
        self.assertEqual(result['rate'], 3)
        self.assertFalse(result['trialProfileEligible'])
        self.assertIn('selected-rate-cannot-meet-latency-sample-floor-revise-coverage-and-recalibrate', result['reasons'])
        self.assertEqual(PROFILE['workload']['minimumLatencySamples'], 200)

    def test_no_clean_step_is_inconclusive(self):
        result = recommendation([self.step(5, False)], PROFILE)
        self.assertIsNone(result['rate'])
        self.assertFalse(result['trialProfileEligible'])

    def test_development_capacity_is_never_labeled_trial_eligible(self):
        profile = copy.deepcopy(PROFILE)
        profile['workload'].update(shortDevelopment=True, minimumLatencySamples=1)
        result = recommendation([self.step(5)], profile)
        self.assertFalse(result['trialProfileEligible'])
        self.assertIn('development-capacity-cannot-qualify-trials', result['reasons'])

    def test_a_later_clean_step_cannot_erase_an_earlier_failure(self):
        result = recommendation([self.step(5), self.step(10, False), self.step(40)], PROFILE)
        self.assertEqual(result['highestCleanRate'], 5)
        self.assertFalse(result['trialProfileEligible'])

    def test_live_reader_ignores_only_unfinished_suffix(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'live.ndjson'
            path.write_bytes(b'{"time":1}\n{"time":')
            self.assertEqual(complete_rows(path), [{'time': 1}])
            path.write_bytes(b'{"time":1}\nnot-json\n')
            with self.assertRaises(json.JSONDecodeError):
                complete_rows(path)

    def test_capacity_comparisons_have_enough_samples_before_rate_increase(self):
        for rate in (5, 10, 20, 40):
            with self.subTest(rate=rate):
                stage = step_profile(PROFILE, rate)['workload']
                self.assertEqual(stage['minimumLatencySamples'], 200)
                self.assertEqual(stage['windowSeconds'], stage['plateauSeconds'])
                usable = stage['plateauSeconds'] - stage['drainSeconds'] - stage['requestTimeoutSeconds']
                self.assertGreaterEqual(usable * rate / 30, 200)
        self.assertEqual(PROFILE['workload']['windowSeconds'], 300)


if __name__ == '__main__':
    unittest.main()
