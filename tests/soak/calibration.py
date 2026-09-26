#!/usr/bin/env python3
"""Run one full baseline trial against a verified CI capacity result.

No publisher and no accepted baseline are needed. A successful result means
only that this trial is eligible for review with two other matching trials.
"""
import argparse
import copy
import json
from pathlib import Path

from capacity import complete_rows, recommendation, step_profile
from controller import Controller, Inconclusive, execute, write_json
from identity import build_identity, digest, profile_identity, read, require_match, sha_file
from package import verify
from resources import evaluate as evaluate_resources
from traffic import evaluate as evaluate_traffic


SCHEDULE = {'warmupSeconds': 300, 'rampSeconds': 300, 'plateauSeconds': 2400,
            'recoverySeconds': 300, 'idleSeconds': 300, 'windowSeconds': 300}


def validate_trial_profile(profile):
    profile_identity(profile)
    w = profile['workload']
    if any(w.get(key) != value for key, value in SCHEDULE.items()):
        raise ValueError('Calibration requires the complete 60-minute schedule')
    if w.get('shortDevelopment') or w.get('capacityProbe') or profile.get('fault', 'none') != 'none':
        raise ValueError('Development, capacity, or fault profiles cannot become baseline trials')
    if w['minimumLatencySamples'] < 200 or w['minimumFailuresPerCase'] < 100:
        raise ValueError('Calibration cannot waive required coverage')
    if not isinstance(w['rate'], int) or w['rate'] < 1:
        raise ValueError('Calibration requires a positive fixed arrival rate')
    if not 0 <= w['drainSeconds'] < w['windowSeconds'] or not 0 < w['sampleSeconds'] <= 15:
        raise ValueError('Calibration timing inputs are invalid')


def capacity_reference(run):
    run = Path(run)
    assessment, summary, base = (read(run / name) for name in ('capacity-analysis.json', 'summary.json', 'profile.json'))
    if assessment.get('development') is not False or not assessment.get('collectionComplete'):
        raise ValueError('Capacity must be a complete CI sweep')
    if summary['status'] != 'capacity-measured' or summary['reasons']:
        raise ValueError('Capacity sweep did not produce an eligible target')
    steps = assessment['steps']
    if not steps or [s['rate'] for s in steps] != base['capacity']['rates'][:len(steps)]:
        raise ValueError('Capacity evidence is not the planned increasing prefix')
    if any(not s['clean'] for s in steps[:-1]):
        raise ValueError('Capacity increased after an unclean step')
    proposed = recommendation(steps, base)
    if proposed != assessment['recommendation'] or not proposed['trialProfileEligible']:
        raise ValueError('Capacity target does not satisfy headroom and coverage policy')
    profile = copy.deepcopy(base)
    profile['workload']['rate'] = proposed['rate']
    if profile != assessment['profileForTrials'] or read(run / 'proposed-trial-profile.json') != profile:
        raise ValueError('Proposed profile differs from measured capacity inputs')
    validate_trial_profile(profile)
    jvm, observations = complete_rows(run / 'jvm/jvm.ndjson'), complete_rows(run / 'observations.ndjson')
    if not jvm or jvm[-1].get('kind') != 'collectorEnd' or read(run / 'collector-exit.json')['ExitCode'] != 0:
        raise ValueError('Capacity telemetry did not finish')
    if (run / 'jvm/recording-final.jfr').stat().st_size == 0:
        raise ValueError('Capacity JFR is missing')
    reference = None
    evidence = {}
    generator = None
    for step in steps:
        if not step['clean']:
            break
        label = 'capacity/rate-' + str(step['rate'])
        if step['directory'] != label:
            raise ValueError('Unexpected capacity evidence directory')
        stage = run / label
        stage_profile = read(stage / 'profile.json')
        if stage_profile != step_profile(base, step['rate']):
            raise ValueError('Capacity stage profile changed')
        with (stage / 'k6.ndjson').open() as stream:
            traffic = evaluate_traffic((json.loads(line) for line in stream if line.strip()), stage_profile['workload'], reference)
        timing = read(stage / 'timing.json')
        # Later exploratory steps may saturate by design; evaluate each clean
        # step against the observations available at its own decision boundary.
        end = timing['idleFinishedMs']
        stage_jvm = [row for row in jvm if row.get('kind') in ('runtime', 'collectorEnd') or row['time'] <= end]
        stage_observations = [row for row in observations if row['time'] <= end]
        resources = evaluate_resources(stage_jvm, stage_observations, stage_profile, timing,
                                       plateau_start=traffic['plateauStartMs'])
        state = read(stage / 'generator-exit.json')
        if traffic['status'] != 'passed' or resources['status'] != 'passed' or state['ExitCode'] or state['OOMKilled']:
            raise ValueError('Raw capacity evidence does not substantiate the clean step')
        p99 = read(stage / 'k6-summary.json')['metrics']['journey_duration']['values']['p(99)']
        if p99 != step['journeyP99Ms']:
            raise ValueError('Capacity journey headroom changed')
        if reference is None:
            reference = {name: {'p95Ms': value['earlyP95Ms']} for name, value in traffic['latency'].items()}
        current_generator = read(stage / 'generator.json')
        if generator and generator != current_generator:
            raise ValueError('Generator identity changed during capacity sweep')
        generator = current_generator
        for name in ('profile.json', 'k6.ndjson', 'k6-summary.json', 'generator-exit.json', 'generator.json', 'timing.json'):
            evidence[label + '/' + name] = sha_file(stage / name)
    for name in ('capacity-analysis.json', 'summary.json', 'host.json', 'harness-manifest.json', 'profile.json',
                 'jvm/jvm.ndjson', 'jvm/recording-final.jfr', 'observations.ndjson', 'package/package-manifest.json'):
        evidence[name] = sha_file(run / name)
    package = read(run / 'package/package-manifest.json')
    verify(run / 'package', package['candidateSha'])
    return {'schema': 1, 'runId': summary['runId'], 'githubRunId': read(run / 'host.json')['githubRunId'],
            'profile': profile, 'package': package, 'identity': build_identity(run, profile=profile, generator=generator),
            'evidence': evidence, 'evidenceSha256': digest(evidence)}


class CalibrationController(Controller):
    def setup(self):
        # Fail before provisioning if the proposed rate or package provenance
        # does not follow from the complete capacity evidence.
        self.reference = capacity_reference(self.args.capacity)
        if profile_identity(self.profile) != profile_identity(self.reference['profile']):
            raise Inconclusive('Trial profile differs from the capacity proposal')
        validate_trial_profile(self.profile)
        super().setup()
        write_json(self.out / 'capacity-reference.json', self.reference)
        if read(self.out / 'package/package-manifest.json') != self.reference['package']:
            raise Inconclusive('Baseline trials must use the exact healthy capacity package')
        # Resolve and inspect the actual generator image and budgets before any
        # workload arrivals. The final running generator is checked again below.
        r = self.profile['resources']['generator']
        probe = self.start_container('generator-preflight', ['--network', self.prefix, '--cpus', str(r['cpus']),
            '--memory', f'{r["memoryMiB"]}m', '--user', '0'], self.profile['images']['k6'], ['version'])
        actual = self.inspect(probe)
        generator = {'image': actual['Image'], 'limits': {key: actual['HostConfig'][key]
                     for key in ('Memory', 'MemorySwap', 'NanoCpus')}}
        identity = build_identity(self.out, generator=generator)
        write_json(self.out / 'measurement-identity.json', identity)
        require_match(self.reference['identity'], identity)

    def analyze_resources(self):
        super().analyze_resources()
        if self.summary.get('state') != 'complete':
            return
        identity = build_identity(self.out)
        require_match(self.reference['identity'], identity)
        write_json(self.out / 'measurement-identity.json', identity)
        expected = {'traffic': 'passed', 'resources': 'passed', 'memory': 'passed'}
        if (self.summary['status'] == 'inconclusive' and self.summary.get('assessments') == expected
                and self.summary['reasons'] == ['accepted-baseline-and-profile-qualification-required']):
            self.summary.update(status='calibration-passed', reasons=[], releaseQualified=False)
        write_json(self.out / 'summary.json', self.summary)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--capacity', type=Path, required=True, help='Downloaded complete CI capacity artifact directory')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    args.profile = args.capacity / 'proposed-trial-profile.json'
    args.package = args.capacity / 'package'
    args.candidate = read(args.package / 'package-manifest.json')['candidateSha']
    args.development, args.fault = False, 'none'
    controller = CalibrationController(args)
    execute(controller)
    return 0 if controller.summary['status'] == 'calibration-passed' else 1


if __name__ == '__main__':
    raise SystemExit(main())
