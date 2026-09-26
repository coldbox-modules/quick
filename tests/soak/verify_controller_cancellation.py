#!/usr/bin/env python3
"""Verify cancellation or observer loss after real HTTP work and JVM telemetry."""
import argparse
import json
from pathlib import Path
import signal
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--mode', choices=('controller-cancel', 'collector-stop'), default='controller-cancel')
    parser.add_argument('--candidate', help='Exact candidate used by the live probe')
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    run = args.output.resolve() / 'run'
    with (args.output / 'controller.log').open('w') as log:
        command = [sys.executable, str(HERE / 'controller.py'), '--development', '--output', str(run)]
        if args.candidate:
            command.extend(['--candidate', args.candidate])
        process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT)
        ready = False
        try:
            deadline = time.monotonic() + 750
            while time.monotonic() < deadline and process.poll() is None:
                if (run / 'summary.json').exists() and (run / 'jvm/jvm.ndjson').exists() and (run / 'k6.ndjson').exists():
                    contents = (run / 'jvm/jvm.ndjson').read_text()
                    rows = [json.loads(line) for line in contents[:contents.rfind('\n')].splitlines() if line]
                    samples = sum(row['kind'] == 'sample' for row in rows)
                    # A completed journey proves this is not merely setup cancellation.
                    traffic = (run / 'k6.ndjson').read_text()
                    recording = run / 'jvm/recording.jfr'
                    recording_ready = args.mode == 'controller-cancel' or (recording.exists() and recording.stat().st_size > 0)
                    if samples >= 3 and recording_ready and '"metric":"journey_completed","type":"Point"' in traffic:
                        ready = True
                        break
                time.sleep(1)
            if not ready:
                raise RuntimeError('Controller did not reach live HTTP and telemetry before cancellation deadline')
            if args.mode == 'controller-cancel':
                process.send_signal(signal.SIGTERM)
            else:
                run_id = json.loads((run / 'summary.json').read_text())['runId']
                owned = subprocess.check_output(['docker', 'ps', '-q', '--filter', 'label=org.quick.soak=' + run_id], text=True).split()
                containers = json.loads(subprocess.check_output(['docker', 'inspect', *owned], text=True))
                observers = [item for item in containers if item['Name'].endswith('-collector')]
                if len(observers) != 1:
                    raise RuntimeError('Expected exactly one live owned collector')
                subprocess.run(['docker', 'kill', '--signal', 'KILL', observers[0]['Id']], check=True, stdout=subprocess.DEVNULL)
            code = process.wait(timeout=90)
        finally:
            if process.poll() is None:
                process.send_signal(signal.SIGTERM)
                try:
                    process.wait(timeout=90)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
    summary = json.loads((run / 'summary.json').read_text())
    remaining = subprocess.check_output(['docker', 'ps', '-aq', '--filter', 'label=org.quick.soak=' + summary['runId']], text=True).strip()
    volumes = subprocess.check_output(['docker', 'volume', 'ls', '-q', '--filter', 'label=org.quick.soak=' + summary['runId']], text=True).strip()
    networks = subprocess.check_output(['docker', 'network', 'ls', '-q', '--filter', 'label=org.quick.soak=' + summary['runId']], text=True).strip()
    rows = [json.loads(line) for line in (run / 'jvm/jvm.ndjson').read_text().splitlines() if line]
    mysql_volumes = json.loads((run / 'mysql-volumes.json').read_text())
    database_volume_removed = bool(mysql_volumes) and all(subprocess.run(
        ['docker', 'volume', 'inspect', volume['name']], stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL).returncode != 0 for volume in mysql_volumes)
    checks = {
        'liveWorkBeforeInterruption': ready,
        'nonzeroControllerExit': code != 0,
        'interruptedNeverPasses': summary['status'] == 'inconclusive' and summary['state'] == ('canceled' if args.mode == 'controller-cancel' else 'aborted') and not summary['releaseQualified'],
        'ownedContainersRemoved': not remaining,
        'ownedVolumeRemoved': not volumes,
        'ownedNetworkRemoved': not networks,
        'anonymousDatabaseVolumeRemoved': database_volume_removed,
        'jvmSamplesRetained': sum(row['kind'] == 'sample' for row in rows) >= 3,
        'httpEvidenceRetained': (run / 'k6.ndjson').stat().st_size > 0,
    }
    if args.mode == 'controller-cancel':
        recording = run / 'jvm/recording-final.jfr'
        checks['collectorFlushed'] = rows[-1]['kind'] == 'collectorEnd'
    else:
        recording = run / 'jvm/recording.jfr'
        checks['observerLossIdentified'] = any(reason.startswith('Required process ') and '-collector stopped or OOMed' in reason for reason in summary['reasons'])
        checks['incompleteRecordingIdentified'] = any(reason.startswith('Cleanup incomplete: verify flushed recording:') for reason in summary['reasons'])
        checks['collectorKilled'] = json.loads((run / 'collector-exit.json').read_text())['ExitCode'] == 137
    checks['partialRecordingRetained'] = recording.exists() and recording.stat().st_size > 0
    report = {'passed': all(checks.values()), 'mode': args.mode, 'checks': checks, 'runId': summary['runId']}
    filename = 'cancellation-verification.json' if args.mode == 'controller-cancel' else 'collector-failure-verification.json'
    (args.output / filename).write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))
    return 0 if report['passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
