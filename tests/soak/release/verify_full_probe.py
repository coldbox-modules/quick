#!/usr/bin/env python3
"""Download and verify a successful full native release-matrix diagnostic run."""
import argparse
import base64
import datetime
import json
from pathlib import Path
import re
import subprocess
import shutil

from package import digest
from validate_candidate import inspect_artifact
from qualification import catalog_names

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


def objects(value):
    if isinstance(value, dict):
        yield value
        for nested in value.values():
            yield from objects(nested)
    elif isinstance(value, list):
        for nested in value:
            yield from objects(nested)


def expected_rows(output):
    template = (output / 'release.yml.pending').read_text()
    rows = re.findall(r'cfengine: "([^"]+)"\s+coldbox: "([^"]+)"\s+fullNull: "([^"]+)"', template)
    return {f'Validation / functional / {engine} / {coldbox} / null={null}' for engine, coldbox, null in rows}


def verify_failure(output, mode):
    workflow, jobs = read(output / 'workflow.json'), read(output / 'jobs.json')['jobs']
    artifacts = output / 'artifacts'
    soak = one((j for j in jobs if j['name'].startswith('Validation / soak /')), 'soak row')
    run = one(artifacts.glob('release-soak-*/supervision/run'), 'interrupted full soak')
    summary, cleanup = read(run / 'summary.json'), read(run.parent / 'cleanup-verification.json')
    functional = [j for j in jobs if j['name'].startswith('Validation / functional /')]
    expected = expected_rows(output)
    checks = {
        'expectedWorkflow': workflow['path'] == '.github/workflows/soak-release-proof.yml',
        'terminalExpectedOutcome': workflow['status'] == 'completed' and workflow['conclusion'] == ('cancelled' if mode == 'explicit-cancel' else 'failure'),
        'entireFunctionalMatrixPresent': len(functional) == len(expected) == 23 and {j['name'] for j in functional} == expected,
        'liveFullSoakStarted': read(run.parent / 'live.json').get('live') is True,
        'noQualificationReceipt': not (run / 'qualification.json').exists() and not (run / 'validation.json').exists(),
        'neverQualified': summary.get('releaseQualified') is False,
        'publicationBlocked': all(j['conclusion'] in ('skipped', 'cancelled') for j in jobs
            if j['name'] == 'Full receipt publication stub (no provider calls)'),
        'noPublicationArtifact': not list(artifacts.rglob('qualified-publication-stub.json')),
        'ownedResourcesRemoved': all(cleanup.get('checks', {}).get(key) is True for key in
            ('containersRemoved', 'volumesRemoved', 'networksRemoved', 'anonymousDatabaseVolumeRemoved')),
        'httpAndJvmEvidenceRetained': (run / 'k6.ndjson').stat().st_size > 0 and (run / 'jvm/jvm.ndjson').stat().st_size > 0,
    }
    if mode == 'soak-failure':
        injection = read(run.parent.parent / 'probe/soak-injected.json')
        sibling = one((j for j in jobs if j['id'] == injection['functionalJobId']), 'observed functional sibling')
        test = one((s for s in sibling['steps'] if s['name'] == 'Run TestBox Tests'), 'observed TestBox step')
        checks.update(
            actualOwnedApplicationKilled=injection.get('injected') is True and injection['runId'] == summary['runId'] and read(run / 'app-exit.json')['ExitCode'] == 137,
            actualTestBoxWasRunning=epoch(test['started_at']) <= injection['time'] <= epoch(test['completed_at']),
            soakDetectedFailure=summary['status'] == 'failed' and soak['conclusion'] == 'failure',
            unfinishedFunctionalCanceled=sibling['conclusion'] == 'cancelled',
            partialRecordingRetained=(run / 'jvm/recording.jfr').stat().st_size > 0)
    else:
        checks['cleanControllerCancellation'] = summary['status'] == 'inconclusive' and summary['state'] == 'canceled' and cleanup['passed']
        checks['finalRecordingRetained'] = (run / 'jvm/recording-final.jfr').stat().st_size > 0
        checks['soakJobCanceled'] = soak['conclusion'] == 'cancelled'
        if mode == 'functional-failure':
            record_path = one(artifacts.glob('full-functional-*/functional-injection.json'), 'functional injection')
            injection = read(record_path)
            report = read(record_path.parent / 'testbox.json')
            row = read(record_path.parent / 'row.json')
            failing = one((j for j in jobs if j['name'] == row['name']), 'deliberately failing functional row')
            intended = [item for item in objects(report) if item.get('name') ==
                'fails deliberately after the sibling soak has real HTTP and JVM evidence' and item.get('status', '').lower() == 'failed'
                and 'Intentional full-matrix functional failure' in item.get('failMessage', '')]
            checks.update(
                actualAssertionFailed=len(intended) == 1 and report.get('totalFail') == 1 and report.get('totalError') == 0,
                intendedFunctionalRowFailed=failing['conclusion'] == 'failure' and any(
                    s['name'] == 'Run TestBox Tests' and s['conclusion'] == 'failure' for s in failing['steps']),
                injectedAfterLiveSoak=injection['soakJobId'] == soak['id'] and
                    read(run.parent / 'live.json')['time'] <= injection['time'] <= epoch(soak['completed_at']),
                noUnrelatedFunctionalFailure=all(j['conclusion'] in ('success', 'cancelled', 'skipped') for j in jobs
                    if j['name'].startswith('Validation / functional /') and j['id'] != failing['id']))
        elif mode == 'explicit-cancel':
            cancel = read(output / 'cancellation-request.json')
            from full_faults import live_soak, live_testbox
            checks['explicitCancelAfterBothLive'] = cancel.get('cancelRequested') is True and cancel['runId'] == workflow['id'] and \
                cancel['candidateSha'] == workflow['head_sha'] and any(live_soak(j) for j in cancel['jobs']) and any(live_testbox(j) for j in cancel['jobs'])
        else:
            raise ValueError('Unknown full-matrix failure mode')
    return {'passed': all(checks.values()), 'mode': mode, 'checks': checks, 'runId': workflow['id'],
            'candidateSha': workflow['head_sha'], 'published': False}


def verify(output):
    workflow, jobs = read(output / 'workflow.json'), read(output / 'jobs.json')['jobs']
    expected = expected_rows(output)
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
    reports = [(read(path), read(path.parent / 'testbox.json')) for path in artifacts.glob('full-functional-*/row.json')]
    checks = {
        'expectedWorkflow': workflow['path'] == '.github/workflows/soak-release-proof.yml',
        'terminalSuccess': workflow['status'] == 'completed' and workflow['conclusion'] == 'success',
        'exactFunctionalMatrix': len(functional) == len(expected) == 23 and {j['name'] for j in functional} == expected,
        'exactJobCount': len(jobs) == 25,
        'everyValidationPassed': all(j['conclusion'] == 'success' for j in validations),
        'everyActualTestBoxReportPassed': len(reports) == 23 and {row['name'] for row, _ in reports} == expected and all(
            str(row.get('workflowRunId')) == str(workflow['id']) and report.get('totalFail') == 0
            and report.get('totalError') == 0 and report.get('totalPass', 0) > 0 for row, report in reports),
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
    parser.add_argument('--mode', choices=('all-pass', 'functional-failure', 'soak-failure', 'explicit-cancel'), default='all-pass')
    parser.add_argument('--cancellation-evidence', type=Path)
    args = parser.parse_args()
    workflow = api(f'actions/runs/{args.run_id}')
    if workflow['status'] != 'completed':
        raise ValueError('The existing workflow is still running; wait for that run')
    args.output.mkdir(parents=True, exist_ok=False)
    if args.mode == 'explicit-cancel':
        if not args.cancellation_evidence:
            parser.error('Explicit cancellation requires the saved cancellation request')
        shutil.copyfile(args.cancellation_evidence, args.output / 'cancellation-request.json')
    write(args.output / 'workflow.json', workflow)
    write(args.output / 'jobs.json', api(f'actions/runs/{args.run_id}/jobs?per_page=100'))
    write(args.output / 'artifacts.json', api(f'actions/runs/{args.run_id}/artifacts?per_page=100'))
    for remote, local in (('tests/soak/release/release.yml.pending', 'release.yml.pending'),
                          ('tests/soak/baselines/lucee6-serial.json', 'candidate-baseline.json')):
        source = api(f'contents/{remote}?ref={workflow["head_sha"]}')
        (args.output / local).write_bytes(base64.b64decode(source['content']))
    names = catalog_names(read(args.output / 'candidate-baseline.json'))
    for name in names or []:
        if name == 'candidate-baseline.json':
            raise ValueError('Baseline leaf conflicts with the downloaded catalog filename')
        source = api(f'contents/tests/soak/baselines/{name}?ref={workflow["head_sha"]}')
        (args.output / name).write_bytes(base64.b64decode(source['content']))
    subprocess.run(['gh', 'run', 'download', str(args.run_id), '--repo', REPOSITORY,
                    '--dir', str(args.output / 'artifacts')], check=True)
    result = verify(args.output) if args.mode == 'all-pass' else verify_failure(args.output, args.mode)
    write(args.output / 'verification.json', result)
    print(json.dumps(result, indent=2))
    return 0 if result['passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
