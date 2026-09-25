#!/usr/bin/env python3
"""Cancel the real container controller after HTTP work and JVM telemetry begin."""
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
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    run = args.output.resolve() / 'run'
    with (args.output / 'controller.log').open('w') as log:
        process = subprocess.Popen([sys.executable, str(HERE / 'controller.py'), '--development', '--output', str(run)],
                                   stdout=log, stderr=subprocess.STDOUT)
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
                    if samples >= 3 and '"metric":"journey_completed","type":"Point"' in traffic:
                        ready = True
                        break
                time.sleep(1)
            if not ready:
                raise RuntimeError('Controller did not reach live HTTP and telemetry before cancellation deadline')
            process.send_signal(signal.SIGTERM)
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
        'liveWorkBeforeCancellation': ready,
        'nonzeroControllerExit': code != 0,
        'canceledNeverPasses': summary['status'] == 'inconclusive' and summary['state'] == 'canceled' and not summary['releaseQualified'],
        'ownedContainersRemoved': not remaining,
        'ownedVolumeRemoved': not volumes,
        'ownedNetworkRemoved': not networks,
        'anonymousDatabaseVolumeRemoved': database_volume_removed,
        'jvmSamplesRetained': sum(row['kind'] == 'sample' for row in rows) >= 3,
        'collectorFlushed': rows[-1]['kind'] == 'collectorEnd',
        'partialRecordingRetained': (run / 'jvm/recording-final.jfr').stat().st_size > 0,
        'httpEvidenceRetained': (run / 'k6.ndjson').stat().st_size > 0,
    }
    report = {'passed': all(checks.values()), 'checks': checks, 'runId': summary['runId']}
    (args.output / 'cancellation-verification.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))
    return 0 if report['passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
