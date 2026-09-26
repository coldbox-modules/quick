#!/usr/bin/env python3
"""Observe capacity without publication or baseline acceptance.

One application, database and collector survive warmup and every rate step.
Each bounded k6 invocation must finish and pass before the next rate starts.
Generator startup/drain/idle intervals are retained outside step comparisons.
"""
import argparse
import copy
import json
import math
from pathlib import Path
import time

from controller import Controller, HERE, Inconclusive, execute, write_json
from traffic import evaluate as evaluate_traffic, timestamp
from resources import evaluate as evaluate_resources


def complete_rows(path):
    # The external collector can be appending its final line during a step
    # decision. Ignore only that unfinished suffix, never malformed full lines.
    data = path.read_bytes()
    return [json.loads(line) for line in data[:data.rfind(b'\n') + 1].splitlines() if line]


def recommendation(steps, profile):
    clean = []
    for step in steps:
        if not step['clean']:
            break
        clean.append(step)
    if not clean:
        return {'rate': None, 'trialProfileEligible': False, 'reasons': ['no-clean-capacity-step']}
    highest = clean[-1]
    rate = math.floor(highest['rate'] * 0.6)
    w = profile['workload']
    required_vus = max(1, math.ceil(rate * highest['journeyP99Ms'] / 1000 * 2))
    # This is a feasibility check, not a waiver of actual per-window counts.
    # The rarest operation is one of three equally rotated report sizes.
    expected_minimum = rate * (w['windowSeconds'] - w['drainSeconds']) * 0.1 / 3
    reasons = []
    if required_vus > w['vus']:
        reasons.append('increase-generator-allocation-and-repeat-capacity-calibration')
    if expected_minimum < w['minimumLatencySamples']:
        reasons.append('selected-rate-cannot-meet-latency-sample-floor-revise-coverage-and-recalibrate')
    return {'rate': rate, 'highestCleanRate': highest['rate'], 'vus': w['vus'], 'requiredVUsWithDoubleHeadroom': required_vus,
            'expectedRarestOperationSamplesInFirstWindow': expected_minimum,
            'trialProfileEligible': not reasons, 'reasons': reasons}


def step_profile(base, rate):
    profile = copy.deepcopy(base)
    config = base.get('capacity', {})
    profile['mode'] = 'capacity-step'
    profile['workload'].update(rate=rate, plateauSeconds=config.get('stepSeconds', 180), recoverySeconds=0,
        idleSeconds=config.get('idleSeconds', 30), windowSeconds=60, minimumFailuresPerCase=10,
        minimumLatencySamples=3, capacityProbe=True)
    if not base['workload'].get('shortDevelopment'):
        w = profile['workload']
        # Rare reports receive 1/30 of arrivals. Compare aggregate step p95s
        # only after each operation has >=200 samples; a three-minute low-rate
        # probe had only 5-10 and could mistake one slow response for a trend.
        # Full trials retain independent five-minute windows and trend rules.
        minimum = base['workload']['minimumLatencySamples']
        seconds = math.ceil((minimum * 30 / rate + w['drainSeconds'] + w['requestTimeoutSeconds']) / 60) * 60
        seconds = max(seconds, config.get('stepSeconds', 180))
        w.update(plateauSeconds=seconds, windowSeconds=seconds, minimumLatencySamples=minimum,
                 minimumFailuresPerCase=base['workload']['minimumFailuresPerCase'])
    return profile


class CapacityController(Controller):
    def run_generator(self, label, profile):
        stage = self.out / 'capacity' / label
        stage.mkdir(parents=True)
        write_json(stage / 'profile.json', profile)
        r, w = profile['resources']['generator'], profile['workload']
        self.env.update(SOAK_URL='http://application:8080', SOAK_RUN_ID=self.run_id + '_' + label)
        self.generator = self.start_container('capacity-' + label + '-k6', [
            '--network', self.prefix, '--cpus', str(r['cpus']), '--memory', f'{r["memoryMiB"]}m', '--user', '0',
            '-v', f'{self.out}:/work', '-e', 'SOAK_TOKEN', '-e', 'SOAK_URL', '-e', 'SOAK_RUN_ID',
            '-e', f'SOAK_PROFILE=/work/capacity/{label}/profile.json', '-e', 'SOAK_FIXTURES=/work/fixtures/fixture-manifest.json',
            '-e', f'SOAK_SUMMARY=/work/capacity/{label}/k6-summary.json'], self.profile['images']['k6'],
            ['run', '--no-usage-report', '--out', f'json=/work/capacity/{label}/k6.ndjson', '/work/k6/workload.mjs'])
        state = self.inspect(self.generator)
        write_json(stage / 'generator.json', {'image': state['Image'], 'limits': {key: state['HostConfig'][key]
                   for key in ('Memory', 'MemorySwap', 'NanoCpus')}})
        self.summary['state'] = 'capacity-' + label
        write_json(self.out / 'summary.json', self.summary)
        duration = w['warmupSeconds'] if profile['mode'] == 'capacity-warmup' else w['plateauSeconds']
        deadline = time.monotonic() + duration + w['drainSeconds'] + 60
        saturated = 0
        stop = None
        while self.inspect(self.generator)['State']['Running']:
            start = time.monotonic()
            row = self.collect()
            # Explore only the region with resource headroom; do not knowingly
            # increase the next rate after borrowing queues or generator limits.
            app = row['application']
            if app['jdbcWaiting'] or app['queuedRequests']:
                stop = 'application-pool-or-request-queue'
            generator = next(item for item in row['containers'] if item['Name'] == self.generator)
            usage = float(generator['CPUPerc'].rstrip('%')) / (100 * r['cpus'])
            saturated = saturated + 1 if usage >= 0.9 else 0
            if saturated >= 3 or float(generator['MemPerc'].rstrip('%')) > 90:
                stop = 'generator-capacity-exhausted'
            if time.monotonic() > deadline:
                stop = 'generator-duration-exceeded'
            if stop:
                self.docker('stop', '--time', '10', self.generator, timeout=20)
                break
            time.sleep(max(0, start + w['sampleSeconds'] - time.monotonic()))
        state = self.inspect(self.generator)['State']
        write_json(stage / 'generator-exit.json', state)
        self.docker('logs', self.generator, log=f'capacity/{label}/k6.log')
        if state['OOMKilled']:
            stop = 'generator-oom'
        elif state['ExitCode'] != 0:
            stop = stop or 'generator-or-http-threshold-failed'
        return stage, stop

    def run(self):
        self.setup()
        base = copy.deepcopy(self.profile)
        config = base.get('capacity', {})
        rates = config.get('rates', [5, 10, 20, 40])
        if not rates or rates != sorted(set(rates)) or any(not isinstance(rate, int) or rate < 1 for rate in rates):
            raise ValueError('Capacity rates must be distinct, positive, increasing integers')
        self.measured_start = time.time()
        warmup = copy.deepcopy(base)
        warmup['mode'] = 'capacity-warmup'
        stage, stop = self.run_generator('warmup', warmup)
        warmup_rows = complete_rows(stage / 'k6.ndjson')
        starts = [row['data'] for row in warmup_rows if row.get('type') == 'Point' and row['metric'] == 'journey_started']
        completed = sum(row['data']['value'] for row in warmup_rows if row.get('type') == 'Point' and row['metric'] == 'journey_completed')
        if stop or not starts:
            raise Inconclusive('Capacity warmup did not complete: ' + (stop or 'missing-starts'))
        nominal = base['workload']['rate'] * base['workload']['warmupSeconds'] / 10
        if not nominal <= len(starts) <= nominal + 1 or completed != len(starts):
            raise Inconclusive('Capacity warmup traffic did not complete')
        self.warmup_epoch = float(starts[0]['tags']['phaseStart'])
        if timestamp(starts[-1]['time']) < self.warmup_epoch + base['workload']['warmupSeconds'] * 1000 - 10000 / base['workload']['rate'] - 1000:
            raise Inconclusive('Capacity warmup was abbreviated')
        self.steps = []
        reference = None
        for rate in rates:
            profile = step_profile(base, rate)
            w = profile['workload']
            label = 'rate-' + str(rate)
            print(f'Capacity: {rate} journeys/second for {w["plateauSeconds"]} seconds', flush=True)
            stage, stop = self.run_generator(label, profile)
            with (stage / 'k6.ndjson').open() as stream:
                traffic = evaluate_traffic((json.loads(line) for line in stream if line.strip()), w, reference)
            write_json(stage / 'traffic-analysis.json', traffic)
            resources = None
            if not stop:
                idle_started = int(time.time() * 1000)
                idle_end = time.monotonic() + w['idleSeconds']
                while time.monotonic() < idle_end:
                    start = time.monotonic()
                    self.collect()
                    time.sleep(max(0, min(idle_end, start + w['sampleSeconds']) - time.monotonic()))
                timing = {'warmupStartMs': self.warmup_epoch, 'idleStartedMs': idle_started,
                          'idleFinishedMs': int(time.time() * 1000)}
                write_json(stage / 'timing.json', timing)
                resources = evaluate_resources(complete_rows(self.out / 'jvm/jvm.ndjson'),
                    complete_rows(self.out / 'observations.ndjson'), profile, timing,
                    plateau_start=traffic['plateauStartMs'], finalized=False)
                write_json(stage / 'resource-analysis.json', resources)
            metric = json.loads((stage / 'k6-summary.json').read_text())['metrics'].get('journey_duration', {}).get('values', {})
            p99 = metric.get('p(99)')
            clean = not stop and traffic['status'] == 'passed' and resources['status'] == 'passed' and p99 is not None
            self.steps.append({'rate': rate, 'clean': clean, 'stopReason': stop, 'directory': str(stage.relative_to(self.out)),
                               'traffic': traffic['status'], 'resources': resources['status'] if resources else 'unavailable',
                               'journeyP99Ms': p99})
            self.capacity = {'releaseQualified': False, 'steps': self.steps, 'recommendation': recommendation(self.steps, base),
                             'maximumNotObserved': clean and rate == rates[-1], 'development': self.args.development}
            write_json(self.out / 'capacity-analysis.json', self.capacity)
            if not clean:
                break  # Never launch a higher rate after an unclean step.
            if reference is None:
                reference = {name: {'p95Ms': value['earlyP95Ms']} for name, value in traffic['latency'].items()}
        self.summary.update(status='capacity-measured' if self.capacity['recommendation']['rate'] else 'inconclusive',
                            state='capacity-complete', reasons=self.capacity['recommendation']['reasons'])
        self.capacity['profileForTrials'] = copy.deepcopy(base)
        self.capacity['profileForTrials']['workload']['rate'] = self.capacity['recommendation']['rate']
        write_json(self.out / 'capacity-analysis.json', self.capacity)

    def analyze_resources(self):
        # Per-step evidence is provisional until the real collector end marker
        # and every owned resource have been verified by the shared cleanup.
        if hasattr(self, 'capacity'):
            self.capacity['collectionComplete'] = self.summary['status'] == 'capacity-measured'
            write_json(self.out / 'capacity-analysis.json', self.capacity)
            if self.capacity['collectionComplete'] and self.capacity['recommendation']['trialProfileEligible'] and not self.args.development:
                write_json(self.out / 'proposed-trial-profile.json', self.capacity['profileForTrials'])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--profile', type=Path, default=HERE / 'profiles/lucee6-serial.json')
    parser.add_argument('--output', type=Path)
    parser.add_argument('--candidate')
    parser.add_argument('--package', type=Path)
    parser.add_argument('--development', action='store_true', help='Local architecture and short capacity probes; never CI calibration')
    args = parser.parse_args()
    args.fault = 'none'
    return execute(CapacityController(args))


if __name__ == '__main__':
    raise SystemExit(main())
