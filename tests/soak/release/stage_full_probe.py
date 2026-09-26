#!/usr/bin/env python3
"""Generate the full native diagnostic matrix from the pending release workflow.

Validation keeps every row, test command and qualification step; diagnostic
fault hooks and JSON report retention are added. Publication is replaced
wholesale with a local-only receipt/promotion probe.
Do not dispatch until the accepted baseline and matching detectors exist.
"""
import argparse
import hashlib
from pathlib import Path

HERE = Path(__file__).resolve().parent
TARGET = HERE.parents[2] / '.github/workflows/soak-release-proof.yml'

HEADER = '''name: Full release validation proof (no publication)

on:
  workflow_dispatch:
    inputs:
      mode:
        description: Full native matrix scenario
        required: true
        default: all-pass
        type: choice
        options: [all-pass, functional-failure, soak-failure, explicit-cancel]
  push:
    tags:
      - 'soak-release-proof-*'

permissions:
  contents: read
  actions: read

env:
  FULL_PROBE_MODE: ${{ inputs.mode || '' }}

jobs:
'''

FUNCTIONAL_HOOK = '''      - name: Prepare the requested live functional fault
        if: matrix.kind == 'functional' && matrix.cfengine == 'lucee@6' && matrix.coldbox == 'coldbox@^8' && matrix.fullNull == 'true'
        env:
          GH_TOKEN: ${{ github.token }}
        run: python3 tests/soak/release/full_faults.py functional --output tests/results/soak/full-functional-probe

'''
FUNCTIONAL_COMMAND = '''        run: |
          python3 tests/soak/release/full_faults.py record --output tests/results/soak/full-functional-probe --engine "${{ matrix.cfengine }}" --coldbox "${{ matrix.coldbox }}" --full-null "${{ matrix.fullNull }}"
          box testbox run outputFile=tests/results/soak/full-functional-probe/testbox.json
      - name: Preserve the actual functional result and fault record
        if: always() && matrix.kind == 'functional'
        uses: actions/upload-artifact@v4.6.2
        with:
          name: full-functional-${{ strategy.job-index }}-${{ github.run_id }}
          path: tests/results/soak/full-functional-probe/
          if-no-files-found: warn
          retention-days: 30
'''
SOAK_HOOK = '''      - name: Inject the requested live soak fault
        if: matrix.kind == 'soak'
        env:
          GH_TOKEN: ${{ github.token }}
        run: python3 tests/soak/release/full_faults.py soak --output tests/results/soak/release-candidate/probe --supervision tests/results/soak/release-candidate/supervision
'''

PUBLISHER = '''
  publication-stub:
    name: Full receipt publication stub (no provider calls)
    needs: validation
    runs-on: ubuntu-24.04
    timeout-minutes: 20
    concurrency:
      group: quick-release-diagnostic-publication
      cancel-in-progress: false
    steps:
      - uses: actions/checkout@v4.2.2
        with:
          ref: ${{ github.sha }}
          fetch-depth: 0
      - uses: actions/download-artifact@v4.3.0
        with:
          name: release-soak-${{ github.sha }}-${{ github.run_attempt }}
          path: tests/results/soak/downloaded-candidate
      - name: Verify the complete receipt and exercise local-only promotion
        env:
          CANDIDATE_SHA: ${{ github.sha }}
          HOLD_SECONDS: ${{ contains(github.ref_name, '-serialization-') && '180' || '0' }}
        run: |
          python3 tests/soak/release/probe_qualified.py \\
            --run tests/results/soak/downloaded-candidate/supervision/run \\
            --candidate "$CANDIDATE_SHA" \\
            --baseline tests/soak/baselines/lucee6-serial.json \\
            --output tests/results/soak/full-publication-proof \\
            --hold-seconds "$HOLD_SECONDS"
      - name: Retain local publication proof, including partial failures
        if: always()
        uses: actions/upload-artifact@v4.6.2
        with:
          name: full-publication-proof-${{ github.run_id }}
          path: tests/results/soak/full-publication-proof/
          if-no-files-found: error
          retention-days: 30
'''


def render(template):
    if template.count('\njobs:\n') != 1 or template.count('\n  release:\n') != 1:
        raise ValueError('Pending workflow structure changed; review probe generation')
    validation = template.split('\njobs:\n')[1].split('\n  release:\n')[0]
    skip = '    if: "!contains(github.event.head_commit.message, \'__SEMANTIC RELEASE VERSION UPDATE__\')"\n'
    if validation.count(skip) != 1:
        raise ValueError('Expected exactly one release-message skip condition')
    validation = validation.replace(skip, '')
    for marker in ('      - name: Run TestBox Tests\n', '        run: box testbox run\n',
                   '      - name: Observe the complete required soak\n'):
        if validation.count(marker) != 1:
            raise ValueError('Validation step changed; review diagnostic instrumentation')
    validation = validation.replace('      - name: Run TestBox Tests\n', FUNCTIONAL_HOOK + '      - name: Run TestBox Tests\n')
    validation = validation.replace('        run: box testbox run\n', FUNCTIONAL_COMMAND)
    validation = validation.replace('      - name: Observe the complete required soak\n', SOAK_HOOK + '      - name: Observe the complete required soak\n')
    if validation.count('- kind: functional') != 23 or validation.count('- kind: soak') != 1:
        raise ValueError('Full proof requires all 23 functional rows and exactly one soak row')
    for forbidden in ('contents: write', 'FORGEBOX_TOKEN', 'promote_qualified.py'):
        if forbidden in validation:
            raise ValueError('Validation unexpectedly contains publisher capabilities')
    source_hash = hashlib.sha256(template.encode()).hexdigest()
    return '# Generated by tests/soak/release/stage_full_probe.py; do not edit.\n' + \
        '# Pending workflow SHA-256: ' + source_hash + '\n' + HEADER + validation + PUBLISHER


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='Reject drift without rewriting')
    parser.add_argument('--output', type=Path, default=TARGET)
    args = parser.parse_args()
    content = render((HERE / 'release.yml.pending').read_text())
    if args.check:
        if args.output.read_text() != content:
            raise ValueError('Full diagnostic workflow differs from the pending release validation')
    else:
        args.output.write_text(content)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
