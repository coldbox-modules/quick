"""Evaluate independent JVM, application, database, and container observations.

Hard failures win over incomplete evidence. Ordinary RSS/committed-heap growth
is reported separately and never substituted for retained-heap observations.
"""
import math
import statistics

MIB = 1024 * 1024


def result(failures, invalid, warnings, **evidence):
    return {'status': 'failed' if failures else 'inconclusive' if invalid else 'passed',
            'failures': sorted(set(failures)), 'invalid': sorted(set(invalid)),
            'warnings': sorted(set(warnings)), **evidence}


def coverage(rows, start, end, gap, label):
    times = sorted(set(r['time'] for r in rows if start - gap <= r['time'] <= end + gap))
    if not times:
        return [label + ':missing']
    invalid = []
    if times[0] > start + gap or times[-1] < end - gap:
        invalid.append(label + ':incomplete-span')
    if any(b - a > gap for a, b in zip(times, times[1:]) if b > start and a < end):
        invalid.append(label + ':telemetry-gap')
    return invalid


def pause_windows(rows, start, end, window_ms, exclude_initial_ms=0):
    intervals = sorted(set((r['time'], r['time'] + r['durationMs']) for r in rows if r.get('kind') == 'pause'))
    # Top-level pauses can be duplicated in imported evidence. Union intervals
    # before splitting at boundaries, never double-counting stop-the-world time.
    merged = []
    for left, right in intervals:
        if merged and left <= merged[-1][1]:
            merged[-1][1] = max(merged[-1][1], right)
        else:
            merged.append([left, right])
    windows = []
    for i in range(int((end - start) / window_ms)):
        left, right = max(start + i * window_ms, start + exclude_initial_ms), start + (i + 1) * window_ms
        paused = sum(max(0, min(b, right) - max(a, left)) for a, b in merged)
        cycles = [r for r in rows if r.get('kind') == 'gc' and r.get('name') in ('Z', 'ZGC Major') and left <= r['time'] < right]
        minor = [r for r in rows if r.get('kind') == 'gc' and r.get('name') == 'ZGC Minor' and left <= r['time'] < right]
        windows.append({'index': i, 'pauseMs': paused, 'observedMs': right - left,
                        'pauseFraction': paused / (right - left), 'completedCycles': len(cycles),
                        'cycleElapsedMs': sum(r['durationMs'] for r in cycles),
                        'minorCycles': len(minor), 'minorCycleElapsedMs': sum(r['durationMs'] for r in minor)})
    return windows


def evaluate(jvm, observations, profile, timing, *, plateau_start, exits=None, finalized=True):
    failures, invalid, warnings = [], [], []
    for role, state in (exits or {}).items():
        if state.get('OOMKilled'):
            (failures if role in ('app', 'mysql') else invalid).append('oom:' + role)
    if any(row.get('application', {}).get('errors', {}).get('unexpected', 0) for row in observations):
        failures.append('unexpected-application-exception')
    w, limits = profile['workload'], profile.get('limits', {})
    samples = sorted((r for r in jvm if r.get('kind') == 'sample'), key=lambda r: r['time'])
    observations = sorted(observations, key=lambda r: r['time'])
    required_limits = ('maxTelemetryGapSeconds', 'maxThreads', 'maxDescriptors', 'maxMetaspaceMiB',
                       'maxQueuedRequests', 'maxActiveRequests', 'maxDefinitions', 'maxDerivedBuckets',
                       'maxDerivedEntries', 'recoveryThreadAllowance', 'recoveryDescriptorAllowance')
    if any(key not in limits for key in required_limits):
        return result(failures, [*invalid, 'missing-declared-resource-bounds'], warnings)
    gap = limits['maxTelemetryGapSeconds'] * 1000
    start, idle_start, end = (timing.get(key) for key in ('warmupStartMs', 'idleStartedMs', 'idleFinishedMs'))
    if any(value is None for value in (start, idle_start, end, plateau_start)):
        return result(failures, [*invalid, 'missing-phase-timing'], warnings)
    plateau_end = plateau_start + w['plateauSeconds'] * 1000
    recovery_end = plateau_end + w['recoverySeconds'] * 1000
    if not start < plateau_start < plateau_end <= recovery_end <= idle_start < end:
        invalid.append('invalid-phase-order')
    if end - idle_start < w['idleSeconds'] * 1000:
        invalid.append('abbreviated-idle-observation')
    if idle_start - recovery_end > (w['drainSeconds'] + w['sampleSeconds'] * 2 + 5) * 1000:
        invalid.append('unbounded-phase-drain')
    invalid += coverage(samples, start, end, gap, 'jvm')
    invalid += coverage(observations, start, end, gap, 'application-resources')
    runtime = [r for r in jvm if r.get('kind') == 'runtime']
    if len(runtime) != 1 or not runtime[0].get('javaVersion', '').startswith(profile['runtime']['java']):
        invalid.append('runtime-version-mismatch')
    if any(r.get('kind') == 'collectorError' for r in jvm) or (finalized and not any(r.get('kind') == 'collectorEnd' for r in jvm)):
        invalid.append('collector-incomplete')
    for r in jvm:
        if r.get('kind') in ('pause', 'gc') and (not math.isfinite(r.get('durationMs', -1)) or r.get('durationMs', -1) < 0):
            invalid.append('invalid-gc-duration')
    for a, b in zip(samples, samples[1:]):
        if b['uptimeMs'] <= a['uptimeMs']:
            failures.append('jvm-restarted')
    for sample in samples:
        if any(sample.get(key, -1) < 0 for key in ('threads', 'descriptors', 'metaspaceUsed', 'rssBytes', 'processCpuTimeNs')):
            invalid.append('missing-os-jvm-metric')
        if sample.get('heapMax') != profile['resources']['application']['heapMiB'] * MIB:
            invalid.append('heap-budget-mismatch')
        for field, maximum in (('threads', limits['maxThreads']), ('descriptors', limits['maxDescriptors']),
                               ('metaspaceUsed', limits['maxMetaspaceMiB'] * MIB)):
            if sample.get(field, 0) > maximum:
                failures.append('resource-bound:' + field)
    boot_ids, starts = set(), set()
    pressure_since, prior_time = None, None
    cpu = {role: [] for role in ('application', 'mysql', 'generator', 'collector')}
    memory = {role: [] for role in cpu}
    for row in observations:
        if any(key.endswith('Error') for key in row):
            invalid.append('observation-error')
        app = row.get('application', {})
        required = ('bootId', 'applicationStarts', 'uptimeMs', 'jdbcActive', 'jdbcIdle', 'jdbcWaiting',
                    'activeRequests', 'queuedRequests', 'scratchPosts', 'registry', 'errors')
        if any(key not in app for key in required):
            invalid.append('missing-application-metric')
            continue
        boot_ids.add(app['bootId']); starts.add(app['applicationStarts'])
        if app['errors'].get('unexpected', 0):
            failures.append('unexpected-application-exception')
        if app.get('parallelEagerLoading') is not profile['runtime']['parallelEagerLoading']:
            invalid.append('eager-loading-mode-mismatch')
        if profile['runtime']['parallelEagerLoading']:
            executor = app.get('executor', {})
            fields = ('maxThreads', 'poolSize', 'active', 'queued', 'queueCapacity', 'completed')
            if any(type(executor.get(key)) not in (int, float) or not math.isfinite(executor[key]) or executor[key] < 0 for key in fields):
                invalid.append('missing-executor-metric')
            else:
                threads = profile['runtime']['parallelEagerLoadingMaxThreads']
                capacity = profile['runtime']['parallelEagerLoadingQueueCapacity']
                if executor['maxThreads'] != threads or executor['queueCapacity'] != capacity:
                    failures.append('executor-configuration-mismatch')
                if executor['poolSize'] > threads or executor['active'] > threads or executor['queued'] > capacity:
                    failures.append('executor-resource-bound')
        pool = profile['resources']['application']['jdbcPoolLimit']
        if app['jdbcActive'] + app['jdbcIdle'] > pool:
            failures.append('jdbc-pool-bound')
        for field, maximum in (('queuedRequests', limits['maxQueuedRequests']), ('activeRequests', limits['maxActiveRequests'])):
            if app[field] > maximum:
                failures.append('resource-bound:' + field)
        registry = app['registry']
        for field, maximum in (('definitionCount', limits['maxDefinitions']), ('derivedBucketCount', limits['maxDerivedBuckets']),
                               ('derivedEntryCount', limits['maxDerivedEntries'])):
            if field not in registry:
                invalid.append('missing-registry-metric')
            elif registry[field] > maximum:
                failures.append('registry-bound:' + field)
        if any(field not in row.get('database', {}) for field in ('queries', 'queryTimePicoseconds', 'locks', 'lockWaits')):
            invalid.append('missing-database-metric')
        found = set()
        for item in row.get('containers', []):
            role = {'app': 'application', 'mysql': 'mysql', 'k6': 'generator', 'collector': 'collector'}.get(item.get('Name', '').rsplit('-', 1)[-1])
            if not role:
                continue
            found.add(role)
            try:
                usage = float(item['MemPerc'].rstrip('%'))
                used_cpu = float(item['CPUPerc'].rstrip('%')) / (100 * profile['resources'][role]['cpus'])
                if not all(math.isfinite(x) and x >= 0 for x in (usage, used_cpu)):
                    raise ValueError('Invalid container percentage')
                memory[role].append((row['time'], usage))
                cpu[role].append((row['time'], used_cpu))
                if role == 'application':
                    if usage > 90:
                        if pressure_since is None or prior_time is None or row['time'] - prior_time > gap:
                            pressure_since = row['time']
                        if row['time'] - pressure_since >= 120000:
                            failures.append('sustained-memory-headroom-exhaustion')
                    else:
                        pressure_since = None
                    prior_time = row['time']
            except (KeyError, ValueError, TypeError):
                invalid.append('invalid-container-metric')
        if found != set(cpu):
            invalid.append('missing-container-metric')
    if len(boot_ids) > 1 or (starts and starts != {1}):
        failures.append('application-lifecycle-changed')
    elif not boot_ids:
        invalid.append('missing-lifecycle-evidence')
    if pressure_since is not None and prior_time - pressure_since < 120000:
        invalid.append('late-memory-headroom-needs-observation')
    app_rows = [r for r in observations if 'application' in r and 'uptimeMs' in r['application']]
    if any(b['application']['uptimeMs'] <= a['application']['uptimeMs'] for a, b in zip(app_rows, app_rows[1:])):
        failures.append('application-uptime-fell')
    # Once the bounded drain ends, every idle sample must be free of borrowed
    # connections, queued work, scratch rows and database lock waits.
    idle = [r for r in observations if idle_start <= r['time'] <= end]
    if len(idle) < max(2, int(w['idleSeconds'] / limits['maxTelemetryGapSeconds'])):
        invalid.append('insufficient-idle-observations')
    for row in idle:
        app = row.get('application', {})
        for field in ('jdbcActive', 'jdbcWaiting', 'queuedRequests', 'scratchPosts'):
            if app.get(field, 0):
                failures.append('idle-resource-not-released:' + field)
        if app.get('activeRequests', 1) > 1:
            failures.append('idle-requests-did-not-drain')
        if profile['runtime']['parallelEagerLoading']:
            for field in ('active', 'queued'):
                if app.get('executor', {}).get(field, 0):
                    failures.append('idle-executor-not-released:' + field)
        if row.get('database', {}).get('lockWaits', 0):
            failures.append('idle-database-lock-waits')
    if profile['runtime']['parallelEagerLoading']:
        parallel_rows = [r['application'].get('executor', {}) for r in app_rows if plateau_start <= r['time'] <= plateau_end]
        completed = [r['completed'] for r in parallel_rows if isinstance(r.get('completed'), (int, float))]
        if len(completed) < 2 or completed[-1] <= completed[0]:
            invalid.append('parallel-work-not-observed')
        elif any(b < a for a, b in zip(completed, completed[1:])):
            failures.append('executor-counter-reset')
    reference_end = plateau_start + min(600000, w['plateauSeconds'] * 1000 / 2)
    early = [r for r in samples if plateau_start + w['drainSeconds'] * 1000 <= r['time'] < reference_end]
    idle_jvm = [r for r in samples if idle_start <= r['time'] <= end]
    recovery = {}
    for field, allowance in (('threads', limits['recoveryThreadAllowance']), ('descriptors', limits['recoveryDescriptorAllowance'])):
        if not early or not idle_jvm:
            invalid.append('missing-resource-recovery-comparison')
            continue
        reference = statistics.median(r[field] for r in early)
        recovered = statistics.median(r[field] for r in idle_jvm)
        recovery[field] = {'earlyMedian': reference, 'idleMedian': recovered, 'allowance': allowance}
        if recovered > reference + allowance:
            failures.append('resource-did-not-recover:' + field)
    for role, state in (exits or {}).items():
        if state.get('OOMKilled'):
            (failures if role in ('app', 'mysql') else invalid).append('oom:' + role)
        if role in ('collector', 'k6') and state.get('ExitCode') != 0:
            invalid.append('process-incomplete:' + role)
    windows = pause_windows([r for r in jvm if math.isfinite(r.get('durationMs', 0)) and r.get('durationMs', 0) >= 0], plateau_start, plateau_end,
                            w['windowSeconds'] * 1000, w['drainSeconds'] * 1000)
    consecutive = 0
    for window in windows:
        if window['pauseFraction'] > 0.05:
            warnings.append('gc-pressure-warning:' + str(window['index']))
        consecutive = consecutive + 1 if window['pauseFraction'] > 0.1 else 0
        if consecutive >= 3:
            failures.append('sustained-gc-pressure')
    if 0 < consecutive < 3 and 'sustained-gc-pressure' not in failures:
        invalid.append('late-gc-pressure-needs-observation')
    resource_summary = {}
    for role in cpu:
        plateau_cpu = [v for t, v in cpu[role] if plateau_start <= t < plateau_end]
        plateau_memory = [v for t, v in memory[role] if plateau_start <= t < plateau_end]
        resource_summary[role] = {'medianCpuBudgetFraction': statistics.median(plateau_cpu) if plateau_cpu else None,
                                  'maxMemoryPercent': max(plateau_memory) if plateau_memory else None,
                                  'saturatedSamples': sum(v >= 0.9 for v in plateau_cpu), 'samples': len(plateau_cpu)}
    return result(failures, invalid, warnings, gcWindows=windows, recovery=recovery, containers=resource_summary,
                  bootIds=sorted(boot_ids), sampleCount=len(samples), observationCount=len(observations), finalized=finalized)
