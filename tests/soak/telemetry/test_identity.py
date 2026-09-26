import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).parents[1]))
from identity import (CPU_FIELDS, DOCKER_FIELDS, JVM_FIELDS, build_identity,
                      measured_source, profile_identity, require_match, sha_file)
from calibration import validate_trial_profile

HERE = Path(__file__).parents[1]
PROFILE = json.loads((HERE / 'profiles/lucee6-serial.json').read_text())


class IdentityTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.run = Path(self.tmp.name)
        self.write('profile.json', PROFILE)
        host = {'docker': {key: 'fixed-' + key for key in DOCKER_FIELDS},
                'cpu': {'lscpu': [{'field': key + ':', 'data': 'fixed-' + key} for key in CPU_FIELDS]},
                'runnerImage': 'ubuntu24', 'runnerImageVersion': '20260921.1', 'githubRunId': '123'}
        self.write('host.json', host)
        sources = {}
        for path in HERE.rglob('*'):
            name = str(path.relative_to(HERE))
            if path.is_file() and measured_source(name) and not any(
                    part in path.parts for part in ('.engine', 'modules', 'coldbox', 'logs', '__pycache__')):
                destination = self.run / 'harness' / name
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(path.read_bytes())
                sources[name] = sha_file(destination)
        self.write('harness-manifest.json', sources)
        runtime = {key: 'fixed-' + key for key in JVM_FIELDS}
        runtime.update(kind='runtime', collectors='ZGC Cycles,ZGC Pauses')
        self.write('jvm/jvm.ndjson', runtime)
        self.write('initial-diagnostics.json', {'parallelEagerLoading': False, 'luceeVersion': '6.2.8.20', 'coldboxVersion': '8.2.0+35',
                   'appName': 'Quick release soak', 'exceptionHandler': 'Api.onException'})
        self.write('dependency-files.json', {'coldbox/Controller.cfc': 'hash-a'})
        self.write('dependency-identity.json', {'sha256': sha_file(self.run / 'dependency-files.json')})
        self.write('runtime-containers.json', [{'name': 'run-one-' + role, 'image': 'sha256:' + role,
                   'limits': {'Memory': 1024, 'MemorySwap': 2048, 'NanoCpus': 1000000000}}
                   for role in ('app', 'mysql', 'collector')])
        self.write('generator.json', {'image': 'sha256:k6', 'limits': {'Memory': 512, 'NanoCpus': 750000000}})
        self.write('fixtures/fixture-manifest.json', {'version': 'v1', 'sqlSha256': 'seed-a'})
        (self.run / 'seed-commandbox-version.log').write_text('CommandBox 6.3.5+00887\n')

    def write(self, name, value):
        path = self.run / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(value) + '\n')

    def read(self, name):
        return json.loads((self.run / name).read_text())

    def test_public_identity_survives_review_metadata_and_new_run(self):
        before = build_identity(self.run)
        profile = self.read('profile.json')
        profile.update(status='accepted', acceptedBaseline='reviewed-baseline.json', id='reviewed-name')
        self.write('profile.json', profile)
        self.write('package/package-manifest.json', {'candidateSha': 'different-candidate'})
        host = self.read('host.json')
        host.update(githubRunId='456', githubSha='new-candidate')
        host['cpu']['lscpu'].append({'field': 'CPU MHz:', 'data': 'variable'})
        self.write('host.json', host)
        (self.run / 'harness/README.md').write_text('Reviewed baseline instructions')
        # Release tooling is audited in the complete snapshot. Its exact ZIP
        # output is bound separately; it does not execute during measurement.
        release = self.run / 'harness/release'
        release.mkdir(exist_ok=True)
        (release / 'package.py').write_text('changed publication validation')
        runtime = self.read('jvm/jvm.ndjson')
        runtime.update(pid='999', time=100000, startTime=5000)
        self.write('jvm/jvm.ndjson', runtime)
        require_match(before, build_identity(self.run))

    def test_dependency_change_requires_recalibration_even_for_new_candidate(self):
        before = build_identity(self.run)
        self.write('dependency-files.json', {'coldbox/Controller.cfc': 'hash-b'})
        self.write('dependency-identity.json', {'sha256': sha_file(self.run / 'dependency-files.json')})
        with self.assertRaisesRegex(ValueError, 'dependenciesSha256'):
            require_match(before, build_identity(self.run))

    def test_source_edit_is_not_hidden_by_saved_manifest(self):
        (self.run / 'harness/k6/workload.mjs').write_text('changed workload')
        with self.assertRaisesRegex(ValueError, 'Measurement source changed'):
            build_identity(self.run)

    def test_updated_source_manifest_still_requires_recalibration(self):
        before = build_identity(self.run)
        path = self.run / 'harness/k6/workload.mjs'
        path.write_text('changed workload')
        manifest = self.read('harness-manifest.json')
        manifest['k6/workload.mjs'] = sha_file(path)
        self.write('harness-manifest.json', manifest)
        with self.assertRaisesRegex(ValueError, 'sources'):
            require_match(before, build_identity(self.run))

    def test_budget_runner_and_fixture_changes_each_block_comparison(self):
        for name, change in (
            ('profile.json', lambda x: x['resources']['application'].update(heapMiB=x['resources']['application']['heapMiB'] + 512)),
            ('host.json', lambda x: x.update(runnerImageVersion='20261001.1')),
            ('fixtures/fixture-manifest.json', lambda x: x.update(sqlSha256='seed-b')),
            ('generator.json', lambda x: x.update(image='sha256:new-k6')),
        ):
            with self.subTest(name=name):
                original = self.read(name)
                before = build_identity(self.run)
                changed = copy.deepcopy(original)
                change(changed)
                self.write(name, changed)
                with self.assertRaisesRegex(ValueError, 'recalibration required'):
                    require_match(before, build_identity(self.run))
                self.write(name, original)

    def test_local_or_missing_runtime_evidence_cannot_be_a_ci_baseline(self):
        host = self.read('host.json')
        host['runnerImageVersion'] = None
        self.write('host.json', host)
        with self.assertRaisesRegex(ValueError, 'CI runner identity'):
            build_identity(self.run)

    def test_forged_identity_digest_is_rejected(self):
        before = build_identity(self.run)
        after = copy.deepcopy(before)
        after['values']['runtime']['arguments'] = '-Xmx2g'
        with self.assertRaisesRegex(ValueError, 'checksum mismatch'):
            require_match(before, after)

    def test_new_profile_controls_cannot_be_silently_excluded(self):
        profile = copy.deepcopy(PROFILE)
        profile['newInstrumentation'] = True
        with self.assertRaisesRegex(ValueError, 'Unrecognized'):
            profile_identity(profile)

    def test_fanout_change_requires_new_measurement_identity(self):
        before = build_identity(self.run)
        changed = copy.deepcopy(PROFILE)
        changed['fixtures']['highFanoutComments'] = 180
        with self.assertRaisesRegex(ValueError, 'recalibration required: profile'):
            require_match(before, build_identity(self.run, profile=changed))
        historical = copy.deepcopy(PROFILE)
        historical.pop('fixtures')
        self.assertNotIn('fixtures', profile_identity(historical))

    def test_first_commandbox_initialization_does_not_change_version_identity(self):
        before = build_identity(self.run)
        log = self.run / 'seed-commandbox-version.log'
        log.write_text('Configuring CommandBox home: /home/runner/.CommandBox (change with -CommandBox_home=/path/to/dir)\n'
                       'Library path: /home/runner/.CommandBox/lib\n'
                       'Initializing libraries -- this will only happen once, and takes a few seconds...\n'
                       '...\nLibraries initialized\nCommandBox 6.3.5+00887\n')
        require_match(before, build_identity(self.run))
        self.assertIn('Libraries initialized', log.read_text())
        log.write_text('CommandBox 6.3.6+00999\n')
        with self.assertRaisesRegex(ValueError, 'recalibration required: seedCommandBox'):
            require_match(before, build_identity(self.run))

    def test_commandbox_version_must_be_unambiguous(self):
        for text in ('Libraries initialized\n', 'CommandBox 6.3.5+00887\nCommandBox 6.3.6+00999\n'):
            with self.subTest(text=text):
                (self.run / 'seed-commandbox-version.log').write_text(text)
                with self.assertRaisesRegex(ValueError, 'exactly one seed CommandBox version'):
                    build_identity(self.run)

    def test_only_one_page_of_host_memory_reporting_variance_is_allowed(self):
        host = self.read('host.json')
        host['docker']['MemTotal'] = 16722006016
        self.write('host.json', host)
        before = build_identity(self.run)
        for difference in (-4096, 0, 4096):
            host['docker']['MemTotal'] = 16722006016 + difference
            self.write('host.json', host)
            after = build_identity(self.run)
            self.assertEqual(require_match(before, after)['hostMemoryDifferenceBytes'], difference)
            self.assertEqual(after['values']['host']['docker']['MemTotal'], 16722006016 + difference)
        host['docker']['MemTotal'] += 1
        self.write('host.json', host)
        with self.assertRaisesRegex(ValueError, 'recalibration required: host'):
            require_match(before, build_identity(self.run))
        host['docker']['MemTotal'] = 16722006016 + 4096
        for key in ('Model name', 'L2 cache', 'L3 cache'):
            changed = copy.deepcopy(host)
            next(row for row in changed['cpu']['lscpu'] if row['field'] == key + ':')['data'] = 'different'
            self.write('host.json', changed)
            with self.assertRaisesRegex(ValueError, 'recalibration required: host'):
                require_match(before, build_identity(self.run))
        self.write('host.json', host)
        profile = copy.deepcopy(PROFILE)
        profile['resources']['application']['heapMiB'] += 1
        with self.assertRaisesRegex(ValueError, 'recalibration required'):
            require_match(before, build_identity(self.run, profile=profile))

    def test_full_trial_cannot_be_shortened_or_weakened(self):
        validate_trial_profile(PROFILE)
        for key, value in (('plateauSeconds', 180), ('minimumLatencySamples', 199),
                           ('minimumFailuresPerCase', 99), ('shortDevelopment', True), ('capacityProbe', True)):
            with self.subTest(key=key):
                profile = copy.deepcopy(PROFILE)
                profile['workload'][key] = value
                with self.assertRaises(ValueError):
                    validate_trial_profile(profile)


if __name__ == '__main__':
    unittest.main()
