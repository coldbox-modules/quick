"""Attribute undelivered arrivals without converting missing evidence into a pass."""
import math

SHORTFALL = 'traffic-shortfall-needs-resource-classification'
COVERAGE = ('failure-or-recovery-incomplete:', 'insufficient-failure-coverage:',
            'missing-bucket-window:', 'missing-failure-window:', 'missing-journey-window:', 'missing-query-variant:')


def evaluate(traffic, observations, profile, generator_exit):
    hard = [reason for reason in traffic['failures'] if not reason.startswith(COVERAGE)]
    shortfall = SHORTFALL in traffic['invalid']
    exit_bad = generator_exit.get('ExitCode') != 0 or generator_exit.get('OOMKilled')
    if not shortfall and (not exit_bad or traffic['status'] == 'failed'):
        return {'status': traffic['status'], 'reasons': traffic['failures'] + traffic['invalid'], 'windows': []}
    w = profile['workload']
    start = traffic.get('plateauStartMs')
    evidence = []
    if start is not None:
        for index, window in enumerate(traffic['windows']):
            starts = sum(window.get('journey_started', {}).values())
            completes = sum(window.get('journey_completed', {}).values())
            drops = sum(window.get('dropped_iterations', {}).values())
            if not drops and starts >= w['rate'] * w['windowSeconds'] and completes >= starts:
                continue
            lower, upper = start + index * w['windowSeconds'] * 1000, start + (index + 1) * w['windowSeconds'] * 1000
            rows = sorted((row for row in observations if lower <= row['time'] < upper), key=lambda row: row['time'])
            streak = {'generator': 0, 'application': 0}
            sustained = {'generator': False, 'application': False}
            samples = []
            previous = None
            for row in rows:
                values = {}
                for container in row.get('containers', []):
                    role = {'app': 'application', 'mysql': 'mysql', 'k6': 'generator'}.get(container.get('Name', '').rsplit('-', 1)[-1])
                    if not role:
                        continue
                    try:
                        cpu = float(container['CPUPerc'].rstrip('%')) / (100 * profile['resources'][role]['cpus'])
                        if math.isfinite(cpu) and cpu >= 0:
                            values[role] = cpu
                    except (KeyError, ValueError, TypeError):
                        pass
                app = row.get('application', {})
                complete = set(values) == {'generator', 'application', 'mysql'}
                pressure = {'generator': values.get('generator', 0) >= .9,
                    'application': values.get('application', 0) >= .9 or values.get('mysql', 0) >= .9
                        or app.get('jdbcWaiting', 0) > 0 or app.get('queuedRequests', 0) > 0
                        or row.get('database', {}).get('lockWaits', 0) > 0}
                for role in streak:
                    if previous is None or row['time'] - previous > profile['limits']['maxTelemetryGapSeconds'] * 1000:
                        streak[role] = 0
                    streak[role] = streak[role] + 1 if complete and pressure[role] else 0
                    sustained[role] |= streak[role] >= 3
                samples.append({'time': row['time'], 'cpuBudgetFraction': values, 'pressure': pressure})
                previous = row['time']
            evidence.append({'index': index, 'starts': starts, 'completed': completes, 'dropped': drops,
                             'sustained': sustained, 'samples': samples})
    generator = generator_exit.get('OOMKilled', False) or any(x['sustained']['generator'] for x in evidence)
    application = any(x['sustained']['application'] for x in evidence)
    if generator and application:
        status, reason = 'inconclusive', 'delivery-both-application-and-generator-saturated'
    elif generator:
        status, reason = 'inconclusive', 'delivery-generator-capacity-exhausted'
    elif application:
        status, reason = 'failed', 'delivery-application-overloaded'
    else:
        status, reason = 'inconclusive', 'delivery-cause-unresolved'
    # A proven incorrect response or unexpected HTTP failure remains a hard
    # failure even when generation also saturated. Coverage absent because work
    # was never delivered is evidence of invalidity, not a fabricated contract bug.
    if hard:
        status = 'failed'
    return {'status': status, 'reasons': [*hard, reason], 'windows': evidence,
            'generatorExit': generator_exit, 'missingCoverage': [r for r in traffic['failures'] if r.startswith(COVERAGE)]}
