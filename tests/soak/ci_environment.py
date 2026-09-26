#!/usr/bin/env python3
"""Record public runner identity before toolchain setup, without environment secrets."""
import json
import os
from pathlib import Path
import platform
import subprocess


def main():
    output = Path('tests/results/soak/ci-environment.json')
    output.parent.mkdir(parents=True, exist_ok=True)
    identity = {key: os.environ.get(key) for key in (
        'GITHUB_SHA', 'GITHUB_REF', 'GITHUB_RUN_ID', 'GITHUB_RUN_ATTEMPT', 'GITHUB_JOB',
        'RUNNER_OS', 'RUNNER_ARCH', 'ImageOS', 'ImageVersion')}
    identity.update(kernel=platform.release(), machine=platform.machine(), cpuCount=os.cpu_count())
    if platform.system() == 'Linux':
        identity['cpu'] = json.loads(subprocess.check_output(['lscpu', '--json'], text=True, timeout=10))
        identity['memory'] = Path('/proc/meminfo').read_text()
    output.write_text(json.dumps(identity, indent=2) + '\n')


if __name__ == '__main__':
    main()
