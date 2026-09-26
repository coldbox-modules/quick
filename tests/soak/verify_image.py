#!/usr/bin/env python3
"""Build twice without cache and verify the runtime image identity is repeatable."""
import argparse
import json
from pathlib import Path
import secrets
import subprocess

HERE = Path(__file__).resolve().parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--architecture', choices=('amd64', 'arm64'))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    architecture = args.architecture or subprocess.check_output(['docker', 'info', '--format', '{{.Architecture}}'], text=True).strip()
    architecture = {'aarch64': 'arm64', 'x86_64': 'amd64'}.get(architecture, architecture)
    prefix = 'quick-soak-image-proof:' + secrets.token_hex(6)
    tags, images = [], []
    try:
        for number in (1, 2):
            tag = prefix + '-' + str(number)
            tags.append(tag)
            with (args.output / f'build-{number}.log').open('w') as log:
                subprocess.run(['docker', 'build', '--no-cache', '--platform', 'linux/' + architecture,
                    '--build-arg', 'SOURCE_DATE_EPOCH=0', '-t', tag, str(HERE / 'docker')],
                    stdout=log, stderr=subprocess.STDOUT, timeout=600, check=True)
            image = json.loads(subprocess.check_output(['docker', 'image', 'inspect', tag]))[0]
            # Image configuration contains no per-run container secrets.
            identity = {key: image[key] for key in ('Id', 'Created', 'Architecture', 'Os', 'RootFS', 'Config')}
            (args.output / f'image-{number}.json').write_text(json.dumps(identity, indent=2) + '\n')
            images.append(identity)
        result = {'passed': images[0] == images[1], 'imageIds': [image['Id'] for image in images],
                  'architecture': architecture, 'sourceDateEpoch': 0, 'releaseQualified': False}
        (args.output / 'verification.json').write_text(json.dumps(result, indent=2) + '\n')
        print(json.dumps(result, indent=2))
        return 0 if result['passed'] else 1
    finally:
        for tag in tags:
            subprocess.run(['docker', 'image', 'rm', tag], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=30)


if __name__ == '__main__':
    raise SystemExit(main())
