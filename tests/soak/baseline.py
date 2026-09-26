#!/usr/bin/env python3
"""Seal complete trials and propose baseline measurements for explicit review.

This tool cannot accept a baseline or qualify a release. It preserves measured
noise, proposed latency budgets, and the exact evidence that needs review.
"""
import argparse
import json
import math
from pathlib import Path
import statistics

from identity import build_identity, digest, read, require_match, sha_file

EVIDENCE = ('summary.json', 'profile.json', 'timing.json', 'host.json', 'initial-diagnostics.json',
            'final-diagnostics.json', 'capacity-reference.json', 'measurement-identity.json',
            'traffic-analysis.json', 'delivery-analysis.json', 'resource-analysis.json', 'memory-analysis.json',
            'k6.ndjson', 'k6-summary.json', 'observations.ndjson', 'jvm/jvm.ndjson', 'jvm/recording-final.jfr',
            'dependency-files.json', 'dependency-identity.json', 'dependencies.json', 'harness-manifest.json',
            'fixtures/fixture-manifest.json', 'runtime-containers.json', 'generator.json', 'seed-commandbox-version.log',
            'package/package-manifest.json', 'package/prepared.json', 'package/quick.zip',
            'app-exit.json', 'mysql-exit.json', 'collector-exit.json', 'k6-exit.json')


def seal_trial(run):
    if read(run / 'summary.json')['status'] != 'calibration-passed':
        raise ValueError('Only complete calibration trials can be sealed')
    files = {name: sha_file(run / name) for name in EVIDENCE}
    seal = {'schema': 1, 'files': files, 'sha256': digest(files)}
    (run / 'trial-evidence.json').write_text(json.dumps(seal, indent=2) + '\n')
    return seal


def trial(run):
    seal = read(run / 'trial-evidence.json')
    if seal['sha256'] != digest(seal['files']) or set(seal['files']) != set(EVIDENCE):
        raise ValueError('Trial evidence manifest is incomplete or changed')
    for name in EVIDENCE:
        if sha_file(run / name) != seal['files'][name]:
            raise ValueError('Trial evidence changed: ' + name)
    summary = read(run / 'summary.json')
    if (summary['status'] != 'calibration-passed' or summary['releaseQualified'] is not False or summary['reasons']
            or summary.get('assessments') != {'traffic': 'passed', 'resources': 'passed', 'memory': 'passed'}):
        raise ValueError('A trial did not complete all required assessments')
    identity = build_identity(run)
    require_match(read(run / 'measurement-identity.json'), identity)
    capacity = read(run / 'capacity-reference.json')
    require_match(capacity['identity'], identity)
    if read(run / 'package/package-manifest.json') != capacity['package']:
        raise ValueError('Trial package differs from capacity package')
    from calibration import validate_trial_profile
    validate_trial_profile(read(run / 'profile.json'))
    traffic, memory, resources = (read(run / name) for name in ('traffic-analysis.json', 'memory-analysis.json', 'resource-analysis.json'))
    if any(item['status'] != 'passed' for item in (traffic, memory, resources)):
        raise ValueError('A trial assessment was not healthy')
    with (run / 'jvm/jvm.ndjson').open() as stream:
        runtime = json.loads(next(stream))
    return {'runId': summary['runId'], 'bootId': read(run / 'initial-diagnostics.json')['bootId'],
            'jvmStart': runtime['startTime'], 'githubRunId': read(run / 'host.json')['githubRunId'],
            'evidenceSha256': seal['sha256'], 'identity': identity, 'package': capacity['package'],
            'capacityEvidenceSha256': capacity['evidenceSha256'], 'traffic': traffic, 'memory': memory,
            'resources': resources, 'profile': read(run / 'profile.json')}


def propose(trials):
    if len(trials) != 3:
        raise ValueError('Baseline review requires exactly three complete healthy trials')
    first = trials[0]
    for key in ('runId', 'bootId', 'jvmStart'):
        if len({item[key] for item in trials}) != 3:
            raise ValueError('Trials must have distinct run, application, and JVM identities: ' + key)
    for item in trials[1:]:
        require_match(first['identity'], item['identity'])
        if item['package'] != first['package'] or item['capacityEvidenceSha256'] != first['capacityEvidenceSha256']:
            raise ValueError('Trials do not share the same healthy package and capacity evidence')
    latency, investigations = {}, []
    operations = set(first['traffic']['latency'])
    if any(set(item['traffic']['latency']) != operations for item in trials):
        raise ValueError('Trial latency operation coverage changed')
    for operation in sorted(operations):
        measurements = [item['traffic']['latency'][operation] for item in trials]
        # Each value represents the same first stable ten-minute reference.
        p95 = [m['earlyP95Ms'] for m in measurements]
        if any(not isinstance(value, (int, float)) or not math.isfinite(value) or value <= 0 for value in p95):
            raise ValueError('Unusable trial latency reference: ' + operation)
        center = statistics.median(p95)
        noise = (max(p95) - min(p95)) / center
        windows = [value for measurement in measurements for value in measurement['p95Ms']]
        if len(windows) != 24 or any(value is None or not math.isfinite(value) for value in windows):
            raise ValueError('Missing full trial latency windows: ' + operation)
        if noise > .1:
            investigations.append('run-to-run-p95-noise-exceeds-ten-percent:' + operation)
        latency[operation] = {'p95Ms': center, 'trialEarlyP95Ms': p95, 'rangeFraction': noise,
                              'maxObservedWindowP95Ms': max(windows),
                              'proposedAbsoluteP95Ms': math.ceil(max(windows) + max(50, .2 * max(windows)))}
    memory = [item['memory'] for item in trials]
    early = [item['earlyMedianBytes'] for item in memory]
    noise = max(max(early) - min(early), *(max(w['medianBytes'] for w in item['windows']) -
                                        min(w['medianBytes'] for w in item['windows']) for item in memory))
    warnings = sorted(set(warning for item in memory for warning in item.get('warnings', [])))
    if any(warning in warnings for warning in ('persistent-positive-retained-trend', 'retained-growth-warning')):
        investigations.append('healthy-retained-growth-requires-investigation')
    heap = first['profile']['resources']['application']['heapMiB'] * 1024 * 1024
    if noise > max(64 * 1024 * 1024, .05 * heap):
        investigations.append('healthy-memory-noise-exceeds-provisional-blocking-band')
    return {'schema': 1, 'status': 'needs-investigation' if investigations else 'proposed-for-review',
            'accepted': False, 'releaseQualified': False, 'investigations': investigations,
            'measurementIdentity': first['identity'], 'healthyPackage': first['package'],
            'profile': first['profile'], 'capacityEvidenceSha256': first['capacityEvidenceSha256'],
            'trials': [{key: item[key] for key in ('runId', 'bootId', 'jvmStart', 'githubRunId', 'evidenceSha256')} for item in trials],
            'latency': latency,
            'memory': {'baselineBytes': statistics.median(early), 'noiseBytes': noise,
                       'trialGrowthBytes': [item['growthBytes'] for item in memory], 'warnings': warnings},
            'resourceRecovery': [item['resources']['recovery'] for item in trials],
            'reviewRequired': ['Resolve every noise or retained-growth investigation.',
                'Review each proposed absolute latency budget against the operation requirements.',
                'Review declared resource bounds and measured recovery before accepting them.',
                'Retain raw evidence durably and record explicit baseline acceptance in a reviewed update.']}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--trials', nargs=3, required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    proposal = propose([trial(path) for path in args.trials])
    with args.output.open('x') as stream:
        stream.write(json.dumps(proposal, indent=2) + '\n')
    return 0 if proposal['status'] == 'proposed-for-review' else 1


if __name__ == '__main__':
    raise SystemExit(main())
