"""Offline, dependency-free run report from persisted evidence only."""
from collections import Counter
import html
import math
import json
from pathlib import Path

from traffic import percentile

MIB = 1024 * 1024


def document(path, default):
    return json.loads(path.read_text()) if path.exists() else default


def records(path):
    if not path.exists():
        return
    # A canceled stream can have an unfinished final line. This report never
    # determines qualification; raw evidence and analyzer results stay intact.
    with path.open() as stream:
        for line in stream:
            try:
                yield json.loads(line)
            except json.JSONDecodeError:
                continue


def rows(path):
    return list(records(path))


def plateau_latency(path, operations, timeout_ms):
    # Stream request observations into bounded 1 ms histograms, never retaining
    # response bodies or one object per request. Fixed labels come from analysis.
    histograms = {name: Counter() for name in operations}
    excluded = 0
    for row in records(path):
        if row.get('type') != 'Point' or row.get('metric') not in ('successful_latency', 'expected_failure_latency'):
            continue
        data = row['data']
        tags = data.get('tags', {})
        if tags.get('scenario') != 'plateau':
            continue
        name = tags.get('operation') if row['metric'] == 'successful_latency' else 'failure:' + tags.get('case', '')
        value = data['value']
        if (name not in histograms or type(value) not in (int, float)
                or not math.isfinite(value) or not 0 <= value <= timeout_ms):
            excluded += 1
            continue
        histograms[name][math.ceil(value)] += 1
    return {'operations': {name: {'count': sum(hist.values()), 'p99Ms': percentile(hist, 99)}
                           for name, hist in histograms.items()}, 'excluded': excluded}


def window_rates(traffic, workload, complete):
    seconds = workload.get('windowSeconds', 0)
    return [{'window': index + 1,
             'journeysPerSecond': sum(window.get('journey_completed', {}).values()) / seconds if complete and seconds > 0 else None,
             'httpPerSecond': sum(window.get('http_reqs', {}).values()) / seconds if complete and seconds > 0 else None}
            for index, window in enumerate(traffic.get('windows', []))]


def chart(title, points, unit):
    if not points:
        return f'<h2>{html.escape(title)}</h2><p>No observations available.</p>'
    start, end = points[0][0], points[-1][0]
    maximum = max(1, max(value for _, value in points))
    # Preserve peaks and troughs in each display bucket, bounding SVG size.
    stride = max(1, len(points) // 1000)
    displayed = []
    for i in range(0, len(points), stride):
        bucket = points[i:i + stride]
        displayed.extend(sorted({min(bucket, key=lambda p: p[1]), max(bucket, key=lambda p: p[1])}))
    coordinates = ' '.join(f'{55 + (time-start)/max(1,end-start)*875:.1f},{215-value/maximum*175:.1f}' for time, value in displayed)
    return f'''<h2>{html.escape(title)}</h2><div class="chart">
      <p class="chart-range">0–{maximum:.1f} {html.escape(unit)}</p>
      <svg viewBox="45 25 895 200" role="img" aria-label="{html.escape(title)}">
      <path d="M55 35V215H930" fill="none" stroke="#aaa"/>
      <polyline points="{coordinates}" fill="none" stroke="#195fad" stroke-width="2"/></svg>
      <p class="chart-time"><span>0 min</span><span>{(end-start)/60000:.1f} min</span></p></div>'''



def render(directory):
    summary = document(directory / 'summary.json', {'status': 'inconclusive', 'reasons': ['Missing summary']})
    profile = document(directory / 'profile.json', {})
    package = document(directory / 'package/package-manifest.json', {})
    traffic = document(directory / 'traffic-analysis.json', {})
    resources = document(directory / 'resource-analysis.json', {})
    memory = document(directory / 'memory-analysis.json', {})
    capacity = document(directory / 'capacity-analysis.json', {})
    jvm, observations = rows(directory / 'jvm/jvm.ndjson'), rows(directory / 'observations.ndjson')
    parts = ['<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width">',
             '<title>Quick soak evidence</title><style>body{font:16px/1.5 system-ui;max-width:1050px;margin:35px auto;padding:0 20px;color:#202a36}h2{margin-top:2em;font-size:20px}svg{display:block;width:100%}.chart{background:#f5f7fa;padding:10px 12px}.chart p{margin:0}.chart-time{display:flex;justify-content:space-between}table{border-collapse:collapse;width:100%;font-size:14px}th,td{padding:7px;text-align:left;border-bottom:1px solid #ddd}code{overflow-wrap:anywhere}.notice{background:#fff1cc;padding:14px}pre{white-space:pre-wrap}</style>',
             '<h1>Quick soak evidence</h1>',
             ('<p class="notice">Soak qualification passed. Publication still requires a verified qualification receipt and every other required validation job.</p>'
              if summary.get('releaseQualified') and summary['status'] == 'passed' else
              '<p class="notice">Release qualification: <strong>not granted</strong>. Development results, canceled runs, and unaccepted profiles cannot authorize publication.</p>'),
             f'<p>Run <code>{html.escape(summary.get("runId", directory.name))}</code> · <strong>{html.escape(summary["status"])}</strong></p>',
             f'<p>Profile: <code>{html.escape(profile.get("id", "unknown"))}</code><br>Candidate: <code>{html.escape(package.get("candidateSha", "unknown"))}</code><br>Package SHA-256: <code>{html.escape(package.get("packageSha256", "unknown"))}</code></p>']
    parts += ['<ul>' + ''.join('<li>' + html.escape(reason) + '</li>' for reason in summary.get('reasons', [])) + '</ul>']
    if capacity:
        parts.append('<h2>Capacity sweep</h2><p>One application JVM and database remain alive across all stages. Each rate decision precedes the next generator invocation. These short probes do not establish sustained stability.</p><table><tr><th>Journeys/second</th><th>Clean step</th><th>Traffic</th><th>Resources</th><th>Stop reason</th></tr>')
        for step in capacity['steps']:
            parts.append(f'<tr><td>{step["rate"]}</td><td>{step["clean"]}</td><td>{html.escape(step["traffic"])}</td><td>{html.escape(step["resources"])}</td><td>{html.escape(step["stopReason"] or "—")}</td></tr>')
        proposed = capacity['recommendation']
        parts.append(f'</table><p>Proposed target: {proposed["rate"]} journeys/second. Eligible for full trials: {proposed["trialProfileEligible"]}. Baseline acceptance and release qualification remain separate requirements.</p>')
    for label, assessment in (('Resources and recovery', resources), ('Retained memory', memory)):
        if not assessment:
            continue
        parts.append(f'<h2>{label}</h2><p>Assessment: <strong>{html.escape(assessment["status"])}</strong>.</p>')
        for category in ('failures', 'invalid', 'reasons', 'warnings'):
            if assessment.get(category):
                parts.append('<p>' + category.capitalize() + '</p><ul>' + ''.join('<li>' + html.escape(reason) + '</li>' for reason in assessment[category]) + '</ul>')
    if memory and 'earlyMedianBytes' in memory:
        parts.append(f'<p>Early / late post-cycle median: {memory["earlyMedianBytes"]/MIB:.1f} / {memory["lateMedianBytes"]/MIB:.1f} MiB. Growth: {memory["growthBytes"]/MIB:.1f} MiB. Blocking band: {memory["thresholdBytes"]/MIB:.1f} MiB. Observed span: {memory["spanMs"]/60000:.1f} minutes.</p>')
    if resources:
        parts.append('<h2>Resource recovery comparison</h2><table><tr><th>Resource</th><th>Early median</th><th>Idle median</th><th>Recovery allowance</th></tr>')
        for name, item in resources.get('recovery', {}).items():
            parts.append(f'<tr><td>{html.escape(name)}</td><td>{item["earlyMedian"]}</td><td>{item["idleMedian"]}</td><td>{item["allowance"]}</td></tr>')
        parts.append('</table><h2>GC pressure</h2><p>Stop-the-world pause time is compared separately from total collection-cycle elapsed time.</p><table><tr><th>Window</th><th>Stop-the-world time</th><th>Completed cycles</th><th>Collection-cycle elapsed</th></tr>')
        for window in resources.get('gcWindows', []):
            parts.append(f'<tr><td>{window["index"]+1}</td><td>{window["pauseFraction"]*100:.3f}%</td><td>{window["completedCycles"]}</td><td>{window["cycleElapsedMs"]:.1f} ms</td></tr>')
        parts.append('</table>')
    if traffic:
        parts.append(f'<h2>Delivered sustained load</h2><p>Offered: {traffic["offeredJourneys"]:,} journeys. Started: {traffic["startedJourneys"]:,}. Completed: {traffic["completedJourneys"]:,}. Traffic assessment: {html.escape(traffic["status"])}.</p>')
        workload = profile.get('workload', {})
        http_count = sum(traffic['totals'].get('http_reqs', {}).values())
        parts.append(f'<p>Configured target: {workload.get("rate", "unknown")} journeys/second. HTTP requests from plateau journeys, including drain: {http_count:,}.</p>')
        parts.append(f'<p>Rates below count completions inside each {workload.get("windowSeconds", "unknown")}-second plateau window, excluding drain. Rates are unavailable for incomplete runs.</p><table><tr><th>Window</th><th>Journey completions/s</th><th>HTTP completions/s</th></tr>')
        for row in window_rates(traffic, workload, summary.get('state') == 'complete'):
            journey_rate = 'unavailable' if row['journeysPerSecond'] is None else f'{row["journeysPerSecond"]:.2f}'
            http_rate = 'unavailable' if row['httpPerSecond'] is None else f'{row["httpPerSecond"]:.2f}'
            parts.append(f'<tr><td>{row["window"]}</td><td>{journey_rate}</td><td>{http_rate}</td></tr>')
        parts.append('</table>')
        details = plateau_latency(directory / 'k6.ndjson', traffic['latency'], workload.get('requestTimeoutSeconds', 10) * 1000)
        parts.append('<h2>Verified request totals and p99</h2><p>Counts and p99 include all plateau-tagged verified requests, including drain. Successful operations and expected failures remain separate. P99 is descriptive and does not gate release; small sample counts limit its usefulness. Histograms round upward to 1 ms.</p><table><tr><th>Operation</th><th>Verified requests</th><th>p99 (ms)</th></tr>')
        for name, row in details['operations'].items():
            p99 = 'unavailable' if row['p99Ms'] is None else str(row['p99Ms'])
            parts.append(f'<tr><td>{html.escape(name)}</td><td>{row["count"]:,}</td><td>{p99}</td></tr>')
        parts.append('</table>')
        if details['excluded']:
            parts.append(f'<p>Invalid or unknown latency observations excluded from this descriptive table: {details["excluded"]}. See the traffic assessment and raw evidence.</p>')
        parts.append('<h2>Expected failures and recovery</h2><table><tr><th>Case</th><th>Attempted</th><th>Verified</th><th>Recovered</th></tr>')
        for case, count in sorted(traffic['totals'].get('expected_failure_attempted', {}).items()):
            verified = traffic['totals'].get('expected_failure_verified', {}).get(case, 0)
            recovered = traffic['totals'].get('followup_succeeded', {}).get(case, 0)
            parts.append(f'<tr><td>{html.escape(case)}</td><td>{count}</td><td>{verified}</td><td>{recovered}</td></tr>')
        parts.append('</table><h2>Latency by comparison window</h2><p>Each cell shows p95 milliseconds (sample count). Successful operations and expected failures remain separate. Histogram resolution is 1 ms.</p><table><tr><th>Operation</th><th>Windows, in time order</th></tr>')
        for operation, value in traffic['latency'].items():
            cells = ' · '.join(f'{p95 if p95 is not None else "missing"} ({count})' for p95, count in zip(value['p95Ms'], value['counts']))
            parts.append(f'<tr><td>{html.escape(operation)}</td><td>{cells}</td></tr>')
        parts.append('</table>')
        for category in ('failures', 'invalid', 'warnings'):
            if traffic[category]:
                parts.append('<h2>Traffic ' + category + '</h2><ul>' + ''.join('<li>' + html.escape(x) + '</li>' for x in traffic[category]) + '</ul>')
    samples = [row for row in jvm if row.get('kind') == 'sample']
    if any('applicationMemory' in row for row in observations):
        parts.append('<h2>Application cgroup memory</h2><p>These kernel categories explain the container budget separately from JVM heap and process RSS. Shared, mapped, and dirty memory are overlapping subcategories; do not sum the charts. Growth requires investigation and is not automatically a retained-object leak.</p>')
        for field in ('anon', 'file', 'kernel', 'shmem', 'file_mapped', 'file_dirty', 'inactive_file'):
            points = [(row['time'], row['applicationMemory']['bytesAndCounters'][field] / MIB) for row in observations
                      if field in row.get('applicationMemory', {}).get('bytesAndCounters', {})]
            if points:
                parts.append(chart('Cgroup ' + field, points, 'MiB'))
    for field, title, factor, unit in [('heapUsed', 'Heap occupancy', MIB, 'MiB'), ('metaspaceUsed', 'Metaspace', MIB, 'MiB'),
        ('rssBytes', 'Process resident memory (includes ZGC mappings)', MIB, 'MiB'), ('threads', 'JVM threads', 1, 'threads'), ('descriptors', 'Open descriptors', 1, 'descriptors')]:
        parts.append(chart(title, [(r['time'], r[field] / factor) for r in samples if field in r], unit))
    complete = {r['gcId'] for r in jvm if r.get('kind') == 'gc' and r.get('name') in ('Z', 'ZGC Major')}
    parts.append(chart('Occupancy after completed full-heap ZGC cycles', [(r['time'], r['heapUsed'] / MIB) for r in jvm
        if r.get('kind') == 'heap' and r.get('when') == 'After GC' and r['gcId'] in complete], 'MiB'))
    parts.append('<p>Post-cycle occupancy includes concurrent allocations. A short chart cannot establish retained-memory stability or replace the required matched-load analysis.</p>')
    for field, title in [('activeRequests', 'Active application requests (sampled; includes diagnostics)'), ('jdbcActive', 'Borrowed JDBC connections'), ('jdbcWaiting', 'Waiting JDBC borrowers'), ('queuedRequests', 'Queued application requests')]:
        parts.append(chart(title, [(r['time'], r['application'][field]) for r in observations if field in r.get('application', {})], 'count'))
    parts.append('<h2>Raw evidence</h2><p><a href="summary.json">Summary</a> · <a href="traffic-analysis.json">Traffic analysis</a> · <a href="resource-analysis.json">Resource analysis</a> · <a href="memory-analysis.json">Memory analysis</a> · <a href="profile.json">Profile</a> · <a href="harness-manifest.json">Harness identity</a> · <a href="dependencies.json">Dependencies</a> · <a href="jvm/jvm.ndjson">JVM telemetry</a> · <a href="observations.ndjson">Application and resources</a> · <a href="k6.ndjson">k6 observations</a> · <a href="jvm/recording-final.jfr">Final JFR</a></p></html>')
    (directory / 'report.html').write_text('\n'.join(parts))


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', type=Path)
    render(parser.parse_args().directory)
