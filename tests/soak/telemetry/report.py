"""Offline, dependency-free run report from persisted evidence only."""
import html
import json
from pathlib import Path

MIB = 1024 * 1024


def document(path, default):
    return json.loads(path.read_text()) if path.exists() else default


def rows(path):
    if not path.exists():
        return []
    # Cancellation can leave one unfinished final line. Preserve the raw file;
    # charts may show complete earlier observations without declaring a pass.
    result = []
    with path.open() as stream:
        for line in stream:
            try:
                result.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return result


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
    for field, title in [('jdbcActive', 'Borrowed JDBC connections'), ('jdbcWaiting', 'Waiting JDBC borrowers'), ('queuedRequests', 'Queued application requests')]:
        parts.append(chart(title, [(r['time'], r['application'][field]) for r in observations if field in r.get('application', {})], 'count'))
    parts.append('<h2>Raw evidence</h2><p><a href="summary.json">Summary</a> · <a href="traffic-analysis.json">Traffic analysis</a> · <a href="resource-analysis.json">Resource analysis</a> · <a href="memory-analysis.json">Memory analysis</a> · <a href="profile.json">Profile</a> · <a href="harness-manifest.json">Harness identity</a> · <a href="dependencies.json">Dependencies</a> · <a href="jvm/jvm.ndjson">JVM telemetry</a> · <a href="observations.ndjson">Application and resources</a> · <a href="k6.ndjson">k6 observations</a> · <a href="jvm/recording-final.jfr">Final JFR</a></p></html>')
    (directory / 'report.html').write_text('\n'.join(parts))


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', type=Path)
    render(parser.parse_args().directory)
