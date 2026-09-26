#!/usr/bin/env python3
"""Qualify an immutable prepared package against an explicitly reviewed baseline.

This entry point has no publishing capability. Missing acceptance, mismatched
inputs, incomplete evidence, or any failed assessment cannot produce a receipt.
"""
import argparse
import datetime
import math
from pathlib import Path
import re
import shutil

from baseline import EVIDENCE
from calibration import validate_trial_profile
from controller import Controller, Inconclusive, execute, write_json
from identity import build_identity, digest, profile_identity, read, require_match, sha_file
from package import verify
from traffic import CASES, OPERATIONS

QUALIFICATION_EVIDENCE = tuple(name for name in EVIDENCE if name != 'capacity-reference.json') + ('accepted-baseline.json',)
SHA256 = re.compile(r'[0-9a-f]{64}')


def accepted_baseline(path):
    accepted = read(path)
    if accepted.get('schema') != 1 or accepted.get('status') != 'accepted':
        raise ValueError('An explicitly accepted baseline is required')
    review = accepted['review']
    if not review.get('reviewer', '').strip() or not all(review.get(key, '').startswith('https://') for key in ('url', 'evidenceArchive')):
        raise ValueError('Baseline review and durable evidence references are required')
    reviewed = datetime.datetime.fromisoformat(review['reviewedAt'].replace('Z', '+00:00'))
    if reviewed.tzinfo is None or reviewed > datetime.datetime.now(datetime.timezone.utc):
        raise ValueError('Baseline review timestamp is invalid')
    proposal = accepted['proposal']
    if digest(proposal) != accepted['proposalSha256']:
        raise ValueError('Reviewed baseline proposal changed')
    if proposal['status'] != 'proposed-for-review' or proposal['investigations'] or proposal['accepted'] or proposal['releaseQualified']:
        raise ValueError('Baseline investigations must be resolved before acceptance')
    trials = proposal['trials']
    if len(trials) != 3 or any(len({item[key] for item in trials}) != 3 for key in ('runId', 'bootId', 'jvmStart')):
        raise ValueError('Three distinct complete baseline trials are required')
    if any(not SHA256.fullmatch(item['evidenceSha256']) or not item['githubRunId'] for item in trials):
        raise ValueError('Baseline trial evidence references are incomplete')
    identity = proposal['measurementIdentity']
    require_match(identity, identity)
    validate_trial_profile(proposal['profile'])
    if profile_identity(proposal['profile']) != identity['values']['profile']:
        raise ValueError('Reviewed profile differs from measured inputs')
    limits = accepted['latencyBudgetsMs']
    operations = {*OPERATIONS, *('failure:' + case for case in (*CASES, 'post_delete'))}
    if set(limits) != operations or set(proposal['latency']) != operations:
        raise ValueError('Every operation requires a reviewed absolute latency budget')
    for operation, value in limits.items():
        if (not isinstance(value, (int, float)) or isinstance(value, bool) or not math.isfinite(value)
                or not proposal['latency'][operation]['maxObservedWindowP95Ms'] <= value <= proposal['profile']['workload']['requestTimeoutSeconds'] * 1000):
            raise ValueError('Invalid reviewed latency budget: ' + operation)
    memory = proposal['memory']
    maximum = proposal['profile']['resources']['application']['heapMiB'] * 1024 * 1024
    if any(not isinstance(memory[key], (int, float)) or not math.isfinite(memory[key]) or not 0 <= memory[key] <= maximum
           for key in ('baselineBytes', 'noiseBytes')):
        raise ValueError('Invalid calibrated memory reference')
    required = {'retained-growth', 'wrong-contract', 'held-connection', 'latency', 'saturation'}
    proofs = accepted['detectors']
    if set(proofs) != required or any(not p.get('url', '').startswith('https://') or not SHA256.fullmatch(p.get('evidenceSha256', '')) for p in proofs.values()):
        raise ValueError('Reviewed detector evidence is incomplete')
    return accepted


class QualificationController(Controller):
    def setup(self):
        self.accepted = accepted_baseline(self.args.baseline)
        self.reference = self.accepted['proposal']
        validate_trial_profile(self.profile)
        if profile_identity(self.profile) != self.reference['measurementIdentity']['values']['profile']:
            raise Inconclusive('Candidate profile differs from the accepted baseline')
        package = verify(self.args.package, self.args.candidate)
        self.validation_only = getattr(self.args, 'validation_only', False)
        prepared = read(self.args.package / 'prepared.json')
        validate_package_purpose(package, prepared, self.validation_only)
        if package['lastRelease'].get('diagnosticOnly'):
            raise Inconclusive('Diagnostic packages cannot qualify for publication')
        super().setup()
        shutil.copyfile(self.args.baseline, self.out / 'accepted-baseline.json')
        # A bounded version command resolves and inspects the real generator
        # before workload starts; final generator identity is checked again.
        r = self.profile['resources']['generator']
        probe = self.start_container('generator-preflight', ['--network', self.prefix, '--cpus', str(r['cpus']),
            '--memory', f'{r["memoryMiB"]}m', '--user', '0'], self.profile['images']['k6'], ['version'])
        actual = self.inspect(probe)
        generator = {'image': actual['Image'], 'limits': {key: actual['HostConfig'][key]
                     for key in ('Memory', 'MemorySwap', 'NanoCpus')}}
        identity = build_identity(self.out, generator=generator)
        write_json(self.out / 'measurement-identity.json', identity)
        require_match(self.reference['measurementIdentity'], identity)
        self.latency_baseline = {operation: {'p95Ms': data['p95Ms'], 'absoluteBudgetMs': self.accepted['latencyBudgetsMs'][operation]}
                                 for operation, data in self.reference['latency'].items()}
        self.memory_baseline = self.reference['memory']

    def analyze_resources(self):
        super().analyze_resources()
        if self.summary.get('state') != 'complete':
            return
        identity = build_identity(self.out)
        require_match(self.reference['measurementIdentity'], identity)
        write_json(self.out / 'measurement-identity.json', identity)
        if (self.summary['status'] == 'inconclusive'
                and self.summary.get('assessments') == {'traffic': 'passed', 'resources': 'passed', 'memory': 'passed'}
                and self.summary['reasons'] == ['accepted-baseline-and-profile-qualification-required']):
            self.summary.update(status='validation-passed' if self.validation_only else 'passed',
                                reasons=[], releaseQualified=not self.validation_only)
        write_json(self.out / 'summary.json', self.summary)


def validate_package_purpose(package, prepared, validation_only):
    if validation_only:
        if package.get('validationOnly') is not True or prepared.get('noRelease') is not True:
            raise ValueError('Validation-only mode requires a no-release validation package')
    elif package.get('validationOnly') or prepared.get('noRelease'):
        raise ValueError('No-release validation packages cannot qualify publication')


def seal_qualification(run):
    return seal_completed_run(run, validation_only=False)


def seal_validation(run):
    return seal_completed_run(run, validation_only=True)


def seal_completed_run(run, *, validation_only):
    summary = read(run / 'summary.json')
    status = 'validation-passed' if validation_only else 'passed'
    if summary.get('status') != status or summary.get('releaseQualified') is not (not validation_only) or summary.get('reasons'):
        raise ValueError('Only a complete qualified run can produce this receipt')
    package = read(run / 'package/package-manifest.json')
    files = {name: sha_file(run / name) for name in QUALIFICATION_EVIDENCE}
    receipt = {'schema': 1, 'purpose': 'validation-only' if validation_only else 'publication',
               'candidateSha': package['candidateSha'], 'packageSha256': package['packageSha256'],
               'baselineSha256': files['accepted-baseline.json'], 'files': files, 'evidenceSha256': digest(files)}
    write_json(run / ('validation.json' if validation_only else 'qualification.json'), receipt)
    return receipt


def verify_qualification(run, candidate, baseline):
    return verify_completed_run(run, candidate, baseline, validation_only=False)


def verify_validation(run, candidate, baseline):
    return verify_completed_run(run, candidate, baseline, validation_only=True)


def verify_completed_run(run, candidate, baseline, *, validation_only):
    receipt = read(run / ('validation.json' if validation_only else 'qualification.json'))
    if receipt['schema'] != 1 or receipt['candidateSha'] != candidate:
        raise ValueError('Qualification candidate mismatch')
    if receipt.get('purpose') != ('validation-only' if validation_only else 'publication'):
        raise ValueError('Qualification receipt purpose mismatch')
    if set(receipt['files']) != set(QUALIFICATION_EVIDENCE) or digest(receipt['files']) != receipt['evidenceSha256']:
        raise ValueError('Qualification evidence is incomplete or changed')
    for name, expected in receipt['files'].items():
        if sha_file(run / name) != expected:
            raise ValueError('Qualified evidence changed: ' + name)
    if sha_file(baseline) != receipt['baselineSha256'] or sha_file(run / 'accepted-baseline.json') != receipt['baselineSha256']:
        raise ValueError('Accepted baseline changed after validation')
    accepted = accepted_baseline(baseline)
    identity = build_identity(run)
    require_match(accepted['proposal']['measurementIdentity'], identity)
    summary = read(run / 'summary.json')
    status = 'validation-passed' if validation_only else 'passed'
    if (summary.get('status') != status or summary.get('releaseQualified') is not (not validation_only) or summary.get('reasons')
            or summary.get('assessments') != {'traffic': 'passed', 'resources': 'passed', 'memory': 'passed'}):
        raise ValueError('Qualification assessments did not all pass')
    for name in ('traffic', 'delivery', 'resource', 'memory'):
        if read(run / (name + '-analysis.json'))['status'] != 'passed':
            raise ValueError('Qualification assessment failed: ' + name)
    package = verify(run / 'package', candidate)
    validate_package_purpose(package, read(run / 'package/prepared.json'), validation_only)
    if package['lastRelease'].get('diagnosticOnly') or package['packageSha256'] != receipt['packageSha256']:
        raise ValueError('Qualification package mismatch')
    return receipt


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline', required=True, type=Path)
    parser.add_argument('--profile', required=True, type=Path)
    parser.add_argument('--package', required=True, type=Path)
    parser.add_argument('--candidate', required=True)
    parser.add_argument('--output', type=Path)
    parser.add_argument('--validation-only', action='store_true', help='Full validation for a no-release candidate; never publication qualification')
    args = parser.parse_args()
    args.development, args.fault = False, 'none'
    # Missing acceptance is a preflight rejection, never a report-only fallback.
    try:
        accepted_baseline(args.baseline)
    except (ValueError, KeyError, OSError) as error:
        parser.error(str(error))
    controller = QualificationController(args)
    execute(controller)
    expected_status = 'validation-passed' if args.validation_only else 'passed'
    if controller.summary['status'] == expected_status:
        try:
            if args.validation_only:
                seal_validation(controller.out)
                verify_validation(controller.out, args.candidate, args.baseline)
            else:
                seal_qualification(controller.out)
                verify_qualification(controller.out, args.candidate, args.baseline)
            return 0
        except (ValueError, KeyError, OSError) as error:
            controller.summary.update(status='inconclusive', releaseQualified=False)
            controller.summary['reasons'].append('qualification-receipt-failed: ' + str(error))
            write_json(controller.out / 'summary.json', controller.summary)
    return 1


if __name__ == '__main__':
    raise SystemExit(main())
