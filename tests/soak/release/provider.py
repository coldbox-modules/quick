"""Immutable ForgeBox storage and GitHub release adapter.

Protocol follows CommandBox 6.3.5 ForgeBox.cfc, not its directory ZIP builder.
The caller must hold the repository publication concurrency guard throughout
package.promote(). This module has no CLI and is not connected to release CI yet.
"""
import datetime
import hashlib
import io
import json
import os
from pathlib import Path
import urllib.error
import urllib.parse
import urllib.request
import zipfile

from package import digest

FORGEBOX = 'https://www.forgebox.io/api/v1/'
GITHUB = 'https://api.github.com/repos/coldbox-modules/quick/'


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


class Http:
    """One attempt per request; never forward API credentials to another host."""
    def request(self, method, url, headers, body=None):
        if urllib.parse.urlsplit(url).scheme != 'https':
            raise ValueError('Provider endpoints must use HTTPS')
        request = urllib.request.Request(url, data=body, method=method,
                                         headers={'User-Agent': 'Quick-immutable-release/1', **headers})
        try:
            with urllib.request.build_opener(NoRedirect()).open(request, timeout=120) as response:
                data = response.read(100 * 1024 * 1024 + 1)
                if len(data) > 100 * 1024 * 1024:
                    raise ValueError('Provider response exceeds the declared bound')
                return response.status, data
        except urllib.error.HTTPError as error:
            # URLs may contain signed storage credentials; do not echo them.
            return error.code, b''
        except (urllib.error.URLError, TimeoutError, OSError):
            raise RuntimeError('Provider request did not complete; reconcile remote state before another write') from None


class Publisher:
    def __init__(self, *, forgebox_token, github_token, branch, journal, transport=None):
        if branch not in ('main', 'master') or not forgebox_token or not github_token:
            raise ValueError('Release branch and both provider credentials are required')
        self.branch, self.transport = branch, transport or Http()
        self.forgebox_token, self.github_token = forgebox_token, github_token
        self.journal = Path(journal)
        self.journal.mkdir(parents=True, exist_ok=False)
        self.sequence = 0
        self.uploaded = None
        self.downloaded = None

    def checkpoint(self, stage, **metadata):
        self.sequence += 1
        record = {'stage': stage, 'at': datetime.datetime.now(datetime.timezone.utc).isoformat(), **metadata}
        temporary = self.journal / 'pending.tmp'
        with temporary.open('w') as stream:
            json.dump(record, stream, indent=2)
            stream.write('\n')
            stream.flush()
            os.fsync(stream.fileno())
        temporary.replace(self.journal / f'{self.sequence:02d}-{stage}.json')
        fd = os.open(self.journal, os.O_RDONLY)
        try:
            os.fsync(fd)
        finally:
            os.close(fd)

    def api(self, provider, path, *, method='GET', data=None, missing=False):
        headers = {'Accept': 'application/json'}
        if provider == 'forgebox':
            root = FORGEBOX
            headers['X-Api-Token'] = self.forgebox_token
            if data is not None:
                headers['Content-Type'] = 'application/x-www-form-urlencoded'
                data = urllib.parse.urlencode(data).encode()
        else:
            root = GITHUB
            headers.update(Authorization='Bearer ' + self.github_token,
                           **{'X-GitHub-Api-Version': '2022-11-28'})
            if data is not None:
                headers['Content-Type'] = 'application/json'
                data = json.dumps(data).encode()
        status, body = self.transport.request(method, root + path, headers, data)
        if status == 404 and missing:
            return None
        if status not in (200, 201):
            raise RuntimeError(f'{provider} {method} returned HTTP {status}; reconcile before retrying publication')
        try:
            result = json.loads(body)
        except (ValueError, UnicodeDecodeError):
            raise ValueError('Provider returned an invalid JSON envelope') from None
        if provider == 'forgebox':
            if result.get('error') is not False or 'data' not in result:
                raise ValueError('ForgeBox rejected the request')
            return result['data']
        return result

    def candidate_sha(self):
        ref = self.api('github', 'git/ref/heads/' + self.branch)['object']
        if ref['type'] != 'commit':
            raise ValueError('Release branch does not identify a commit')
        return ref['sha']

    def last_release(self):
        entry = self.api('forgebox', 'entry/quick')
        release = self.api('github', 'releases/latest')
        latest = entry['latestVersion']
        version = latest['version']
        if release['tag_name'] != 'v' + version or release['draft'] or release['prerelease']:
            raise ValueError('ForgeBox and GitHub release identities disagree')
        ref = self.api('github', 'git/ref/tags/v' + version)
        target = ref['object']
        for _ in range(5):
            if target['type'] == 'commit':
                break
            if target['type'] != 'tag':
                raise ValueError('Last release tag does not identify a commit')
            target = self.api('github', 'git/tags/' + target['sha'])['object']
        if target['type'] != 'commit':
            raise ValueError('Last release tag chain is too deep')
        return {'version': version, 'forgeboxEntryId': entry['entryID'], 'forgeboxBinaryHash': latest['binaryHash'].lower(),
                'githubReleaseId': release['id'], 'tag': release['tag_name'], 'tagObjectSha': ref['object']['sha'], 'commitSha': target['sha']}

    def version_exists(self, version):
        entry = self.api('forgebox', 'entry/quick')
        if not isinstance(entry.get('versions'), list):
            raise ValueError('ForgeBox version inventory is unavailable')
        if any(item['version'] == version for item in entry['versions']):
            return True
        # An orphaned storage upload or tag is also a partial publication. Never
        # overwrite it just because the final release record is absent.
        return (self.api('forgebox', 'storage/quick/' + version, missing=True) is not None
                or self.api('github', 'git/ref/tags/v' + version, missing=True) is not None
                or self.api('github', 'releases/tags/v' + version, missing=True) is not None)

    def upload(self, manifest, data):
        if manifest['slug'] != 'quick' or digest(data) != manifest['packageSha256']:
            raise ValueError('Upload differs from the tested Quick artifact')
        if self.candidate_sha() != manifest['candidateSha'] or self.last_release() != manifest['lastRelease']:
            raise ValueError('Candidate or prepared release changed before upload')
        if self.version_exists(manifest['version']):
            raise ValueError('Version or partial publication already exists')
        with zipfile.ZipFile(io.BytesIO(data)) as package:
            descriptor_text = package.read('box.json').decode()
            descriptor = json.loads(descriptor_text)
            description = package.read('README.md').decode()
            changelog = package.read('CHANGELOG.md').decode()
        if descriptor.get('location') != 'forgeboxStorage' or descriptor.get('private', False):
            raise ValueError('This adapter requires the public ForgeBox-storage package')
        identity = {key: manifest[key] for key in ('candidateSha', 'version', 'packageSha256')}
        self.checkpoint('before-storage-upload', **identity)
        url = self.api('forgebox', 'storage/storeURL/quick/' + manifest['version'])
        if not isinstance(url, str) or urllib.parse.urlsplit(url).scheme != 'https':
            raise ValueError('ForgeBox returned an invalid storage URL')
        status, _ = self.transport.request('PUT', url, {'Content-Type': 'application/zip'}, data)
        if status != 200:
            raise RuntimeError(f'Storage upload returned HTTP {status}; reconcile before retrying publication')
        self.checkpoint('storage-uploaded', **identity)
        fields = {'slug': 'quick', 'private': 'false', 'version': manifest['version'], 'boxJSON': descriptor_text,
                  'isStable': 'true', 'description': description, 'descriptionFormat': 'md',
                  'installInstructions': descriptor.get('instructions', ''), 'installInstructionsFormat': 'text',
                  'changeLog': changelog, 'changeLogFormat': 'md', 'forceUpload': 'false',
                  'binaryHash': hashlib.md5(data).hexdigest()}
        self.checkpoint('before-forgebox-publish', **identity)
        self.api('forgebox', 'publish', method='POST', data=fields)
        self.checkpoint('forgebox-published', **identity)
        self.uploaded = identity

    def download(self, manifest):
        if self.uploaded is None or self.uploaded['packageSha256'] != manifest['packageSha256']:
            raise ValueError('This publication has not uploaded the tested artifact')
        url = self.api('forgebox', 'storage/quick/' + manifest['version'])
        if not isinstance(url, str) or urllib.parse.urlsplit(url).scheme != 'https':
            raise ValueError('ForgeBox returned an invalid download URL')
        status, data = self.transport.request('GET', url, {}, None)
        if status != 200 or digest(data) != manifest['packageSha256']:
            raise ValueError('Published download differs from the tested artifact')
        self.downloaded = digest(data)
        self.checkpoint('download-verified', **self.uploaded, downloadSha256=self.downloaded)
        return data

    def publicize(self, manifest, notes):
        if self.downloaded != manifest['packageSha256']:
            raise ValueError('Exact published download must be verified before GitHub release creation')
        tag = 'v' + manifest['version']
        if (self.api('github', 'git/ref/tags/' + tag, missing=True) is not None
                or self.api('github', 'releases/tags/' + tag, missing=True) is not None):
            raise ValueError('GitHub tag or release appeared during publication; reconcile it')
        self.checkpoint('before-github-release', **self.uploaded)
        release = self.api('github', 'releases', method='POST', data={'tag_name': tag,
            'target_commitish': manifest['candidateSha'], 'name': tag, 'body': notes,
            'draft': False, 'prerelease': False, 'generate_release_notes': False})
        # Confirm the actual tag, not merely the submitted target_commitish.
        ref = self.api('github', 'git/ref/tags/' + tag)['object']
        if ref['type'] != 'commit' or ref['sha'] != manifest['candidateSha'] or release['tag_name'] != tag:
            raise ValueError('Created release does not resolve to the tested candidate')
        self.checkpoint('complete', **self.uploaded, githubReleaseId=release['id'], downloadSha256=self.downloaded)
