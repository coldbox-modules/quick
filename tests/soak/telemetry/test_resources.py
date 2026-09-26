import copy
import json
from pathlib import Path
import unittest

from resources import evaluate, pause_windows

PROFILE = json.loads((Path(__file__).parents[1] / 'profiles/lucee6-serial.json').read_text())
START, PLATEAU, END, IDLE, FINISH = 0, 600000, 3000000, 3300000, 3600000
TIMING = dict(warmupStartMs=START, idleStartedMs=IDLE, idleFinishedMs=FINISH)


def healthy():
    jvm = [{'kind': 'runtime', 'javaVersion': '21.0.10+7-LTS'}]
    observations = []
    for t in range(START, FINISH + 1, 10000):
        jvm.append(dict(kind='sample', time=t, uptimeMs=t+1, heapMax=PROFILE['resources']['application']['heapMiB']*1024*1024,
                        threads=44, descriptors=120, metaspaceUsed=70*1024*1024,
                        rssBytes=2000*1024*1024, processCpuTimeNs=t*1000))
        observations.append({'time': t, 'application': dict(bootId='one', applicationStarts=1, uptimeMs=t+1,
            parallelEagerLoading=False, executor={}, jdbcActive=0, jdbcIdle=4, jdbcWaiting=0, activeRequests=1, queuedRequests=0, scratchPosts=0,
            registry=dict(definitionCount=6, derivedBucketCount=6, derivedEntryCount=22), errors={'unexpected':0}),
            'database': dict(queries=t, queryTimePicoseconds=t*100000, locks=0, lockWaits=0),
            'containers': [dict(Name='run-' + role, MemPerc='60%', CPUPerc='10%') for role in ('app','mysql','k6','collector')]})
    jvm.append({'kind': 'collectorEnd', 'time': FINISH+1})
    return jvm, observations


class ResourceTests(unittest.TestCase):
    def analyze(self, jvm, observations, **kwargs):
        return evaluate(jvm, observations, PROFILE, kwargs.pop('timing', TIMING), plateau_start=PLATEAU, **kwargs)

    def test_healthy_resources_recover(self):
        r = self.analyze(*healthy())
        self.assertEqual(r['status'], 'passed', r)
        self.assertEqual(r['recovery']['threads']['idleMedian'], 44)

    def test_held_connection_fails_idle_recovery(self):
        jvm, rows = healthy()
        for r in rows:
            if r['time'] >= IDLE: r['application']['jdbcActive'] = 1
        result = self.analyze(jvm, rows)
        self.assertIn('idle-resource-not-released:jdbcActive', result['failures'])

    def test_threads_cannot_accumulate_below_absolute_ceiling(self):
        jvm, rows = healthy()
        for r in jvm:
            if r.get('kind') == 'sample' and r['time'] >= IDLE: r['threads'] = 65
        self.assertIn('resource-did-not-recover:threads', self.analyze(jvm, rows)['failures'])

    def test_telemetry_gap_is_inconclusive(self):
        jvm, rows = healthy()
        jvm = [r for r in jvm if not 1500000 < r.get('time', 0) < 1530000]
        self.assertIn('jvm:telemetry-gap', self.analyze(jvm, rows)['invalid'])

    def test_sustained_gc_pause_pressure_fails(self):
        jvm, rows = healthy()
        for i in (2,3,4): jvm.append(dict(kind='pause', time=PLATEAU+i*300000+50000, durationMs=36000))
        self.assertIn('sustained-gc-pressure', self.analyze(jvm, rows)['failures'])

    def test_final_gc_window_cannot_evade_persistence(self):
        jvm, rows = healthy()
        jvm.append(dict(kind='pause', time=END-60000, durationMs=36000))
        r = self.analyze(jvm, rows)
        self.assertEqual(r['status'], 'inconclusive')
        self.assertIn('late-gc-pressure-needs-observation', r['invalid'])

    def test_overlapping_pauses_are_unioned_and_split(self):
        points = [dict(kind='pause', time=900, durationMs=200), dict(kind='pause', time=950, durationMs=200)]
        windows = pause_windows(points*2, 0, 2000, 1000)
        self.assertEqual([w['pauseMs'] for w in windows], [100,150])

    def test_concurrent_cycle_duration_is_not_stop_the_world(self):
        jvm, rows = healthy()
        jvm.append(dict(kind='gc', name='Z', time=PLATEAU+100000, durationMs=90000))
        r = self.analyze(jvm, rows)
        self.assertEqual(r['status'], 'passed')
        self.assertEqual(r['gcWindows'][0]['cycleElapsedMs'], 90000)
        self.assertEqual(r['gcWindows'][0]['pauseMs'], 0)

    def test_headroom_exhaustion_fails_after_two_minutes(self):
        jvm, rows = healthy()
        for r in rows:
            if 1500000 <= r['time'] <= 1620000: r['containers'][0]['MemPerc'] = '91%'
        self.assertIn('sustained-memory-headroom-exhaustion', self.analyze(jvm, rows)['failures'])

    def test_gap_does_not_manufacture_headroom_persistence(self):
        jvm, rows = healthy()
        for r in rows:
            if r['time'] in (1500000,1620000): r['containers'][0]['MemPerc'] = '91%'
        rows = [r for r in rows if not 1500000 < r['time'] < 1620000]
        r = self.analyze(jvm, rows)
        self.assertNotIn('sustained-memory-headroom-exhaustion', r['failures'])
        self.assertEqual(r['status'], 'inconclusive')

    def test_crash_wins_over_missing_phase_evidence(self):
        r = self.analyze([], [], timing={}, exits={'app': {'OOMKilled': True}})
        self.assertEqual(r['status'], 'failed')
        self.assertIn('oom:app', r['failures'])

    def test_restart_fails_without_http_errors(self):
        jvm, rows = healthy()
        rows[-1]['application']['bootId'] = 'two'
        self.assertIn('application-lifecycle-changed', self.analyze(jvm, rows)['failures'])

    def test_missing_lifecycle_is_inconclusive_not_invented_restart(self):
        r = self.analyze([], [])
        self.assertEqual(r['status'], 'inconclusive')
        self.assertNotIn('application-lifecycle-changed', r['failures'])

    def test_growing_reserved_heap_or_rss_alone_does_not_fail(self):
        jvm, rows = healthy()
        for r in jvm:
            if r.get('kind') == 'sample': r['rssBytes'] += r['time'] * 100
        self.assertEqual(self.analyze(jvm, rows)['status'], 'passed')

    def test_live_capacity_step_does_not_claim_final_collection(self):
        jvm, rows = healthy()
        jvm = [row for row in jvm if row['kind'] != 'collectorEnd']
        self.assertEqual(self.analyze(jvm, rows)['status'], 'inconclusive')
        result = self.analyze(jvm, rows, finalized=False)
        self.assertEqual(result['status'], 'passed')
        self.assertIs(result['finalized'], False)

class ParallelResourceTests(unittest.TestCase):
    def analyze(self, mutation=None):
        profile = json.loads((Path(__file__).parents[1] / 'profiles/lucee6-parallel.json').read_text())
        jvm, rows = healthy()
        for row in rows:
            row['application'].update(parallelEagerLoading=True, executor=dict(
                maxThreads=4, poolSize=4, active=0, queued=0, queueCapacity=64, completed=row['time']//1000))
        if mutation:
            mutation(rows)
        return evaluate(jvm, rows, profile, TIMING, plateau_start=PLATEAU)

    def test_parallel_work_completes_and_drains(self):
        self.assertEqual(self.analyze()['status'], 'passed')

    def test_enabling_module_without_exercising_workers_does_not_pass(self):
        def mutate(rows):
            for row in rows: row['application']['executor']['completed'] = 0
        self.assertIn('parallel-work-not-observed', self.analyze(mutate)['invalid'])

    def test_serial_fallback_does_not_claim_parallel_coverage(self):
        def mutate(rows):
            for row in rows: row['application']['parallelEagerLoading'] = False
        self.assertIn('eager-loading-mode-mismatch', self.analyze(mutate)['invalid'])

    def test_unbounded_executor_or_queue_blocks(self):
        def mutate(rows):
            rows[10]['application']['executor']['queueCapacity'] = 2147483647
        self.assertIn('executor-configuration-mismatch', self.analyze(mutate)['failures'])

    def test_pending_work_at_idle_blocks(self):
        def mutate(rows):
            rows[-1]['application']['executor']['queued'] = 1
        self.assertIn('idle-executor-not-released:queued', self.analyze(mutate)['failures'])

    def test_missing_executor_observation_is_inconclusive(self):
        def mutate(rows):
            rows[10]['application']['executor'].pop('completed')
        self.assertIn('missing-executor-metric', self.analyze(mutate)['invalid'])

if __name__ == '__main__': unittest.main()
