#!/usr/bin/env python3
"""Build and inspect release validation artifacts without any publisher access."""
import argparse
import json
import os
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from package import build, build_validation, verify
from qualification import verify_qualification, verify_validation


def inspect_artifact(run, candidate, baseline):
    package = verify(run / 'package', candidate)
    validation = package.get('validationOnly') is True
    receipt = (verify_validation if validation else verify_qualification)(run, candidate, baseline)
    return {'publicationRequired': not validation, 'candidateSha': receipt['candidateSha'],
            'packageSha256': receipt['packageSha256']}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    p = sub.add_parser('build')
    p.add_argument('--repo', required=True, type=Path)
    p.add_argument('--prepared', required=True, type=Path)
    p.add_argument('--output', required=True, type=Path)
    p = sub.add_parser('inspect')
    p.add_argument('--run', required=True, type=Path)
    p.add_argument('--candidate', required=True)
    p.add_argument('--baseline', required=True, type=Path)
    args = parser.parse_args()
    if args.command == 'build':
        prepared = json.loads(args.prepared.read_text())
        result = (build_validation if prepared.get('noRelease') is True else build)(args.repo, prepared, args.output)
        print(json.dumps({'candidateSha': result['candidateSha'], 'validationOnly': result.get('validationOnly', False)}))
    else:
        result = inspect_artifact(args.run, args.candidate, args.baseline)
        # Emit only a constant boolean after receipt and raw evidence verification.
        if os.environ.get('GITHUB_OUTPUT'):
            with open(os.environ['GITHUB_OUTPUT'], 'a') as stream:
                stream.write('publish=' + str(result['publicationRequired']).lower() + '\n')
        print(json.dumps(result))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
