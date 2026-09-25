#!/usr/bin/env python3
"""Exercise controlled faults through fresh application, database and k6 processes."""
import argparse
import json
from pathlib import Path
import signal
import subprocess
import sys

HERE = Path(__file__).resolve().parent
CASES = ('none', 'held-connection', 'wrong-contract', 'latency', 'late-latency')


def read(path):
    return json.loads(path.read_text()) if path.exists() else {}


def verify(run, case, code):
    summary = read(run / 'summary.json')
    traffic = read(run / 'traffic-analysis.json')
    resources = read(run / 'resource-analysis.json')
    expected = {'none': 'development-passed', 'held-connection': 'failed',
                'wrong-contract': 'failed', 'latency': 'failed', 'late-latency': 'inconclusive'}[case]
    checks = {'expectedStatus': summary.get('status') == expected,
              'expectedExit': code == (0 if case == 'none' else 1),
              'neverReleaseQualified': summary.get('releaseQualified') is False,
              'noCleanupOrReportErrors': not any('incomplete:' in reason for reason in summary.get('reasons', [])),
              'faultProfileRecorded': read(run / 'profile.json').get('fault') == case}
    if case == 'none':
        checks['healthyTrafficAndResources'] = traffic.get('status') == resources.get('status') == 'passed'
    else:
        checks['faultStarted'] = read(run / 'fault.json') == {'mode': case, 'started': True}
    if case == 'held-connection':
        checks['trafficStillCorrect'] = traffic.get('status') == 'passed'
        checks['borrowedConnectionObservedAtEnd'] = read(run / 'final-diagnostics.json').get('jdbcActive', 0) >= 1
        checks['idleConnectionDetected'] = 'idle-resource-not-released:jdbcActive' in resources.get('failures', [])
    elif case == 'wrong-contract':
        metrics = read(run / 'k6-summary.json').get('metrics', {})
        checks['httpStatusMetricGreen'] = metrics.get('http_req_failed', {}).get('values', {}).get('rate') == 0
        checks['bodyAssertionFailed'] = metrics.get('checks', {}).get('values', {}).get('fails', 0) > 0
        checks['exactContractReason'] = 'incorrect-response-contract' in traffic.get('failures', [])
    elif case in ('latency', 'late-latency'):
        category = 'failures' if case == 'latency' else 'invalid'
        prefix = 'sustained-latency-regression:' if case == 'latency' else 'late-latency-regression-needs-observation:'
        checks['exactLatencyReason'] = prefix + 'report_100' in traffic.get(category, [])
        checks['noWrongResponses'] = not {'incorrect-response-contract', 'unexpected-http-failure', 'unexpected-errors'}.intersection(traffic.get('failures', []))
        checks['allOfferedWorkCompleted'] = traffic.get('offeredJourneys') == traffic.get('completedJourneys') and traffic.get('completedJourneys', 0) >= 900
        checks['resourcesHealthy'] = resources.get('status') == 'passed'
    run_id = summary.get('runId', 'missing')
    for noun, command in (('Containers', ['docker', 'ps', '-aq']), ('Volumes', ['docker', 'volume', 'ls', '-q']),
                          ('Networks', ['docker', 'network', 'ls', '-q'])):
        checks['owned' + noun + 'Removed'] = not subprocess.check_output(command + ['--filter', 'label=org.quick.soak=' + run_id], text=True).strip()
    volumes = read(run / 'mysql-volumes.json')
    checks['anonymousDatabaseVolumeRemoved'] = bool(volumes) and all(subprocess.run(
        ['docker', 'volume', 'inspect', volume['name']], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0 for volume in volumes)
    jvm_file = run / 'jvm/jvm.ndjson'
    jvm = [json.loads(line) for line in jvm_file.read_text().splitlines()] if jvm_file.exists() else []
    checks['collectorFlushed'] = bool(jvm) and jvm[-1].get('kind') == 'collectorEnd'
    recording = run / 'jvm/recording-final.jfr'
    checks['recordingRetained'] = recording.exists() and recording.stat().st_size > 0
    return {'case': case, 'passed': all(checks.values()), 'checks': checks, 'runId': run_id,
            'status': summary.get('status'), 'expectedStatus': expected}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--cases', nargs='+', choices=CASES, default=list(CASES))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    reports, identity = [], None
    for case in args.cases:
        run = args.output.resolve() / case
        print('Starting fault verification: ' + case, flush=True)
        with (args.output / (case + '.log')).open('w') as log:
            process = subprocess.Popen([sys.executable, str(HERE / 'controller.py'), '--development', '--fault', case,
                                        '--output', str(run)], stdout=log, stderr=subprocess.STDOUT)
            try:
                code = process.wait(timeout=1200)
            finally:
                if process.poll() is None:
                    process.send_signal(signal.SIGTERM)
                    process.wait(timeout=120)
        report = verify(run, case, code)
        manifest = read(run / 'harness-manifest.json')
        if identity is None:
            identity = manifest
        report['checks']['sameHarnessAcrossCases'] = bool(manifest) and manifest == identity
        report['passed'] = all(report['checks'].values())
        reports.append(report)
        result = {'passed': all(row['passed'] for row in reports), 'completeFaultSuite': set(args.cases) == set(CASES) and len(reports) == len(CASES),
                  'releaseQualified': False, 'cases': reports}
        (args.output / 'verification.json').write_text(json.dumps(result, indent=2) + '\n')
        print(json.dumps(report, indent=2), flush=True)
    return 0 if result['passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
