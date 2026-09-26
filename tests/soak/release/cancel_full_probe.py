#!/usr/bin/env python3
"""Cancel one explicitly tagged full diagnostic run after both kinds of work start."""
import argparse
import json
from pathlib import Path
import subprocess
import time

from full_faults import live_soak, live_testbox
from verify_full_probe import api, REPOSITORY


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run-id', required=True, type=int)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    deadline = time.monotonic() + 1800
    while time.monotonic() < deadline:
        workflow = api(f'actions/runs/{args.run_id}')
        if workflow['path'] != '.github/workflows/soak-release-proof.yml' or not workflow['head_branch'].startswith('soak-release-proof-explicit-cancel-'):
            raise ValueError('Refusing to cancel anything except the explicitly tagged full diagnostic run')
        if workflow['status'] == 'completed':
            raise RuntimeError('The original run ended before concurrent live work; do not restart it')
        jobs = api(f'actions/runs/{args.run_id}/jobs?per_page=100')['jobs']
        if any(live_soak(j) for j in jobs) and any(live_testbox(j) for j in jobs):
            request = {'runId': workflow['id'], 'candidateSha': workflow['head_sha'], 'jobs': jobs,
                       'requestedAt': time.time(), 'cancelRequested': False}
            args.output.parent.mkdir(parents=True, exist_ok=True)
            with args.output.open('x') as stream:
                stream.write(json.dumps(request, indent=2) + '\n')
            subprocess.run(['gh', 'run', 'cancel', str(args.run_id), '--repo', REPOSITORY], check=True)
            request['cancelRequested'] = True
            args.output.write_text(json.dumps(request, indent=2) + '\n')
            return 0
        time.sleep(5)
    raise RuntimeError('Concurrent real TestBox and soak work was not observed before the deadline')


if __name__ == '__main__':
    raise SystemExit(main())
