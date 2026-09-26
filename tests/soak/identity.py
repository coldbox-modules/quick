"""Comparable measurement inputs, separate from package and evidence identities.

A baseline pointer, review metadata, or documentation edit must not recursively
invalidate its own identity. Executed workload and measurement files do. Full
source snapshots remain in the evidence independently of this comparison key.
"""
import hashlib
import json
from pathlib import Path

SOURCE_FILES = {'controller.py', 'Seed.cfc',
                'telemetry/Collector.java', 'telemetry/memory.py',
                'telemetry/resources.py', 'telemetry/traffic.py', 'telemetry/delivery.py', 'telemetry/native.py'}
SOURCE_DIRS = {'app', 'k6', 'fixtures', 'docker'}
DOCKER_FIELDS = ('Architecture', 'NCPU', 'MemTotal', 'KernelVersion', 'ServerVersion',
                 'CgroupDriver', 'CgroupVersion', 'OperatingSystem', 'OSType')
CPU_FIELDS = ('Architecture', 'CPU(s)', 'Vendor ID', 'Model name', 'CPU family', 'Model',
              'Stepping', 'Thread(s) per core', 'Core(s) per socket', 'Socket(s)',
              'L1d cache', 'L1i cache', 'L2 cache', 'L3 cache', 'NUMA node(s)')
JVM_FIELDS = ('javaVersion', 'vm', 'os', 'arch', 'processors', 'physicalMemoryBytes', 'arguments')
PROFILE_FIELDS = ('schema', 'runner', 'architecture', 'runtime', 'images', 'resources', 'workload', 'limits')


def read(path):
    return json.loads(path.read_text())


def sha_file(path):
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':'), allow_nan=False).encode()).hexdigest()


def measured_source(name):
    path = Path(name)
    return name in SOURCE_FILES or path.parts[0] in SOURCE_DIRS


def source_identity(run):
    manifest = read(run / 'harness-manifest.json')
    selected = {name: value for name, value in manifest.items() if measured_source(name)}
    if not SOURCE_FILES <= selected.keys() or any(not any(Path(n).parts[0] == d for n in selected) for d in SOURCE_DIRS):
        raise ValueError('Measurement source snapshot is incomplete')
    for name, expected in selected.items():
        path = (run / 'harness' / name).resolve()
        if not path.is_relative_to((run / 'harness').resolve()) or sha_file(path) != expected:
            raise ValueError('Measurement source changed: ' + name)
    return selected


def profile_identity(profile):
    # Explicit metadata exclusions avoid a self-referential baseline hash.
    unknown = profile.keys() - set(PROFILE_FIELDS) - {'id', 'status', 'acceptedBaseline', 'capacity', 'fault'}
    if unknown or profile.get('fault', 'none') != 'none':
        raise ValueError('Unrecognized or faulted measurement profile')
    return {key: profile[key] for key in PROFILE_FIELDS}


def cpu_identity(cpu):
    if 'lscpu' not in cpu:
        raise ValueError('CI CPU identity is missing')
    values = {item['field'].rstrip(':'): item['data'] for item in cpu['lscpu']}
    if not all(values.get(key) for key in ('Architecture', 'CPU(s)', 'Vendor ID', 'Model name')):
        raise ValueError('CI CPU identity is incomplete')
    return {key: values.get(key) for key in CPU_FIELDS}


def build_identity(run, *, profile=None, generator=None):
    run = Path(run)
    profile = profile or read(run / 'profile.json')
    host = read(run / 'host.json')
    if not host.get('runnerImage') or not host.get('runnerImageVersion') or not host.get('githubRunId'):
        raise ValueError('A baseline requires recorded CI runner identity')
    with (run / 'jvm/jvm.ndjson').open() as stream:
        runtime = next((json.loads(line) for line in stream if line.strip()), None)
    if not runtime or runtime.get('kind') != 'runtime':
        raise ValueError('JVM runtime identity is missing')
    runtime = {**{key: runtime[key] for key in JVM_FIELDS}, 'collectors': sorted(runtime['collectors'].split(','))}
    initial = read(run / 'initial-diagnostics.json')
    application = {key: initial[key] for key in ('luceeVersion', 'coldboxVersion', 'appName', 'exceptionHandler')}
    if application['luceeVersion'] != profile['runtime']['lucee'].replace('+', '.'):
        raise ValueError('Installed Lucee version differs from profile')
    dependencies = read(run / 'dependency-files.json')
    if not dependencies or read(run / 'dependency-identity.json')['sha256'] != sha_file(run / 'dependency-files.json'):
        raise ValueError('Dependency file identity is incomplete or changed')
    containers = {}
    for row in read(run / 'runtime-containers.json'):
        role = row['name'].rsplit('-', 1)[-1]
        if role in containers or role not in ('app', 'mysql', 'collector'):
            raise ValueError('Unexpected runtime container identity')
        containers[role] = {key: row[key] for key in ('image', 'limits')}
    if set(containers) != {'app', 'mysql', 'collector'}:
        raise ValueError('Runtime container identity is incomplete')
    containers['k6'] = generator or read(run / 'generator.json')
    values = {'schema': 2, 'profile': profile_identity(profile),
              'sources': source_identity(run), 'dependenciesSha256': digest(dependencies),
              'fixturesSha256': digest(read(run / 'fixtures/fixture-manifest.json')),
              'runtime': runtime, 'application': application, 'containers': containers,
              'host': {'docker': {key: host['docker'][key] for key in DOCKER_FIELDS},
                       'cpu': cpu_identity(host['cpu']), 'runnerImage': host['runnerImage'],
                       'runnerImageVersion': host['runnerImageVersion']},
              'seedCommandBox': (run / 'seed-commandbox-version.log').read_text().strip()}
    return {'sha256': digest(values), 'values': values}


def require_match(expected, actual):
    if digest(expected['values']) != expected['sha256'] or digest(actual['values']) != actual['sha256']:
        raise ValueError('Measurement identity checksum mismatch')
    if expected['sha256'] != actual['sha256']:
        changed = sorted(key for key in expected['values'].keys() | actual['values'].keys()
                         if expected['values'].get(key) != actual['values'].get(key))
        raise ValueError('Measurement inputs changed; recalibration required: ' + ', '.join(changed))
