#!/usr/bin/env python3
"""Supervise full qualification using the verified native cancellation handoff.

Launch survives the runner step, observe exits promptly on cancellation, and
always-run cleanup waits for the controller's single owned-resource teardown.
No publication capability is present here.
"""
import argparse
from pathlib import Path
import signal
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HERE))
from matrix_probe import live, observe, read, stop, write


def child(output):
    code = 1
    with (output / 'controller.log').open('w') as log:
        try:
            request = read(output / 'request.json')
            command = [sys.executable, str(HERE / 'qualification.py'), '--output', str(output / 'run')]
            for name in ('baseline', 'profile', 'package', 'candidate'):
                command.extend(['--' + name, request[name]])
            prepared = read(Path(request['package']) / 'prepared.json')
            if prepared.get('noRelease') is True:
                command.append('--validation-only')
            process = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=log, stderr=subprocess.STDOUT)
            write(output / 'process.json', {'pid': process.pid})
            code = process.wait()
        except Exception as error:
            log.write(str(error) + '\n')
        finally:
            write(output / 'exit.json', {'code': code})
    return code


def launch(args):
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    request = {key: str(getattr(args, key).resolve()) for key in ('baseline', 'profile', 'package')}
    request['candidate'] = args.candidate
    write(output / 'request.json', request)
    def canceled(signum, frame):
        raise KeyboardInterrupt('Native validation cancellation during launch')
    signal.signal(signal.SIGTERM, canceled)
    try:
        with (output / 'supervisor.log').open('w') as log:
            process = subprocess.Popen([sys.executable, str(Path(__file__).resolve()), 'child', '--output', str(output)],
                stdin=subprocess.DEVNULL, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        deadline = time.monotonic() + 750
        while time.monotonic() < deadline:
            if live(output / 'run'):
                write(output / 'live.json', {'live': True, 'time': time.time(), 'supervisorPid': process.pid})
                return 0
            if process.poll() is not None or (output / 'exit.json').exists():
                raise RuntimeError('Qualification ended before live HTTP and JVM evidence; see controller.log')
            time.sleep(1)
        raise RuntimeError('Qualification did not become live before its setup deadline')
    except KeyboardInterrupt:
        signal.signal(signal.SIGINT, signal.SIG_IGN)
        signal.signal(signal.SIGTERM, signal.SIG_IGN)
        write(output / 'native-signal.json', {'received': True, 'time': time.time()})
        stop(output, wait=False)
        return 130
    except BaseException:
        stop(output)
        raise


def cleanup(output):
    stop(output)
    if not (output / 'exit.json').exists():
        raise RuntimeError('Independent qualification supervisor has no terminal result')
    run = output / 'run'
    summary = read(run / 'summary.json')
    if not run.exists():
        write(output / 'cleanup-verification.json', {'passed': True, 'provisioned': False})
        return 0  # Qualification preflight rejected before resource creation.
    if not summary.get('runId'):
        raise RuntimeError('Missing run identity prevents owned-resource verification')
    checks = {'controllerCleanupComplete': not any('Cleanup incomplete:' in reason for reason in summary.get('reasons', []))}
    for noun, command in (('containers', ['docker', 'ps', '-aq']), ('volumes', ['docker', 'volume', 'ls', '-q']),
                          ('networks', ['docker', 'network', 'ls', '-q'])):
        checks[noun + 'Removed'] = not subprocess.check_output(command + ['--filter', 'label=org.quick.soak=' + summary['runId']], text=True).strip()
    volumes = read(run / 'mysql-volumes.json')
    if volumes:
        checks['anonymousDatabaseVolumeRemoved'] = all(subprocess.run(['docker', 'volume', 'inspect', row['name']],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0 for row in volumes)
    result = {'passed': all(checks.values()), 'checks': checks, 'runId': summary['runId']}
    write(output / 'cleanup-verification.json', result)
    return 0 if result['passed'] else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=('launch', 'child', 'observe', 'cleanup'))
    parser.add_argument('--output', type=Path, required=True)
    for name in ('baseline', 'profile', 'package'):
        parser.add_argument('--' + name, type=Path)
    parser.add_argument('--candidate')
    args = parser.parse_args()
    if args.command == 'launch':
        if any(getattr(args, key) is None for key in ('baseline', 'profile', 'package', 'candidate')):
            parser.error('Launch requires baseline, profile, package, and candidate')
        return launch(args)
    output = args.output.resolve()
    if args.command == 'observe':
        return observe(output, timeout_seconds=5400)
    return globals()[args.command](output)


if __name__ == '__main__':
    raise SystemExit(main())
