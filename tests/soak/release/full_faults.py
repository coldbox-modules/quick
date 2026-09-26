#!/usr/bin/env python3
"""Inject bounded faults into full-matrix diagnostics after real sibling work.

Never called by the real release workflow. Functional failure adds a real
TestBox assertion; soak failure kills only its owned application container.
"""
import argparse
import json
import os
from pathlib import Path
import subprocess
import time

MODES = ('all-pass', 'functional-failure', 'soak-failure', 'explicit-cancel')
FIXTURE = '''component extends="testbox.system.BaseSpec" {
    function run() {
        describe( "Full native release matrix diagnostic", function() {
            it( "fails deliberately after the sibling soak has real HTTP and JVM evidence", function() {
                expect( false ).toBeTrue( "Intentional full-matrix functional failure" );
            } );
        } );
    }
}
'''


def mode():
    requested = os.environ.get('FULL_PROBE_MODE', '')
    if requested in MODES:
        return requested
    if requested:
        raise ValueError('Unknown full-matrix diagnostic mode')
    ref = os.environ.get('GITHUB_REF_NAME', '')
    matches = [value for value in MODES if ref.startswith('soak-release-proof-' + value + '-')]
    if len(matches) != 1:
        raise ValueError('An explicit full-matrix diagnostic mode is required')
    return matches[0]


def read(path):
    return json.loads(path.read_text())


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + '\n')


def jobs():
    repository, run = os.environ['GITHUB_REPOSITORY'], os.environ['GITHUB_RUN_ID']
    return json.loads(subprocess.check_output(['gh', 'api',
        f'repos/{repository}/actions/runs/{run}/jobs?per_page=100'], text=True, timeout=30))['jobs']


def live_soak(job):
    return job['name'].startswith('Validation / soak /') and any(
        s['name'] == 'Launch exact-package qualification and prove live work' and s['conclusion'] == 'success'
        for s in job.get('steps', [])) and job['status'] == 'in_progress' and any(
        s['name'] in ('Observe the complete required soak', 'Inject the requested live soak fault')
        and s['status'] == 'in_progress' for s in job.get('steps', []))


def live_testbox(job):
    return job['name'].startswith('Validation / functional /') and job['status'] == 'in_progress' and any(
        s['name'] == 'Run TestBox Tests' and s['status'] == 'in_progress' for s in job.get('steps', []))


def await_sibling(predicate, timeout=1200):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        snapshot = jobs()
        found = next((job for job in snapshot if predicate(job)), None)
        if found:
            return found
        if snapshot and all(job['status'] == 'completed' for job in snapshot):
            break
        time.sleep(5)
    raise RuntimeError('No live sibling reached the required real-work boundary')


def functional(output, root):
    selected = mode()
    # Keep one real functional row available for the deliberate soak/cancel
    # cases. Its normal TestBox command is unchanged and follows this step.
    if selected == 'all-pass':
        return
    sibling = await_sibling(live_soak)
    record = {'mode': selected, 'time': time.time(), 'soakJobId': sibling['id'], 'soak': sibling}
    if selected == 'functional-failure':
        fixture = root / 'tests/specs/SoakNativeFailureSpec.cfc'
        with fixture.open('x') as stream:
            stream.write(FIXTURE)
        record['fixture'] = str(fixture)
        record['assertion'] = 'Intentional full-matrix functional failure'
    write(output / 'functional-injection.json', record)


def soak(output, supervision):
    if mode() != 'soak-failure':
        return
    # The completed launch step proves HTTP and samples. Require a periodic JFR
    # too, so a killed target still has a retained pre-failure recording.
    recording = supervision / 'run/jvm/recording.jfr'
    deadline = time.monotonic() + 120
    while not (recording.exists() and recording.stat().st_size > 0):
        if time.monotonic() >= deadline or (supervision / 'exit.json').exists():
            raise RuntimeError('No retained recording before the deliberate soak failure')
        time.sleep(1)
    sibling = await_sibling(live_testbox)
    summary = read(supervision / 'run/summary.json')
    owned = subprocess.check_output(['docker', 'ps', '-q', '--filter',
        'label=org.quick.soak=' + summary['runId']], text=True).split()
    containers = json.loads(subprocess.check_output(['docker', 'inspect', *owned], text=True))
    targets = [item for item in containers if item['Name'].endswith('-app') and
               item['Config']['Labels'].get('org.quick.soak') == summary['runId']]
    if len(targets) != 1:
        raise RuntimeError('Expected exactly one live run-owned application')
    record = {'mode': 'soak-failure', 'time': time.time(), 'runId': summary['runId'],
              'functionalJobId': sibling['id'], 'functional': sibling, 'containerId': targets[0]['Id']}
    write(output / 'soak-injection-requested.json', record)
    subprocess.run(['docker', 'kill', '--signal', 'KILL', targets[0]['Id']], check=True, stdout=subprocess.DEVNULL)
    write(output / 'soak-injected.json', {**record, 'injected': True})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=('functional', 'soak', 'record'))
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--root', type=Path, default=Path.cwd())
    parser.add_argument('--supervision', type=Path)
    parser.add_argument('--engine')
    parser.add_argument('--coldbox')
    parser.add_argument('--full-null')
    args = parser.parse_args()
    if args.command == 'record':
        if not all((args.engine, args.coldbox, args.full_null)):
            parser.error('Recording requires every functional matrix value')
        write(args.output / 'row.json', {'mode': mode(), 'time': time.time(),
            'name': f'Validation / functional / {args.engine} / {args.coldbox} / null={args.full_null}',
            'workflowRunId': os.environ['GITHUB_RUN_ID']})
    elif args.command == 'functional':
        functional(args.output, args.root)
    else:
        if not args.supervision:
            parser.error('Soak injection requires the owned supervision directory')
        soak(args.output, args.supervision)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
