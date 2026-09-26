#!/usr/bin/env python3
"""Diagnostic native matrix cancellation probe; never publishes or qualifies."""
import argparse
import datetime
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
MODES = ('functional-failure', 'soak-failure', 'explicit-cancel', 'all-pass')


def read(path):
    return json.loads(path.read_text()) if path.exists() else {}


def write(path, value):
    temporary = path.with_suffix('.tmp')
    temporary.write_text(json.dumps(value, indent=2) + '\n')
    temporary.replace(path)


def mode():
    requested = os.environ.get('PROBE_MODE', '')
    if requested in MODES:
        return requested
    ref = os.environ.get('GITHUB_REF_NAME', '')
    matches = [value for value in MODES if ref.startswith('soak-matrix-' + value + '-')]
    if len(matches) != 1:
        raise ValueError('Select an explicit diagnostic probe mode')
    return matches[0]


def live(run):
    telemetry, traffic = run / 'jvm/jvm.ndjson', run / 'k6.ndjson'
    if not telemetry.exists() or not traffic.exists():
        return False
    raw = telemetry.read_bytes()
    rows = [json.loads(line) for line in raw[:raw.rfind(b'\n') + 1].splitlines() if line]
    return (sum(row.get('kind') == 'sample' for row in rows) >= 3
            and b'"metric":"journey_completed","type":"Point"' in traffic.read_bytes())


def child(output):
    # This supervisor survives the launch step. The observe/always-cleanup steps
    # signal only its recorded controller PID, whose own handler owns teardown.
    with (output / 'controller.log').open('w') as log:
        process = subprocess.Popen([sys.executable, str(HERE / 'controller.py'), '--development',
            '--candidate', 'af2c93d2604de73d7ccac23b7bf69c4be221dbb0',
            '--fault', 'wrong-contract' if mode() == 'soak-failure' else 'none',
            '--output', str(output / 'run')], stdin=subprocess.DEVNULL, stdout=log, stderr=subprocess.STDOUT)
        write(output / 'process.json', {'pid': process.pid})
        code = process.wait()
        write(output / 'exit.json', {'code': code})
    return code


def stop(output, *, wait=True):
    process = read(output / 'process.json')
    if process and not (output / 'exit.json').exists() and not (output / 'stop-requested.json').exists():
        # Observe and the subsequent always-run cleanup share one termination
        # request. A second signal could interrupt the controller's teardown.
        write(output / 'stop-requested.json', {'pid': process['pid'], 'time': time.time()})
        try:
            os.kill(process['pid'], signal.SIGTERM)
        except ProcessLookupError:
            pass
    if not wait:
        return
    deadline = time.monotonic() + 90
    while process and not (output / 'exit.json').exists() and time.monotonic() < deadline:
        time.sleep(1)
    if process and not (output / 'exit.json').exists():
        raise RuntimeError('Controller did not complete bounded cancellation cleanup')


def launch(output):
    output.mkdir(parents=True, exist_ok=False)
    with (output / 'supervisor.log').open('w') as log:
        process = subprocess.Popen([sys.executable, str(Path(__file__).resolve()), 'child', '--output', str(output)],
            stdin=subprocess.DEVNULL, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
    deadline = time.monotonic() + 750
    while time.monotonic() < deadline:
        if live(output / 'run'):
            write(output / 'live.json', {'mode': mode(), 'live': True, 'time': time.time(), 'supervisorPid': process.pid})
            return 0
        if process.poll() is not None:
            raise RuntimeError('Soak ended before live HTTP and JVM evidence')
        time.sleep(1)
    stop(output)
    raise RuntimeError('Live-soak readiness deadline exceeded')


def observe(output, timeout_seconds=1200):
    if read(output / 'live.json').get('live') is not True:
        raise RuntimeError('Live-work proof is missing')
    def cancel(signum, frame):
        raise KeyboardInterrupt('Native matrix cancellation')
    signal.signal(signal.SIGTERM, cancel)
    canceled = False
    try:
        deadline = time.monotonic() + timeout_seconds
        while time.monotonic() < deadline:
            result = read(output / 'exit.json')
            if result:
                return result['code']
            time.sleep(1)
        raise RuntimeError('Soak observation deadline exceeded')
    except KeyboardInterrupt:
        canceled = True
        write(output / 'native-signal.json', {'received': True, 'time': time.time()})
        return 130
    finally:
        # Repeated runner termination signals must not interrupt our explicit
        # handoff to the independent controller's bounded cleanup.
        signal.signal(signal.SIGTERM, signal.SIG_IGN)
        signal.signal(signal.SIGINT, signal.SIG_IGN)
        # Exit within the runner's 7.5-second SIGINT grace period. The always
        # cleanup step waits for the independently supervised controller.
        stop(output, wait=not canceled)


def functional(output, timeout_seconds=1200):
    output.mkdir(parents=True, exist_ok=False)
    selected = mode()
    write(output / 'started.json', {'mode': selected, 'time': time.time()})
    deadline = time.monotonic() + timeout_seconds
    # Only read Actions metadata. The functional stub never touches the soak
    # runner, database, token, or HTTP server.
    while time.monotonic() < deadline:
        data = json.loads(subprocess.check_output(['gh', 'api',
            f'repos/{os.environ["GITHUB_REPOSITORY"]}/actions/runs/{os.environ["GITHUB_RUN_ID"]}/jobs?per_page=100'], text=True))
        jobs = [job for job in data['jobs'] if job['name'] == 'probe / soak']
        if len(jobs) == 1 and any(step['name'] == 'Observe live soak' and step['status'] == 'in_progress' for step in jobs[0]['steps']):
            write(output / 'sibling-live.json', {'mode': selected, 'soakJobId': jobs[0]['id'], 'time': time.time()})
            if selected == 'functional-failure':
                print('Intentional functional-stub failure after live soak readiness', flush=True)
                return 1
            if selected == 'all-pass':
                time.sleep(30)
                return 0
            break
        time.sleep(2)
    else:
        raise RuntimeError('Soak never reached its live observation step')
    # Keep this sibling unfinished until GitHub cancels it after soak failure or
    # explicit workflow cancellation. Expiry is a failure, not successful proof.
    while time.monotonic() < deadline:
        time.sleep(2)
    raise RuntimeError('Expected native sibling cancellation did not arrive')


def verify_cleanup(output):
    stop(output)
    run = output / 'run'
    summary = read(run / 'summary.json')
    run_id = summary.get('runId')
    checks = {'liveBeforeObservation': read(output / 'live.json').get('live') is True,
              'neverReleaseQualified': summary.get('releaseQualified') is False,
              'controllerExited': bool(read(output / 'exit.json')),
              'noCleanupErrors': not any('Cleanup incomplete:' in reason for reason in summary.get('reasons', []))}
    if not run_id:
        raise RuntimeError('Run identity is missing; cannot verify owned cleanup')
    for noun, command in (('Containers', ['docker', 'ps', '-aq']), ('Volumes', ['docker', 'volume', 'ls', '-q']),
                          ('Networks', ['docker', 'network', 'ls', '-q'])):
        checks['owned' + noun + 'Removed'] = not subprocess.check_output(command + ['--filter', 'label=org.quick.soak=' + run_id], text=True).strip()
    volumes = read(run / 'mysql-volumes.json')
    checks['anonymousDatabaseVolumeRemoved'] = bool(volumes) and all(subprocess.run(
        ['docker', 'volume', 'inspect', volume['name']], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0 for volume in volumes)
    rows = [json.loads(line) for line in (run / 'jvm/jvm.ndjson').read_text().splitlines()]
    checks['collectorFlushed'] = bool(rows) and rows[-1].get('kind') == 'collectorEnd'
    checks['recordingRetained'] = (run / 'jvm/recording-final.jfr').stat().st_size > 0
    if mode() in ('functional-failure', 'explicit-cancel'):
        checks['nativeSignalReceived'] = read(output / 'native-signal.json').get('received') is True
        checks['canceledNeverPasses'] = summary.get('status') == 'inconclusive' and summary.get('state') == 'canceled'
    elif mode() == 'soak-failure':
        checks['wrongContractDetected'] = 'incorrect-response-contract' in read(run / 'traffic-analysis.json').get('failures', [])
        checks['soakFailed'] = summary.get('status') == 'failed'
    else:
        checks['healthyDevelopmentRun'] = summary.get('status') == 'development-passed'
    report = {'passed': all(checks.values()), 'mode': mode(), 'runId': run_id, 'checks': checks}
    write(output / 'cleanup-verification.json', report)
    print(json.dumps(report, indent=2))
    return 0 if report['passed'] else 1


def publication_blocked(job, selected):
    if selected == 'all-pass':
        return job['conclusion'] == 'success'
    if selected == 'explicit-cancel':
        # GitHub marks an unstarted dependent job cancelled on whole-workflow
        # cancellation. Require no executed steps as well as no stub artifact.
        return job['conclusion'] in ('skipped', 'cancelled') and not job['steps']
    return job['conclusion'] == 'skipped' and not job['steps']


def verify_remote(output, run_id):
    selected = mode()
    repository = 'coldbox-modules/quick'
    metadata = json.loads(subprocess.check_output(['gh', 'api', f'repos/{repository}/actions/runs/{run_id}'], text=True))
    if metadata['status'] != 'completed':
        raise ValueError('Wait for terminal workflow state before verification')
    output.mkdir(parents=True, exist_ok=False)
    jobs = json.loads(subprocess.check_output(['gh', 'api', f'repos/{repository}/actions/runs/{run_id}/jobs?per_page=100'], text=True))
    write(output / 'workflow.json', metadata)
    write(output / 'jobs.json', jobs)
    subprocess.run(['gh', 'run', 'download', str(run_id), '--repo', repository, '--dir', str(output / 'artifacts')], check=True)
    by_name = {job['name']: job for job in jobs['jobs']}
    expected = {'functional-failure': ('cancelled', 'failure'), 'soak-failure': ('failure', 'cancelled'),
                'explicit-cancel': ('cancelled', 'cancelled'), 'all-pass': ('success', 'success')}[selected]
    checks = {'workflowConclusion': metadata['conclusion'] == ('success' if selected == 'all-pass' else 'cancelled' if selected == 'explicit-cancel' else 'failure'),
              'soakConclusion': by_name['probe / soak']['conclusion'] == expected[0],
              'functionalConclusion': by_name['probe / functional-stub']['conclusion'] == expected[1],
              'publicationGated': publication_blocked(by_name['Publication stub (no provider calls)'], selected)}
    def artifact(name):
        found = list((output / 'artifacts').rglob(name))
        if len(found) != 1:
            raise ValueError('Expected exactly one artifact file: ' + name)
        return read(found[0])
    cleanup = artifact('cleanup-verification.json')
    live_proof = artifact('live.json')
    functional_start = artifact('started.json')
    checks['ownedCleanupAndEvidence'] = cleanup.get('passed') is True and cleanup.get('mode') == selected
    checks['liveHttpAndJvm'] = live_proof.get('live') is True
    finished = datetime.datetime.fromisoformat(artifact('summary.json')['finishedAt']).timestamp()
    checks['functionalOverlappedLiveSoak'] = functional_start['time'] < finished
    if selected == 'functional-failure':
        sibling = artifact('sibling-live.json')
        checks['functionalFailedAfterSoakReady'] = sibling['time'] >= live_proof['time'] and sibling['soakJobId'] == by_name['probe / soak']['id']
    stubs = list((output / 'artifacts').rglob('publication-stub.json'))
    checks['stubRunsOnlyOnAllPass'] = len(stubs) == (1 if selected == 'all-pass' else 0)
    if stubs:
        stub = read(stubs[0])
        checks['noActualPublication'] = stub.get('published') is False and stub.get('stubExecuted') is True and stub.get('candidateSha') == metadata['head_sha']
        if 'packageSha256' in stub:
            manifest = artifact('package-manifest.json')
            checks['transportedPackageIdentity'] = (stub['packageCandidateSha'] == manifest['candidateSha']
                and stub['packageSha256'] == stub['downloadSha256'] == manifest['packageSha256'])
    result = {'passed': all(checks.values()), 'mode': selected, 'runId': run_id,
              'workflowSha': metadata['head_sha'], 'releaseQualified': False, 'checks': checks}
    write(output / 'verification.json', result)
    print(json.dumps(result, indent=2))
    return 0 if result['passed'] else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=('launch', 'child', 'observe', 'functional', 'verify-cleanup', 'verify-remote'))
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--run-id', type=int, help='Terminal GitHub run ID for verify-remote')
    args = parser.parse_args()
    if args.command == 'verify-remote':
        if not args.run_id:
            parser.error('--run-id is required')
        try:
            return verify_remote(args.output.resolve(), args.run_id)
        except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as error:
            result = {'passed': False, 'mode': mode(), 'runId': args.run_id,
                      'releaseQualified': False, 'error': str(error)}
            if args.output.exists():
                write(args.output / 'verification.json', result)
            print(json.dumps(result, indent=2))
            return 1
    return globals()[args.command.replace('-', '_')](args.output.resolve())


if __name__ == '__main__':
    raise SystemExit(main())
