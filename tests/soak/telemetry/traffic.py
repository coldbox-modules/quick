"""Streaming fixed-window analysis of k6 observations; never retain response bodies.

Latency histograms round upward to the nearest millisecond. This bounds storage
by the declared request timeout, operation set, and comparison-window count.
"""
from collections import Counter, defaultdict
import datetime
import math

CASES = ('missing_pk', 'empty_lookup', 'relationship', 'invalid_write', 'rollback')
JOURNEYS = ('browse', 'detail', 'graph', 'write', 'report', 'variant', *CASES)
BASE_OPERATIONS = ('browse', 'user_detail', 'graph', 'post_create', 'post_read', 'post_update',
                   'post_read_updated', 'post_delete', 'scratch_verify',
                   'query_variant', 'lookup_recovery', 'relationship_recovery')


def report_sizes(workload):
    sizes = workload.get('reportSizes', [100, 500, 1000])
    if (not isinstance(sizes, list) or len(sizes) != 3 or
            any(type(size) is not int or size not in (25, 100, 250, 500, 1000) for size in sizes)
            or sizes != sorted(set(sizes))):
        raise ValueError('reportSizes requires three distinct ascending supported row limits')
    return sizes


def operation_names(workload):
    return (*BASE_OPERATIONS, *(f'report_{size}' for size in report_sizes(workload)))


OPERATIONS = operation_names({})  # Historical profiles retain their original operation set.


def percentile(histogram, percentile=95):
    count = sum(histogram.values())
    if not count:
        return None
    target = math.ceil(count * percentile / 100)
    total = 0
    for value, frequency in sorted(histogram.items()):
        total += frequency
        if total >= target:
            return value


def timestamp(value):
    return datetime.datetime.fromisoformat(value.replace('Z', '+00:00')).timestamp() * 1000


def evaluate(points, workload, baseline=None):
    operations = operation_names(workload)
    windows_count = workload['plateauSeconds'] // workload['windowSeconds']
    windows = [defaultdict(Counter) for _ in range(windows_count)]
    totals = defaultdict(Counter)
    latency = [defaultdict(Counter) for _ in range(windows_count)]
    epoch = None
    phase_starts = {}
    invalid, failures, warnings = [], [], []
    unexpected = 0
    boundary_arrivals = 0
    for point in points:
        if point.get('type') != 'Point':
            continue
        metric, data = point['metric'], point['data']
        tags, value = data.get('tags', {}), data['value']
        if metric == 'unexpected_errors' and value:
            unexpected += value
        if metric == 'checks' and value != 1:
            failures.append('incorrect-response-contract')
        if metric == 'http_req_failed' and value:
            failures.append('unexpected-http-failure')
        if metric == 'journey_started':
            phase = tags.get('scenario')
            phase_epoch = float(tags['phaseStart'])
            if phase in phase_starts and phase_starts[phase] != phase_epoch:
                invalid.append('scenario-clock-changed:' + phase)
            phase_starts[phase] = phase_epoch
        if tags.get('scenario') != 'plateau':
            continue
        if metric == 'journey_started':
            observed_epoch = float(tags['phaseStart'])
            if epoch is not None and observed_epoch != epoch:
                invalid.append('plateau-clock-changed')
            epoch = observed_epoch
        if epoch is None:
            # k6 emits journey_started before each journey's requests. A missing
            # clock invalidates evidence rather than guessing from launch time.
            invalid.append('missing-plateau-clock')
            continue
        at = timestamp(data['time'])
        if metric == 'journey_started':
            end = epoch + workload['plateauSeconds'] * 1000
            if end - 1 <= at <= end + 1000 / workload['rate']:
                boundary_arrivals += value
        index = int((at - epoch) // (1000 * workload['windowSeconds']))
        window = windows[index] if 0 <= index < windows_count else None
        if metric in ('journey_started', 'journey_completed'):
            label = tags.get('journey', '')
        elif metric in ('expected_failure_attempted', 'expected_failure_verified', 'followup_succeeded'):
            label = tags.get('case', '')
        elif metric == 'bucket_completed':
            label = tags.get('bucket', '')
        elif metric == 'operation_completed':
            label = tags.get('operation', '')
        else:
            label = 'all'
        if metric in ('journey_started', 'journey_completed', 'expected_failure_attempted', 'expected_failure_verified',
                      'followup_succeeded', 'bucket_completed', 'operation_completed', 'dropped_iterations', 'http_reqs'):
            totals[metric][label] += value
            if window is not None:
                window[metric][label] += value
        if metric in ('successful_latency', 'expected_failure_latency') and window is not None:
            operation = tags.get('operation') if metric == 'successful_latency' else 'failure:' + tags.get('case', '')
            if operation not in operations and operation not in ['failure:' + c for c in (*CASES, 'post_delete')]:
                invalid.append('unknown-latency-operation')
                continue
            if not math.isfinite(value) or value < 0 or value > workload['requestTimeoutSeconds'] * 1000:
                invalid.append('latency-outside-declared-timeout')
                continue
            # Discard requests straddling a comparison boundary. A response from
            # an earlier window must not pollute the next window's percentile.
            if at - value >= max(epoch + index * workload['windowSeconds'] * 1000,
                                 epoch + workload.get('drainSeconds', 0) * 1000):
                latency[index][operation][math.ceil(value)] += 1
    if unexpected:
        failures.append('unexpected-errors')
    if epoch is None:
        invalid.append('missing-plateau')
    nominal = workload['rate'] * workload['plateauSeconds']
    started, completed = sum(totals['journey_started'].values()), sum(totals['journey_completed'].values())
    offered = started + totals['dropped_iterations']['all']
    # k6 v1.3.0 selects between an arrival timer and duration cancellation.
    # Both can be ready at the end boundary, admitting one final arrival.
    # Count it as real offered work, require completion, and exclude its latency
    # from the finished plateau windows. This never excuses a missing arrival.
    boundary_extra = started == nominal + 1 and boundary_arrivals == 1
    if boundary_extra:
        warnings.append('one-completed-arrival-at-duration-boundary')
    if (started != nominal and not boundary_extra) or completed != started or totals['dropped_iterations']['all']:
        invalid.append('traffic-shortfall-needs-resource-classification')
    for case in CASES:
        count = totals['expected_failure_verified'][case]
        if count < workload['minimumFailuresPerCase']:
            failures.append('insufficient-failure-coverage:' + case)
        if count != totals['expected_failure_attempted'][case] or count != totals['followup_succeeded'][case]:
            failures.append('failure-or-recovery-incomplete:' + case)
    for i, window in enumerate(windows):
        for case in CASES:
            if window['expected_failure_verified'][case] < 1:
                failures.append(f'missing-failure-window:{i}:{case}')
        for journey in JOURNEYS:
            if window['journey_started'][journey] < 1:
                failures.append(f'missing-journey-window:{i}:{journey}')
        for bucket in ('browse_25', 'browse_100', *(f'report_{size}' for size in report_sizes(workload)), *(f'variant_{i}' for i in range(32) if not workload.get('shortDevelopment') and not workload.get('capacityProbe'))):
            if window['bucket_completed'][bucket] < 1:
                failures.append(f'missing-bucket-window:{i}:{bucket}')
    for i in range(32):
        if totals["bucket_completed"][f"variant_{i}"] < 1:
            failures.append(f"missing-query-variant:{i}")
    comparisons = {}
    for operation in (*operations, *('failure:' + c for c in (*CASES, 'post_delete'))):
        histograms = [window[operation] for window in latency]
        values = [percentile(histogram) for histogram in histograms]
        counts = [sum(histogram.values()) for histogram in histograms]
        if any(count < workload['minimumLatencySamples'] for count in counts):
            invalid.append('insufficient-latency-samples:' + operation)
        early = Counter()
        late = Counter()
        early_windows = max(1, 600 // workload['windowSeconds']) if not workload.get('shortDevelopment') and not workload.get('capacityProbe') else 1
        for histogram in histograms[:early_windows]:
            early.update(histogram)
        for histogram in histograms[-early_windows:]:
            late.update(histogram)
        reference = percentile(early)
        accepted = (baseline or {}).get(operation, {})
        references = [r for r in (reference, accepted.get('p95Ms')) if r is not None]
        consecutive = 0
        for i, value in enumerate(values):
            above = value is not None and any(value > ref * 1.2 and value - ref >= 50 for ref in references)
            consecutive = consecutive + 1 if above else 0
            if value is not None and any(value > ref * 1.1 for ref in references):
                warnings.append(f'latency-warning:{operation}:{i}')
            if consecutive >= 3:
                failures.append('sustained-latency-regression:' + operation)
            if value is not None and accepted.get('absoluteBudgetMs') is not None and value > accepted['absoluteBudgetMs']:
                failures.append(f'absolute-latency-budget:{operation}:{i}')
        if 0 < consecutive < 3 and 'sustained-latency-regression:' + operation not in failures:
            invalid.append('late-latency-regression-needs-observation:' + operation)
        comparisons[operation] = {'counts': counts, 'p95Ms': values, 'earlyP95Ms': reference,
                                  'lateP95Ms': percentile(late), 'baseline': accepted}
    return {'status': 'failed' if failures else 'inconclusive' if invalid else 'passed',
            'failures': sorted(set(failures)), 'invalid': sorted(set(invalid)), 'warnings': sorted(set(warnings)),
            'plateauStartMs': epoch, 'phaseStartsMs': phase_starts,
            'offeredJourneys': offered, 'nominalOfferedJourneys': nominal, 'startedJourneys': started,
            'completedJourneys': completed, 'totals': dict(totals), 'windows': [dict(window) for window in windows],
            'latency': comparisons, 'quantizationMs': 1}
