#!/usr/bin/env python3
"""Recompute an existing candidate receipt's assessments from retained raw data.

This read-only review cannot create or repair a qualification receipt. It checks
the receipt first, then independently reproduces every saved assessment using
the recorded analyzer versions and the receipt's accepted baseline.
"""
import argparse
import json
from pathlib import Path

from baseline import rows
from identity import read, sha_file
from qualification import accepted_baseline, resolve_artifact_baseline, verify_qualification, verify_validation
from telemetry import delivery, memory, resources, traffic

HERE = Path(__file__).resolve().parent


def replay(run, accepted):
    for name in ('traffic.py', 'delivery.py', 'resources.py', 'memory.py'):
        if sha_file(run / 'harness/telemetry' / name) != sha_file(HERE / 'telemetry' / name):
            raise ValueError('Review requires the recorded analyzer version: ' + name)
    profile, timing = read(run / 'profile.json'), read(run / 'timing.json')
    workload, proposal = profile['workload'], accepted['proposal']
    latency = {operation: {'p95Ms': data['p95Ms'],
                          'absoluteBudgetMs': accepted['latencyBudgetsMs'][operation]}
               for operation, data in proposal['latency'].items()}
    jvm = list(rows(run / 'jvm/jvm.ndjson'))
    observations = list(rows(run / 'observations.ndjson'))
    exits = {role: read(run / (role + '-exit.json')) for role in ('app', 'mysql', 'k6', 'collector')}
    computed = {'traffic': traffic.evaluate(rows(run / 'k6.ndjson'), workload, latency)}
    computed['delivery'] = delivery.evaluate(computed['traffic'],
        [row for row in observations if row['time'] < timing['idleStartedMs']], profile, exits['k6'])
    start = computed['traffic']['plateauStartMs']
    computed['resource'] = resources.evaluate(jvm, observations, profile, timing,
        plateau_start=start, exits=exits)
    computed['memory'] = memory.evaluate(jvm,
        start_ms=start, end_ms=start + workload['plateauSeconds'] * 1000,
        window_ms=workload['windowSeconds'] * 1000, min_span_ms=1200000,
        reference_ms=600000, min_cycles=10,
        heap_max_bytes=profile['resources']['application']['heapMiB'] * 1024 * 1024,
        exclude_initial_ms=workload['drainSeconds'] * 1000,
        noise_bytes=proposal['memory']['noiseBytes'], baseline_bytes=proposal['memory']['baselineBytes'])
    for name, assessment in computed.items():
        if assessment != read(run / (name + '-analysis.json')):
            raise ValueError('Raw reanalysis differs from saved assessment: ' + name)
        if assessment['status'] != 'passed':
            raise ValueError('Raw candidate assessment did not pass: ' + name)
    return computed


def review(run, baseline, candidate):
    validation_only = read(run / 'package/prepared.json').get('noRelease') is True
    verifier = verify_validation if validation_only else verify_qualification
    receipt = verifier(run, candidate, baseline)
    if read(run / 'summary.json')['state'] != 'complete':
        raise ValueError('Candidate observation did not complete')
    accepted = accepted_baseline(resolve_artifact_baseline(baseline, receipt['baselineSha256']))
    computed = replay(run, accepted)
    return {'schema': 1, 'purpose': 'Independent raw candidate review; does not issue a receipt',
        'runId': read(run / 'summary.json')['runId'], 'candidateSha': candidate,
        'receiptPurpose': receipt['purpose'], 'packageSha256': receipt['packageSha256'],
        'baselineSha256': receipt['baselineSha256'], 'evidenceSha256': receipt['evidenceSha256'],
        'rawReanalysisMatches': {name: True for name in computed},
        'assessments': computed, 'inputSha256': receipt['files'],
        'reviewerSourceSha256': sha_file(Path(__file__)),
        'reviewerDependencySha256': {name: sha_file(HERE / name)
            for name in ('baseline.py', 'identity.py', 'qualification.py')},
        'passed': True, 'published': False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run', required=True, type=Path)
    parser.add_argument('--baseline', required=True, type=Path)
    parser.add_argument('--candidate', required=True)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    if args.output.exists():
        parser.error('Refusing to overwrite existing candidate review evidence')
    result = review(args.run, args.baseline, args.candidate)
    with args.output.open('x') as stream:
        json.dump(result, stream, indent=2, allow_nan=False)
        stream.write('\n')
    print(json.dumps({key: result[key] for key in ('runId', 'receiptPurpose', 'rawReanalysisMatches', 'passed')}))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
