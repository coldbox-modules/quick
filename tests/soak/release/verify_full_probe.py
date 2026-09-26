#!/usr/bin/env python3
"""Download and verify a successful full native release-matrix diagnostic run."""
import argparse
import base64
import datetime
import json
from pathlib import Path
import re
import subprocess

from package import digest
from validate_candidate import inspect_artifact

REPOSITORY = 'coldbox-modules/quick'


def read(path):
    return json.loads(path.read_text())


def write(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def api(path):
    return json.loads(subprocess.check_output(['gh', 'api', 'repos/' + REPOSITORY + '/' + path], text=True))


def epoch(value):
    return datetime.datetime.fromisoformat(value.replace('Z', '+00:00')).timestamp()


def one(items, description):
    items = list(items)
    if len(items) != 1:
        raise ValueError('Expected exactly one ' + description)
    return items[0]


def step(job, name):
    result = one((s for s in job['steps'] if s['name'] == name), name + ' step')
    if result['conclusion'] != 'success':
        raise ValueError(name + ' did not succeed')
    return result


def verify(output):
    workflow, jobs = read(output / 'workflow.json'), read(output / 'jobs.json')['jobs']
    template = (output / 'release.yml.pending').read_text()
    rows = re.findall(r'cfengine: "([^"]+)"\s+coldbox: "([^"]+)"\s+fullNull: "([^"]+)"', template)
    expected = {f'Validation / functional / {engine} / {coldbox} / null={null}' for engine, coldbox, null in rows}
    functional = [j for j in jobs if j['name'].startswith('Validation / functional /')]
    soak = one((j for j in jobs if j['name'].startswith('Validation / soak /')), 'soak row')
    publisher = one((j for j in jobs if j['name'] == 'Full receipt publication stub (no provider calls)'), 'publication stub')
    observe = step(soak, 'Observe the complete required soak')
    test_steps = [step(job, 'Run TestBox Tests') for job in functional]
    artifacts = output / 'artifacts'
    run = one(artifacts.glob('release-soak-*/supervision/run'), 'full qualified run')
    stub_path = one(artifacts.rglob('qualified-publication-stub.json'), 'full publication proof')
    baseline = output / 'candidate-baseline.json'
    eligibility = inspect_artifact(run, workflow['head_sha'], baseline)
    stub = read(stub_path)
    validations = [*functional, soak]
    checks = {
        'expectedWorkflow': workflow['path'] == '.github/workflows/soak-release-proof.yml',
        'terminalSuccess': workflow['status'] == 'completed' and workflow['conclusion'] == 'success',
        'exactFunctionalMatrix': len(functional) == len(expected) == 23 and {j['name'] for j in functional} == expected,
        'exactJobCount': len(jobs) == 25,
        'everyValidationPassed': all(j['conclusion'] == 'success' for j in validations),
        'actualTestBoxOverlappedFullSoak': any(max(epoch(s['started_at']), epoch(observe['started_at'])) <
            min(epoch(s['completed_at']), epoch(observe['completed_at'])) for s in test_steps),
        'publisherPassed': publisher['conclusion'] == 'success',
        'publisherWaitedForEntireMatrix': max(epoch(j['completed_at']) for j in validations) <= epoch(publisher['started_at']),
        'fullReceiptVerified': stub.get('fullReceiptVerified') is True,
        'candidateAndPackageMatch': all(stub.get(key) == value for key, value in eligibility.items()),
        'sameWorkflowRun': str(stub.get('workflowRunId')) == str(workflow['id']),
        'noRealPublication': stub.get('published') is False and stub.get('providerWrites') == 0,
    }
    local = stub_path.parent / 'local-publisher'
    if eligibility['publicationRequired']:
        receipt = read(run / 'qualification.json')
        promotion = stub.get('promotionReceipt') or {}
        checks['qualifiedPromotionExecuted'] = stub.get('stubPublished') is True
        checks['exactUploadedBytes'] = digest((local / 'upload.zip').read_bytes()) == eligibility['packageSha256']
        checks['exactReadbackAndReceipt'] = all(promotion.get(key) == receipt[key]
            for key in ('candidateSha', 'packageSha256', 'baselineSha256', 'evidenceSha256')) and \
            promotion.get('downloadSha256') == receipt['packageSha256']
    else:
        checks['noReleaseSkippedPublisher'] = stub.get('stubPublished') is False and stub.get('promotionReceipt') is None and not local.exists()
    return {'passed': all(checks.values()), 'checks': checks, 'runId': workflow['id'],
            'candidateSha': workflow['head_sha'], 'publicationRequired': eligibility['publicationRequired'],
            'published': False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run-id', required=True, type=int)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    workflow = api(f'actions/runs/{args.run_id}')
    if workflow['status'] != 'completed':
        raise ValueError('The existing workflow is still running; wait for that run')
    args.output.mkdir(parents=True, exist_ok=False)
    write(args.output / 'workflow.json', workflow)
    write(args.output / 'jobs.json', api(f'actions/runs/{args.run_id}/jobs?per_page=100'))
    write(args.output / 'artifacts.json', api(f'actions/runs/{args.run_id}/artifacts?per_page=100'))
    for remote, local in (('tests/soak/release/release.yml.pending', 'release.yml.pending'),
                          ('tests/soak/baselines/lucee6-serial.json', 'candidate-baseline.json')):
        source = api(f'contents/{remote}?ref={workflow["head_sha"]}')
        (args.output / local).write_bytes(base64.b64decode(source['content']))
    subprocess.run(['gh', 'run', 'download', str(args.run_id), '--repo', REPOSITORY,
                    '--dir', str(args.output / 'artifacts')], check=True)
    result = verify(args.output)
    write(args.output / 'verification.json', result)
    print(json.dumps(result, indent=2))
    return 0 if result['passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
