#!/usr/bin/env python3
"""Reproduce a baseline proposal and replay its unchanged limits on retained trials.

The first three trials must be the proposal's original trials, in order. Extra
trials are independent validation evidence, never replacements for those three.
This writes investigation evidence only; it cannot accept a baseline.
"""
import argparse
import json
from pathlib import Path
import statistics

from baseline import propose, rows, trial
from identity import digest, read, require_match, sha_file
from review_trial import review
from telemetry import memory, traffic


def investigate(proposal_path, runs):
    if len(runs) < 3:
        raise ValueError('At least the three original proposal trials are required')
    proposal = read(proposal_path)
    trials = [trial(run) for run in runs]
    if propose(trials[:3]) != proposal:
        raise ValueError('Original three trials do not reproduce the proposal exactly')
    if len({item['runId'] for item in trials}) != len(trials):
        raise ValueError('Investigation trials must be distinct')
    reference = proposal['measurementIdentity']
    budgets = {op: data['proposedAbsoluteP95Ms'] for op, data in proposal['latency'].items()}
    latency = {op: {'p95Ms': data['p95Ms'], 'absoluteBudgetMs': budgets[op]}
               for op, data in proposal['latency'].items()}
    results = []
    for run, item in zip(runs, trials):
        comparison = require_match(reference, item['identity'])
        if item['package'] != proposal['healthyPackage']:
            raise ValueError('Investigation package differs from the original healthy package')
        raw_review = review(run)
        workload = item['profile']['workload']
        replay = traffic.evaluate(rows(run / 'k6.ndjson'), workload, latency)
        start = replay['plateauStartMs']
        retained = memory.evaluate(list(rows(run / 'jvm/jvm.ndjson')),
            start_ms=start, end_ms=start + workload['plateauSeconds'] * 1000,
            window_ms=workload['windowSeconds'] * 1000, min_span_ms=1200000,
            reference_ms=600000, min_cycles=10,
            heap_max_bytes=item['profile']['resources']['application']['heapMiB'] * 1024 * 1024,
            exclude_initial_ms=workload['drainSeconds'] * 1000,
            noise_bytes=proposal['memory']['noiseBytes'], baseline_bytes=proposal['memory']['baselineBytes'])
        results.append({'runId': item['runId'], 'githubRunId': item['githubRunId'],
            'measurementComparison': comparison, 'rawReview': raw_review,
            'latencyReplay': replay, 'memoryReplay': retained,
            'resources': item['resources']})
    operation_review = {}
    for op in sorted(latency):
        exact = [item['rawEarlyLatency'][op]['exactNearestRankP95Ms'] for item in trials]
        windows = [value for item in trials for value in item['traffic']['latency'][op]['p95Ms']]
        operation_review[op] = {'trialRawEarlyP95Ms': exact,
            'observedRangeMs': max(exact) - min(exact),
            'observedRangeFraction': (max(exact) - min(exact)) / statistics.median(exact),
            'referenceP95Ms': latency[op]['p95Ms'], 'absoluteBudgetMs': budgets[op],
            'maxObservedWindowP95Ms': max(windows)}
    passed = all(item['latencyReplay']['status'] == item['memoryReplay']['status'] == 'passed'
                 for item in results)
    return {'schema': 1, 'purpose': 'Explicit baseline investigation; not acceptance or qualification',
        'status': 'passed' if passed else 'needs-investigation',
        'proposalSha256': digest(proposal), 'proposalFileSha256': sha_file(proposal_path),
        'proposalInvestigations': proposal['investigations'], 'latencyBudgetsMs': budgets,
        'operations': operation_review, 'trials': results,
        'reviewerSources': {name: sha_file(Path(__file__).parent / name)
                           for name in ('review_baseline.py', 'review_trial.py', 'baseline.py')},
        'accepted': False, 'releaseQualified': False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--proposal', required=True, type=Path)
    parser.add_argument('--trials', required=True, nargs='+', type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    if args.output.exists():
        parser.error('Refusing to overwrite existing investigation evidence')
    report = investigate(args.proposal, args.trials)
    with args.output.open('x') as stream:
        json.dump(report, stream, indent=2, allow_nan=False)
        stream.write('\n')
    print(json.dumps({'status': report['status'], 'trials': len(report['trials']),
                      'proposalInvestigations': report['proposalInvestigations']}))
    return 0 if report['status'] == 'passed' else 1


if __name__ == '__main__':
    raise SystemExit(main())
