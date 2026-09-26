#!/usr/bin/env python3
"""Exercise complete qualified/no-release receipts with a local-only publisher.

Used by the full release-matrix diagnostic workflow. No network adapter or
provider credentials are available here; real promotion remains release-only.
"""
import argparse
import json
import os
from pathlib import Path
import time

from package import digest
from promote_qualified import promote_qualified
from validate_candidate import inspect_artifact


def write(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


class LocalPublisher:
    """Persist the exact upload/readback and simulated publicization locally."""
    def __init__(self, manifest, journal):
        self.manifest, self.journal = manifest, journal
        journal.mkdir(parents=True, exist_ok=False)
        self.sequence = 0

    def checkpoint(self, stage, **metadata):
        self.sequence += 1
        write(self.journal / f'{self.sequence:02d}-{stage}.json', {'stage': stage, **metadata})

    def candidate_sha(self):
        return self.manifest['candidateSha']

    def last_release(self):
        return self.manifest['lastRelease']

    def version_exists(self, version):
        return (self.journal / 'upload.zip').exists()

    def upload(self, manifest, data):
        if manifest != self.manifest or digest(data) != manifest['packageSha256']:
            raise ValueError('Local stub upload differs from verified artifact')
        with (self.journal / 'upload.zip').open('xb') as stream:
            stream.write(data)
        self.checkpoint('stub-uploaded', packageSha256=digest(data))

    def download(self, manifest):
        return (self.journal / 'upload.zip').read_bytes()

    def publicize(self, manifest, notes):
        self.checkpoint('stub-publicized', candidateSha=manifest['candidateSha'],
                        packageSha256=manifest['packageSha256'], notes=notes)


def probe(run, candidate, baseline, output, hold_seconds=0):
    if type(hold_seconds) is not int or not 0 <= hold_seconds <= 180:
        raise ValueError('Guard hold must be an integer between 0 and 180 seconds')
    started = time.time()
    # No output or fake provider exists until the complete raw receipt verifies.
    eligibility = inspect_artifact(run, candidate, baseline)
    output.mkdir(parents=True, exist_ok=False)
    write(output / 'guard-started.json', {'time': started, 'holdSeconds': hold_seconds})
    receipt = None
    if eligibility['publicationRequired']:
        manifest = json.loads((run / 'package/package-manifest.json').read_text())
        receipt = promote_qualified(run, candidate, baseline,
            lambda: LocalPublisher(manifest, output / 'local-publisher'))
    time.sleep(hold_seconds)
    result = {**eligibility, 'fullReceiptVerified': True, 'published': False,
              'stubPublished': receipt is not None, 'providerWrites': 0,
              'workflowRunId': os.environ.get('GITHUB_RUN_ID'),
              'guardStartedAt': started, 'guardFinishedAt': time.time(),
              'holdSeconds': hold_seconds, 'promotionReceipt': receipt}
    write(output / 'qualified-publication-stub.json', result)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run', required=True, type=Path)
    parser.add_argument('--candidate', required=True)
    parser.add_argument('--baseline', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--hold-seconds', type=int, default=0)
    args = parser.parse_args()
    print(json.dumps(probe(args.run, args.candidate, args.baseline, args.output, args.hold_seconds), indent=2))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
