#!/usr/bin/env python3
"""Prepare release metadata using immutable Git objects and semantic-release 4.1.0.

Only public provider reads and local artifact writes. No publication capability.
"""
import argparse
import datetime
import json
import hashlib
import shutil
from pathlib import Path
import re
import subprocess
import urllib.request

REPOSITORY = 'coldbox-modules/quick'


def command(args, cwd=None):
    return subprocess.check_output(args, cwd=cwd, timeout=60).decode().strip()


def github(path):
    return json.loads(command(['gh', 'api', 'repos/' + REPOSITORY + '/' + path]))


def identity():
    with urllib.request.urlopen('https://www.forgebox.io/api/v1/entry/quick', timeout=30) as response:
        entry = json.load(response)
    if entry.get('error'):
        raise ValueError('ForgeBox read failed; refusing to assume a first release')
    entry = entry['data']
    latest = entry['latestVersion']
    release = github('releases/latest')
    version = latest['version']
    if release['tag_name'] != 'v' + version or release['draft'] or release['prerelease']:
        raise ValueError('ForgeBox and GitHub release state disagree; reconcile before preparation')
    ref = github('git/ref/tags/v' + version)
    target = ref['object']
    for _ in range(5):
        if target['type'] == 'commit':
            break
        if target['type'] != 'tag':
            raise ValueError('Last release tag does not identify a commit')
        target = github('git/tags/' + target['sha'])['object']
    if target['type'] != 'commit':
        raise ValueError('Last release tag chain is too deep')
    return {'version': version, 'forgeboxEntryId': entry['entryID'], 'forgeboxBinaryHash': latest['binaryHash'].lower(),
            'githubReleaseId': release['id'], 'tag': release['tag_name'], 'tagObjectSha': ref['object']['sha'], 'commitSha': target['sha']}


def prepare(repo, candidate, output, task):
    if not re.fullmatch('[0-9a-f]{40}', candidate):
        raise ValueError('Candidate must be a full commit SHA')
    if command(['git', 'rev-parse', candidate + '^{commit}'], repo) != candidate:
        raise ValueError('Candidate is not a commit')
    # Plugins use this checkout only for abbreviation; committed content comes
    # from explicit object IDs and package.py later archives the same candidate.
    if not (repo / '.git').is_dir():
        raise ValueError('Preparation requires a full checkout (JGit plugin worktree support is unqualified)')
    last = identity()
    subprocess.run(['git', 'merge-base', '--is-ancestor', last['commitSha'], candidate], cwd=repo, check=True, timeout=30)
    if command(['git', 'rev-parse', 'refs/tags/' + last['tag']], repo) != last['tagObjectSha']:
        raise ValueError('Local last-release tag differs from provider state')
    shas = command(['git', 'rev-list', '--topo-order', last['commitSha'] + '..' + candidate], repo).splitlines()
    output.mkdir(parents=True, exist_ok=False)
    request = {'preparedAt': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'candidateSha': candidate, 'lastRelease': last, 'commitShas': shas,
               'repositoryURL': 'https://github.com/' + REPOSITORY}
    for source in (Path(__file__), task):
        shutil.copyfile(source, output / source.name)
    (output / 'input.json').write_text(json.dumps(request, indent=2) + '\n')
    # The task invokes pinned semantic-release plugin APIs, never semantic-release
    # itself: its dry-run fallback and write hooks are deliberately not involved.
    with (output / 'prepare.log').open('w') as log:
        subprocess.run(['box', 'task', 'run', 'taskFile=' + str(output / task.name), ':input=' + str(output / 'input.json'),
                        ':output=' + str(output / 'prepared.json')], cwd=repo, stdout=log, stderr=subprocess.STDOUT,
                       check=True, timeout=180)
    prepared = json.loads((output / 'prepared.json').read_text())
    if prepared['candidateSha'] != candidate or prepared['lastRelease'] != last:
        raise ValueError('Preparation identity changed')
    if identity() != last:
        raise ValueError('Release state changed during preparation; discard these untested inputs')
    prepared['preparationSources'] = {source.name: hashlib.sha256((output / source.name).read_bytes()).hexdigest() for source in (Path(__file__), task)}
    (output / 'prepared.json').write_text(json.dumps(prepared, indent=2) + '\n')
    return prepared


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', required=True, type=Path)
    parser.add_argument('--candidate', required=True)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    print(json.dumps(prepare(args.repo.resolve(), args.candidate, args.output.resolve(), Path(__file__).with_name('Prepare.cfc')), indent=2))
