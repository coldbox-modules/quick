#!/usr/bin/env python3
"""Reproduce a completed calibration trial from retained raw evidence.

A successful review means saved assessments reproduce, including failed or
inconclusive assessments. It does not accept a baseline or qualify a release.
"""
import argparse
import json
from pathlib import Path
import sys

from baseline import EVIDENCE, raw_early_latency, rows, trial
from calibration import validate_trial_profile
from identity import build_identity, read, require_match, sha_file

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / 'telemetry'))
import delivery
import memory
import resources
import traffic


def review(run):
    summary, profile = read(run / 'summary.json'), read(run / 'profile.json')
    if summary['state'] != 'complete' or summary['releaseQualified'] is not False:
        raise ValueError('Expected a completed, unqualified calibration trial')
    validate_trial_profile(profile)
    hashes = {name: sha_file(run / name) for name in EVIDENCE}
    for name in ('traffic.py', 'delivery.py', 'resources.py', 'memory.py'):
        if sha_file(run / 'harness/telemetry' / name) != sha_file(HERE / 'telemetry' / name):
            raise ValueError('Review requires the recorded analyzer version: ' + name)
    identity = build_identity(run)
    require_match(read(run / 'measurement-identity.json'), identity)
    capacity = read(run / 'capacity-reference.json')
    require_match(capacity['identity'], identity)
    if read(run / 'package/package-manifest.json') != capacity['package']:
        raise ValueError('Trial package differs from capacity package')
    timing = read(run / 'timing.json')
    jvm, observations = list(rows(run / 'jvm/jvm.ndjson')), list(rows(run / 'observations.ndjson'))
    exits = {role: read(run / (role + '-exit.json')) for role in ('app', 'mysql', 'k6', 'collector')}
    workload = profile['workload']
    computed = {'traffic': traffic.evaluate(rows(run / 'k6.ndjson'), workload)}
    computed['delivery'] = delivery.evaluate(computed['traffic'],
        [row for row in observations if row['time'] < timing['idleStartedMs']], profile, exits['k6'])
    computed['resource'] = resources.evaluate(jvm, observations, profile, timing,
        plateau_start=computed['traffic']['plateauStartMs'], exits=exits)
    start = computed['traffic']['plateauStartMs']
    computed['memory'] = memory.evaluate(jvm, start_ms=start, end_ms=start + workload['plateauSeconds'] * 1000,
        window_ms=workload['windowSeconds'] * 1000, min_span_ms=1200000, reference_ms=600000,
        min_cycles=10, heap_max_bytes=profile['resources']['application']['heapMiB'] * 1024 * 1024,
        exclude_initial_ms=workload['drainSeconds'] * 1000)
    for name, assessment in computed.items():
        if assessment != read(run / (name + '-analysis.json')):
            raise ValueError('Raw reanalysis differs from saved assessment: ' + name)
    statuses = {name: computed[key]['status'] for name, key in
                (('traffic', 'traffic'), ('resources', 'resource'), ('memory', 'memory'))}
    if summary['assessments'] != statuses:
        raise ValueError('Summary assessment statuses differ from raw results')
    sealed = trial(run) if summary['status'] == 'calibration-passed' else None
    times = sorted(row['time'] for row in observations if row.get('application'))
    return {'schema': 1, 'runId': summary['runId'], 'githubRunId': read(run / 'host.json')['githubRunId'],
        'status': summary['status'], 'reasons': summary['reasons'], 'assessments': statuses,
        'rawReanalysisMatches': {name: True for name in computed},
        'rate': workload['rate'], 'offeredJourneys': computed['traffic']['offeredJourneys'],
        'completedJourneys': computed['traffic']['completedJourneys'],
        'rawEarlyLatency': sealed['rawEarlyLatency'] if sealed else raw_early_latency(run, workload, computed['traffic']),
        'maxApplicationGapSeconds': max(((b - a) / 1000 for a, b in zip(times, times[1:])), default=None),
        'idleTransitionMs': timing['idleStartedMs'] - timing['generatorEndedMs'],
        'collectorFlushed': jvm[-1]['kind'] == 'collectorEnd',
        'finalJfrBytes': (run / 'jvm/recording-final.jfr').stat().st_size,
        'sealedTrialVerified': sealed is not None,
        'evidenceSha256': sealed['evidenceSha256'] if sealed else None,
        'inputSha256': hashes, 'reviewerSourceSha256': sha_file(Path(__file__)),
        'reviewerDependencySha256': {'baseline.py': sha_file(HERE / 'baseline.py')},
        'releaseQualified': False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        parser.error('Refusing to overwrite existing review evidence')
    report = review(args.run)
    with args.output.open('x') as stream:
        json.dump(report, stream, indent=2, allow_nan=False)
        stream.write('\n')
    print(json.dumps({key: report[key] for key in ('runId', 'status', 'rawReanalysisMatches', 'sealedTrialVerified')}))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
