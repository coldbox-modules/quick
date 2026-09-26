#!/usr/bin/env python3
"""Promote only the exact package in a complete qualification receipt.

The release job must depend on the entire required validation matrix and hold
repository-wide publication concurrency with cancel-in-progress: false. This
entry point is not wired into that workflow until baseline acceptance. Local
invocation is rejected; provider writes are not retried after uncertain results.
"""
import argparse
import json
import os
from pathlib import Path
import re
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from controller import write_json
from qualification import verify_qualification
from package import promote, digest
from provider import Publisher


def release_context(environment, candidate):
    branch = environment.get('GITHUB_REF', '').removeprefix('refs/heads/')
    if (environment.get('GITHUB_ACTIONS') != 'true'
            or environment.get('GITHUB_REPOSITORY') != 'coldbox-modules/quick'
            or environment.get('GITHUB_EVENT_NAME') != 'push'
            or branch not in ('main', 'master')
            or environment.get('GITHUB_SHA') != candidate
            or not re.fullmatch(r'[0-9a-f]{40}', candidate)):
        raise ValueError('Publication requires the matching Quick release-branch push context')
    return branch


def promote_qualified(run, candidate, baseline, publisher_factory):
    # Verify raw evidence, accepted inputs and the exact ZIP before even creating
    # the provider adapter. A summary status or workflow exit code is not proof.
    qualification = verify_qualification(run, candidate, baseline)
    manifest_bytes = (run / 'package/package-manifest.json').read_bytes()
    if digest(manifest_bytes) != qualification['files']['package/package-manifest.json']:
        raise ValueError('Package manifest changed after qualification verification')
    manifest = json.loads(manifest_bytes)
    publisher = publisher_factory()
    publisher.checkpoint('qualification-verified', candidateSha=candidate,
                         packageSha256=qualification['packageSha256'],
                         baselineSha256=qualification['baselineSha256'],
                         evidenceSha256=qualification['evidenceSha256'])
    receipt = promote(run / 'package', candidate, publisher, expected_manifest=manifest)
    receipt.update(baselineSha256=qualification['baselineSha256'],
                   evidenceSha256=qualification['evidenceSha256'])
    write_json(publisher.journal / 'publication-receipt.json', receipt)
    return receipt


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run', required=True, type=Path, help='Complete downloaded qualified-run artifact')
    parser.add_argument('--candidate', required=True)
    parser.add_argument('--baseline', required=True, type=Path, help='Accepted baseline from the checked-out release commit')
    parser.add_argument('--journal', required=True, type=Path, help='New directory; preserve even on failure')
    args = parser.parse_args()
    try:
        branch = release_context(os.environ, args.candidate)
        def publisher():
            return Publisher(forgebox_token=os.environ.get('FORGEBOX_TOKEN'),
                             github_token=os.environ.get('GH_TOKEN'), branch=branch, journal=args.journal)
        receipt = promote_qualified(args.run, args.candidate, args.baseline, publisher)
    except (ValueError, KeyError, OSError, RuntimeError) as error:
        print(str(error), file=sys.stderr)
        return 1
    print(json.dumps(receipt, indent=2))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
