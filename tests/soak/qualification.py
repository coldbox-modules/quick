#!/usr/bin/env python3
"""Qualify an immutable prepared package against an explicitly reviewed baseline.

This entry point has no publishing capability. Missing acceptance, mismatched
inputs, incomplete evidence, or any failed assessment cannot produce a receipt.
"""
import argparse
import copy
import json
import os
import datetime
import math
from pathlib import Path
import re
import shutil

from baseline import EVIDENCE
from calibration import validate_trial_profile
from controller import Controller, Inconclusive, execute, write_json
from identity import DOCKER_FIELDS, build_identity, cpu_identity, digest, matching_host, profile_identity, read, require_match, sha_file
from package import verify
from traffic import CASES, operation_names

QUALIFICATION_EVIDENCE = tuple(name for name in EVIDENCE if name != 'capacity-reference.json') + ('accepted-baseline.json', 'baseline-comparison.json')
SHA256 = re.compile(r'[0-9a-f]{64}')


def reviewed_investigations(proposal, review):
    """Keep warning evidence intact while requiring an explicit reviewed disposition.

    This path only resolves latency-noise investigations. It cannot change the
    traffic analyzer's warning/blocking bands or resolve retained-growth risks.
    """
    investigations = proposal['investigations']
    resolutions = review.get('investigationResolutions', {})
    expected_status = 'needs-investigation' if investigations else 'proposed-for-review'
    if (proposal['status'] != expected_status or proposal['accepted'] or proposal['releaseQualified']
            or not isinstance(resolutions, dict) or set(resolutions) != set(investigations)
            or len(set(investigations)) != len(investigations)):
        raise ValueError('Baseline investigations require complete explicit review')
    prefix = 'run-to-run-p95-noise-exceeds-ten-percent:'
    for finding in investigations:
        resolution = resolutions[finding]
        operation = finding.removeprefix(prefix)
        if (not finding.startswith(prefix) or operation not in proposal['latency']
                or not isinstance(resolution, dict)
                or resolution.get('disposition') != 'retain-warning-with-unchanged-gates'
                or not isinstance(resolution.get('rationale'), str) or not resolution['rationale'].strip()
                or not resolution.get('evidenceUrl', '').startswith('https://')
                or not SHA256.fullmatch(resolution.get('evidenceSha256', ''))):
            raise ValueError('Baseline investigations need supported, evidence-backed latency review')


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
    reviewed_investigations(proposal, review)
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
    operations = {*operation_names(proposal['profile']['workload']), *('failure:' + case for case in (*CASES, 'post_delete'))}
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
    required = {'retained-growth', 'wrong-contract', 'held-connection', 'latency', 'late-latency', 'saturation'}
    proofs = accepted['detectors']
    if set(proofs) != required or any(not p.get('url', '').startswith('https://') or not SHA256.fullmatch(p.get('evidenceSha256', '')) for p in proofs.values()):
        raise ValueError('Reviewed detector evidence is incomplete')
    return accepted


def catalog_names(data):
    if data.get('status') != 'accepted-catalog':
        return None
    names = data.get('baselines')
    if (data.get('schema') != 1 or not isinstance(names, list) or not names
            or any(not isinstance(name, str) or not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_-]*\.json', name) for name in names)
            or len(set(names)) != len(names)):
        raise ValueError('Baseline catalog requires unique safe sibling JSON filenames')
    return names


def baseline_paths(path):
    path = Path(path).resolve()
    names = catalog_names(read(path))
    paths = [path] if names is None else [path.parent / name for name in names]
    if any(item.resolve().parent != path.parent or item.resolve() == path for item in paths) and names is not None:
        raise ValueError('Baseline catalog entries must be sibling leaf files')
    for item in paths:
        accepted_baseline(item)
    return paths


def select_baseline(path, host, profile):
    matches = [item for item in baseline_paths(path)
               if matching_host(accepted_baseline(item)['proposal']['measurementIdentity']['values'].get('host', {}), host)]
    if len(matches) != 1:
        raise ValueError('Exactly one reviewed baseline must match the actual runner hardware; found ' + str(len(matches)))
    selected = matches[0]
    reference = accepted_baseline(selected)['proposal']
    # Capacity chooses rate; it cannot silently change the workload or budgets.
    measured = copy.deepcopy(profile)
    measured['workload']['rate'] = reference['profile']['workload']['rate']
    validate_trial_profile(measured)
    if profile_identity(measured) != reference['measurementIdentity']['values']['profile']:
        raise ValueError('Candidate profile differs from the accepted baseline')
    return selected, measured


def resolve_artifact_baseline(path, expected_sha):
    matches = [item for item in baseline_paths(path) if sha_file(item) == expected_sha]
    if len(matches) != 1:
        raise ValueError('Accepted baseline changed after validation or is absent from the catalog')
    return matches[0]


class QualificationController(Controller):
    def setup(self):
        host = {'docker': json.loads(self.docker('info', '--format', '{{json .}}').stdout),
                'cpu': cpu_identity(json.loads(self.command(['lscpu', '--json']).stdout)),
                'runnerImage': os.environ.get('ImageOS'), 'runnerImageVersion': os.environ.get('ImageVersion')}
        host['docker'] = {key: host['docker'][key] for key in DOCKER_FIELDS}
        self.baseline_path, self.profile = select_baseline(self.args.baseline, host, self.profile)
        self.accepted = accepted_baseline(self.baseline_path)
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
        shutil.copyfile(self.baseline_path, self.out / 'accepted-baseline.json')
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
        comparison = require_match(self.reference['measurementIdentity'], identity)
        write_json(self.out / 'baseline-comparison.json', comparison)
        self.latency_baseline = {operation: {'p95Ms': data['p95Ms'], 'absoluteBudgetMs': self.accepted['latencyBudgetsMs'][operation]}
                                 for operation, data in self.reference['latency'].items()}
        self.memory_baseline = self.reference['memory']

    def analyze_resources(self):
        super().analyze_resources()
        if self.summary.get('state') != 'complete':
            return
        identity = build_identity(self.out)
        comparison = require_match(self.reference['measurementIdentity'], identity)
        write_json(self.out / 'baseline-comparison.json', comparison)
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
    baseline = resolve_artifact_baseline(baseline, receipt['baselineSha256'])
    if sha_file(run / 'accepted-baseline.json') != receipt['baselineSha256']:
        raise ValueError('Accepted baseline changed after validation')
    accepted = accepted_baseline(baseline)
    identity = build_identity(run)
    comparison = require_match(accepted['proposal']['measurementIdentity'], identity)
    if read(run / 'baseline-comparison.json') != comparison:
        raise ValueError('Recorded baseline comparison changed')
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
        baseline_paths(args.baseline)
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
