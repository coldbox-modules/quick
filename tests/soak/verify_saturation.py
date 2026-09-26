#!/usr/bin/env python3
"""Saturate one live container after warmup and verify real delivery attribution.

This diagnostic adds bounded generator CPU work or reduces the application CPU
quota deliberately. It cannot qualify a release and records each injection.
The actual application, database, requests, assertions and generator remain in use.
"""
import argparse
import json
from pathlib import Path
import signal
import subprocess
import sys
import time

from controller import Controller, HERE, execute, write_json, sha_file
from delivery import evaluate
from verify_faults import read, verify as verify_cleanup_evidence

# One CPU stayed healthy; a quarter CPU starved diagnostic HTTP collection.
# Probe overload at half a CPU without changing the normal calibration budget.
QUOTAS = {'generator': 0.25, 'application': 0.5}

GENERATOR_WORK = '''import exec from 'k6/execution';
import {options as normalOptions, setup as normalSetup, mixedJourney as original} from './workload.mjs';
export const options = normalOptions;
export const setup = normalSetup;
export function mixedJourney() {
    if (exec.scenario.name === 'plateau') {
        // Bounded CPU work in four VUs consumes generator capacity without
        // starving the Go HTTP runtime with an unrealistically tiny CPU quota.
        const until = Date.now() + 15000;
        let value = 0;
        while (Date.now() < until) value = Math.sqrt(value + 12345);
        if (!Number.isFinite(value)) throw new Error('Invalid diagnostic work');
    }
    return original();
}
'''


class SaturationController(Controller):
    def setup(self):
        super().setup()
        if self.args.role == 'generator':
            self.profile['workload']['vus'] = 4
            write_json(self.out / 'profile.json', self.profile)
            (self.out / 'k6/saturation.mjs').write_text(GENERATOR_WORK)

    def start_container(self, role, arguments, image, command=()):
        if role == 'k6' and self.args.role == 'generator':
            command = [part.replace('/work/k6/workload.mjs', '/work/k6/saturation.mjs') for part in command]
        return super().start_container(role, arguments, image, command)

    def collect(self):
        # Compilation and the full warmup use the normal budget. Constrain only
        # the plateau; do not confuse slow startup with load-delivery capacity.
        w = self.profile['workload']
        if (self.measured_start and not hasattr(self, 'injection') and
                time.time() >= self.measured_start + w['warmupSeconds'] + w['rampSeconds'] + 5):
            role = self.args.role
            container = self.generator if role == 'generator' else self.app
            original = self.inspect(container)['HostConfig']['NanoCpus']
            if role == 'application':
                self.docker('update', '--cpus', str(QUOTAS[role]), container)
            actual = self.inspect(container)['HostConfig']['NanoCpus']
            self.injection = {'role': role, 'container': container, 'timeMs': int(time.time() * 1000),
                              'originalNanoCpus': original, 'injectedNanoCpus': actual,
                              'mechanism': 'bounded-cpu-work' if role == 'generator' else 'reduced-cpu-quota'}
            if role == 'generator':
                self.injection['workloadSha256'] = sha_file(self.out / 'k6/saturation.mjs')
            write_json(self.out / 'saturation-injection.json', self.injection)
            if actual != round(QUOTAS[role] * 1e9):
                raise RuntimeError('Docker did not apply the requested diagnostic quota')
            self.profile['resources'][role]['cpus'] = actual / 1e9
            self.profile['fault'] = role + '-saturation'
            write_json(self.out / 'profile.json', self.profile)
        return super().collect()

    def cleanup(self):
        # Restore the original quota for evidence collection and owned teardown.
        # Measurement has already ended; this is not recovery evidence.
        try:
            if hasattr(self, 'injection'):
                event = self.injection
                self.docker('update', '--cpus', str(event['originalNanoCpus'] / 1e9), event['container'])
                write_json(self.out / 'saturation-quota-restored.json', {'timeMs': int(time.time() * 1000)})
        finally:
            super().cleanup()


def verify(run, role, code):
    injection = read(run / 'saturation-injection.json')
    summary, traffic = read(run / 'summary.json'), read(run / 'traffic-analysis.json')
    if not traffic:
        raise ValueError('Controller stopped before traffic analysis; inspect summary.json and observations.ndjson')
    expected = 'inconclusive' if role == 'generator' else 'failed'
    reason = 'delivery-generator-capacity-exhausted' if role == 'generator' else 'delivery-application-overloaded'
    rows = [json.loads(line) for line in (run / 'observations.ndjson').read_text().splitlines()]
    # Discard pre-injection observations rather than applying the new quota to
    # measurements made under the original allocation.
    rows = [row for row in rows if row['time'] >= injection['timeMs']]
    assessment = evaluate(traffic, rows, read(run / 'profile.json'), read(run / 'k6-exit.json'))
    write_json(run / 'injected-delivery-analysis.json', assessment)
    cleanup = verify_cleanup_evidence(run, 'none', code)['checks']
    checks = {key: value for key, value in cleanup.items() if key.startswith('owned') or key in (
        'anonymousDatabaseVolumeRemoved', 'collectorFlushed', 'recordingRetained', 'noCleanupOrReportErrors')}
    checks.update(expectedClassification=assessment['status'] == expected,
                  exactAttribution=reason in assessment['reasons'],
                  neverReleaseQualified=summary.get('releaseQualified') is False,
                  diagnosticExit=code == 1,
                  injectionVerified=injection['injectedNanoCpus'] == round(QUOTAS[role] * 1e9),
                  quotaRestored=bool(read(run / 'saturation-quota-restored.json')),
                  realShortfall=traffic.get('completedJourneys', 0) < traffic.get('offeredJourneys', 0)
                      or any(sum(window.get('dropped_iterations', {}).values()) > 0 for window in traffic.get('windows', [])))
    if role == 'generator':
        checks['boundedWorkRecorded'] = (injection.get('mechanism') == 'bounded-cpu-work'
            and injection.get('workloadSha256') == sha_file(run / 'k6/saturation.mjs')
            and read(run / 'profile.json')['workload']['vus'] == 4)
        checks['noIncorrectResponses'] = not any(reason in traffic.get('failures', []) for reason in (
            'incorrect-response-contract', 'unexpected-http-failure', 'unexpected-errors'))
    return {'role': role, 'passed': all(checks.values()), 'checks': checks,
            'status': assessment['status'], 'reasons': assessment['reasons'], 'releaseQualified': False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--candidate', required=True)
    parser.add_argument('--profile', type=Path, default=HERE / 'profiles/lucee6-serial.json')
    parser.add_argument('--role', choices=tuple(QUOTAS), help='Internal single-case worker')
    parser.add_argument('--cases', nargs='+', choices=tuple(QUOTAS), default=list(QUOTAS))
    args = parser.parse_args()
    if args.role:
        args.development, args.fault, args.package = True, 'none', None
        return execute(SaturationController(args))
    args.output.mkdir(parents=True, exist_ok=False)
    reports = []
    for role in args.cases:
        run = args.output.resolve() / role
        with (args.output / (role + '.log')).open('w') as log:
            process = subprocess.Popen([sys.executable, str(Path(__file__).resolve()), '--output', str(run),
                '--candidate', args.candidate, '--profile', str(args.profile), '--role', role], stdout=log, stderr=subprocess.STDOUT)
            try:
                code = process.wait(timeout=1200)
            finally:
                if process.poll() is None:
                    process.send_signal(signal.SIGTERM)
                    process.wait(timeout=120)
        try:
            result = verify(run, role, code)
        except Exception as error:
            result = {'role': role, 'passed': False, 'error': str(error), 'releaseQualified': False}
        reports.append(result)
        write_json(args.output / 'verification.json', {'passed': len(reports) == len(args.cases) and all(r['passed'] for r in reports),
                                                     'completeSaturationSuite': set(args.cases) == set(QUOTAS) and len(reports) == len(QUOTAS),
                                                     'releaseQualified': False, 'cases': reports})
        print(json.dumps(result, indent=2), flush=True)
    return 0 if all(r['passed'] for r in reports) else 1


if __name__ == '__main__':
    raise SystemExit(main())
