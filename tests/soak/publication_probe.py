#!/usr/bin/env python3
"""Verify native artifact transport and guard serialization without providers."""
import argparse
import datetime
import json
import os
from pathlib import Path
import shutil
import sys
import time

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / 'release'))
from package import digest, verify
from matrix_probe import read, write


def publication_stub(run, output, candidate, hold_seconds=0):
    if not 0 <= hold_seconds <= 180:
        raise ValueError('Diagnostic guard hold must be between 0 and 180 seconds')
    if read(run / 'summary.json').get('status') != 'development-passed':
        raise ValueError('A successful real development workload is required')
    if not read(run.parent / 'cleanup-verification.json').get('passed'):
        raise ValueError('Verified owned cleanup is required')
    for name in ('traffic-analysis.json', 'resource-analysis.json'):
        if read(run / name).get('status') != 'passed':
            raise ValueError('Traffic and resource checks must pass')
    manifest = verify(run / 'package', candidate)
    output.mkdir(parents=True, exist_ok=False)
    started = time.time()
    write(output / 'guard-started.json', {'time': started, 'holdSeconds': hold_seconds})
    # This is a local stand-in for upload/readback. It deliberately never calls
    # promote(): the tested package is diagnostic-only and remains ineligible.
    shutil.copyfile(run / 'package/quick.zip', output / 'stub-upload.zip')
    downloaded = (output / 'stub-upload.zip').read_bytes()
    if digest(downloaded) != manifest['packageSha256']:
        raise ValueError('Stub readback differs from the tested package')
    time.sleep(hold_seconds)
    result = {'stubExecuted': True, 'published': False, 'releaseQualified': False,
              'candidateSha': os.environ['GITHUB_SHA'], 'runId': os.environ['GITHUB_RUN_ID'],
              'packageCandidateSha': candidate, 'packageSha256': manifest['packageSha256'],
              'downloadSha256': digest(downloaded), 'holdSeconds': hold_seconds,
              'guardStartedAt': started, 'guardFinishedAt': time.time()}
    write(output / 'publication-stub.json', result)
    print(json.dumps(result, indent=2))
    return 0


def epoch(value):
    return datetime.datetime.fromisoformat(value.replace('Z', '+00:00')).timestamp()


def serialization(evidence):
    if len(evidence) != 2:
        raise ValueError('Exactly two verified native runs are required')
    records = []
    for directory in evidence:
        verification = read(directory / 'verification.json')
        if verification.get('passed') is not True or verification.get('mode') != 'all-pass':
            raise ValueError('Both native all-pass artifact verifications must pass')
        workflow = read(directory / 'workflow.json')
        jobs = read(directory / 'jobs.json')['jobs']
        guard = next(job for job in jobs if job['name'] == 'Publication stub (no provider calls)')
        validation = [job for job in jobs if job['name'] in ('probe / soak', 'probe / functional-stub')]
        if len(validation) != 2 or any(job['conclusion'] != 'success' for job in validation):
            raise ValueError('Both validation siblings must have completed successfully')
        stubs = list((directory / 'artifacts').rglob('publication-stub.json'))
        if len(stubs) != 1:
            raise ValueError('Expected one native publication stub artifact')
        stub = read(stubs[0])
        records.append({'runId': workflow['id'], 'workflowSha': workflow['head_sha'],
            'workflowStarted': epoch(workflow['run_started_at']), 'workflowFinished': epoch(workflow['updated_at']),
            'validationFinished': max(epoch(job['completed_at']) for job in validation),
            'guardStarted': epoch(guard['started_at']), 'guardFinished': epoch(guard['completed_at']), 'stub': stub})
    records.sort(key=lambda row: row['guardStarted'])
    first, second = records
    checks = {'distinctRuns': first['runId'] != second['runId'],
              'sameHarnessCommit': first['workflowSha'] == second['workflowSha'],
              'workflowsOverlapped': max(row['workflowStarted'] for row in records) < min(row['workflowFinished'] for row in records),
              'providerGuardJobsDidNotOverlap': first['guardFinished'] <= second['guardStarted'],
              'validationCompletedBeforeEachGuard': all(row['validationFinished'] <= row['guardStarted'] for row in records),
              'secondReadyWhileFirstGuardHeld': second['validationFinished'] < first['guardFinished'],
              'stubBodiesDidNotOverlap': first['stub']['guardFinishedAt'] <= second['stub']['guardStartedAt'],
              'sameTestedPackage': first['stub']['packageSha256'] == second['stub']['packageSha256'],
              'samePackageCandidate': first['stub']['packageCandidateSha'] == second['stub']['packageCandidateSha'],
              'bothGuardsHeldForThreeMinutes': all(row['stub']['holdSeconds'] == 180 and
                  row['stub']['guardFinishedAt'] - row['stub']['guardStartedAt'] >= 180 for row in records),
              'exactReadback': all(row['stub']['packageSha256'] == row['stub']['downloadSha256'] for row in records),
              'noPublication': all(row['stub']['published'] is False and row['stub']['releaseQualified'] is False for row in records)}
    return {'passed': all(checks.values()), 'releaseQualified': False, 'checks': checks, 'runs': records}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=('stub', 'verify-serialization'))
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--run', type=Path)
    parser.add_argument('--candidate')
    parser.add_argument('--hold-seconds', type=int, default=0)
    parser.add_argument('--evidence', type=Path, nargs=2)
    args = parser.parse_args()
    if args.command == 'stub':
        if not args.run or not args.candidate:
            parser.error('Stub requires run and exact package candidate')
        return publication_stub(args.run, args.output, args.candidate, args.hold_seconds)
    if not args.evidence:
        parser.error('Serialization requires two downloaded native proof directories')
    result = serialization(args.evidence)
    args.output.mkdir(parents=True, exist_ok=False)
    write(args.output / 'verification.json', result)
    print(json.dumps(result, indent=2))
    return 0 if result['passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
