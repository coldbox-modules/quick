import copy
import json
from pathlib import Path
from types import SimpleNamespace
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).parents[1]))
from controller import Controller
from resources import coverage

PROFILE = json.loads((Path(__file__).parents[1] / 'profiles/lucee6-serial.json').read_text())


class Clock:
    def __init__(self):
        self.now = 1000

    def read(self):
        return self.now

    def sleep(self, seconds):
        self.now += seconds


class ControllerSamplingTests(unittest.TestCase):
    def exercise(self, *, exit_code=0, delivery_status='passed'):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        profile = copy.deepcopy(PROFILE)
        profile['workload'].update(warmupSeconds=5, rampSeconds=5, plateauSeconds=5,
                                   recoverySeconds=5, idleSeconds=30, sampleSeconds=10)
        profile_path = root / 'profile.json'
        profile_path.write_text(json.dumps(profile))
        controller = Controller(SimpleNamespace(profile=profile_path, output=root / 'run',
                                                development=False, fault='none'))
        clock = Clock()
        controller.setup = Mock()
        controller.start_container = Mock(return_value='owned-generator')
        controller.docker = Mock()
        controller.http = Mock(return_value={key: 0 for key in
                               ('scratchPosts', 'jdbcActive', 'jdbcWaiting', 'queuedRequests')})
        controller.inspect = Mock(side_effect=lambda name: {
            'State': {'Running': clock.now < 1020, 'ExitCode': exit_code, 'OOMKilled': False},
            'Image': 'recorded-image',
            'HostConfig': {'Memory': 512, 'MemorySwap': 1024, 'NanoCpus': 250000000}})
        (controller.out / 'k6.ndjson').write_text('{}\n')
        observations = controller.out / 'observations.ndjson'
        observations.touch()

        def collect():
            with observations.open('a') as stream:
                stream.write(json.dumps({'time': clock.now * 1000}) + '\n')

        controller.collect = collect
        analysis_started = []

        def slow_analysis(*args):
            analysis_started.append(clock.now * 1000)
            clock.sleep(20)  # Longer than the unchanged 15-second telemetry limit.
            return {'phaseStartsMs': {'warmup': 1000000}, 'status': delivery_status}

        delivery = Mock(return_value={'status': delivery_status,
                       'reasons': [] if delivery_status == 'passed' else ['delivery-application-overloaded']})
        error = None
        with patch('controller.time.time', clock.read), patch('controller.time.monotonic', clock.read), \
                patch('controller.time.sleep', clock.sleep), \
                patch('controller.evaluate_traffic', side_effect=slow_analysis), \
                patch('controller.evaluate_delivery', delivery):
            try:
                controller.run()
            except RuntimeError as caught:
                error = caught
        rows = [json.loads(line) for line in observations.read_text().splitlines()]
        return controller, rows, analysis_started, delivery, error

    def test_slow_full_file_analysis_preserves_observation_cadence_and_delivery_inputs(self):
        controller, rows, analysis_started, delivery, error = self.exercise()
        self.assertIsNone(error)
        timing = controller.timing
        self.assertEqual(coverage(rows, timing['warmupStartMs'], timing['idleFinishedMs'],
                                  PROFILE['limits']['maxTelemetryGapSeconds'] * 1000, 'application-resources'), [])
        self.assertGreaterEqual(analysis_started[0], timing['idleFinishedMs'])
        self.assertEqual(timing['idleFinishedMs'] - timing['idleStartedMs'], 30000)
        self.assertEqual([row['time'] for row in delivery.call_args.args[1]], [1000000, 1010000])
        self.assertEqual(controller.summary['state'], 'complete')
        self.assertFalse(controller.summary['releaseQualified'])

    def test_failed_generator_is_classified_without_waiting_through_idle(self):
        controller, rows, analysis_started, delivery, error = self.exercise(
            exit_code=99, delivery_status='failed')
        self.assertIsInstance(error, RuntimeError)
        self.assertEqual(str(error), 'delivery-application-overloaded')
        self.assertNotIn('idleStartedMs', controller.timing)
        self.assertEqual(analysis_started, [1020000])
        self.assertEqual([row['time'] for row in rows], [1000000, 1010000])
        self.assertEqual(delivery.call_args.args[3]['ExitCode'], 99)
        self.assertFalse(controller.summary['releaseQualified'])


if __name__ == '__main__':
    unittest.main()
