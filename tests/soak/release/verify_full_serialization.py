#!/usr/bin/env python3
"""Verify actual guard contention between two successful full-matrix probes."""
import argparse
import json
from pathlib import Path

from verify_full_probe import epoch, one, read, verify, write


def serialization(directories):
    if len(directories) != 2:
        raise ValueError('Two complete full-matrix evidence directories are required')
    records = []
    for directory in directories:
        # Recheck the downloaded raw receipts and bytes, not just a saved result.
        result = verify(directory)
        if not result['passed'] or not result['publicationRequired']:
            raise ValueError('Both full matrices must pass and exercise qualified local promotion')
        workflow = read(directory / 'workflow.json')
        jobs = read(directory / 'jobs.json')['jobs']
        guard = one((j for j in jobs if j['name'] == 'Full receipt publication stub (no provider calls)'), 'guard job')
        validations = [j for j in jobs if j['name'].startswith('Validation /')]
        stub = read(one((directory / 'artifacts').rglob('qualified-publication-stub.json'), 'publication proof'))
        prepared = read(one((directory / 'artifacts').glob('release-soak-*/supervision/run/package/prepared.json'), 'prepared package'))
        records.append({'runId': workflow['id'], 'candidateSha': workflow['head_sha'],
            'workflowStarted': epoch(workflow['run_started_at']), 'workflowFinished': epoch(workflow['updated_at']),
            'validationFinished': max(epoch(j['completed_at']) for j in validations),
            'guardStarted': epoch(guard['started_at']), 'guardFinished': epoch(guard['completed_at']),
            'preparedLastRelease': prepared['lastRelease'], 'version': prepared['version'], 'stub': stub})
    records.sort(key=lambda row: row['guardStarted'])
    first, second = records
    checks = {
        'distinctRuns': first['runId'] != second['runId'],
        'sameCandidate': first['candidateSha'] == second['candidateSha'],
        'samePreparedReleaseState': first['preparedLastRelease'] == second['preparedLastRelease'] and first['version'] == second['version'],
        'workflowsOverlapped': max(row['workflowStarted'] for row in records) < min(row['workflowFinished'] for row in records),
        'actualGuardContention': second['validationFinished'] < first['guardFinished'],
        'guardJobsDidNotOverlap': first['guardFinished'] <= second['guardStarted'],
        'promotionBodiesDidNotOverlap': first['stub']['guardFinishedAt'] <= second['stub']['guardStartedAt'],
        'bothHeldForThreeMinutes': all(row['stub']['holdSeconds'] == 180 and
            row['stub']['guardFinishedAt'] - row['stub']['guardStartedAt'] >= 180 for row in records),
        'eachPublisherWaitedForEntireMatrix': all(row['validationFinished'] <= row['guardStarted'] for row in records),
    }
    # Independent preparations include their own timestamped release notes and
    # can produce different ZIPs. Each exact ZIP/readback was checked above;
    # package equality across workflows is not the serialization requirement.
    return {'passed': all(checks.values()), 'published': False, 'checks': checks, 'runs': records,
            'scope': 'Native full-matrix guard serialization; provider-state invalidation is covered by adapter tests.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--evidence', required=True, nargs=2, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    result = serialization(args.evidence)
    args.output.mkdir(parents=True, exist_ok=False)
    write(args.output / 'verification.json', result)
    print(json.dumps(result, indent=2))
    return 0 if result['passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
