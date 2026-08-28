# Quick performance benchmarks

This opt-in suite measures Quick outside the normal TestBox run. It reports
median, p95, and standard deviation for wall-clock time, JVM thread CPU time,
and bytes allocated on the benchmark thread. It also includes directional
post-GC retained-heap probes.

The suite currently covers warmed entity creation, the internal shallow
construction boundary, single and batch hydration, attribute reads and writes,
attribute snapshots, clean dirty checks, memento serialization, builder
creation and cloning, SQL composition, relationship construction, and
raw-versus-hydrated database fetches.

## Run a benchmark

Start one of the normal Quick test servers and initialize the test database if
needed:

```bash
box server start serverConfigFile=server-lucee@6.json --noSaveSettings
curl -fsS 'http://127.0.0.1:60299/tests/runner.cfm?reloadDatabase=true&bundles=tests.specs.integration.ModuleCanBeActivedSpec&reporter=json' >/dev/null
```

Then run the suite:

```bash
box run-script performance
```

The default command writes `tests/results/performance-latest.json`, which is
ignored by Git. Parameters can be overridden through the task directly:

```bash
box task run taskFile=tests/performance/Run.cfc \
    :samples=15 \
    :iterations=50 \
    :output=tests/results/baseline.json
```

For CPU-only work or a database-less engine, use `includeDatabase=false`. For
quick feedback, use `includeRetained=false`; retained-heap probes intentionally
force GC and are slower.

Select one or more scenarios during optimization loops with a comma-delimited
`only` argument:

```bash
box task run taskFile=tests/performance/Run.cfc \
    :only=attribute.read,attribute.assign,entity.is_dirty_clean \
    :includeDatabase=false \
    :includeRetained=false
```

## Compare a candidate to a baseline

Use the same engine, JVM, heap settings, database, power mode, and machine for
both files. Run each revision at least twice and compare the second result to
reduce class-loading and JIT noise.

```bash
box task run taskFile=tests/performance/Compare.cfc \
    :baseline=tests/results/baseline.json \
    :candidate=tests/results/candidate.json \
    :maxWallRegressionPercent=10 \
    :maxAllocationRegressionPercent=10 \
    :maxRetainedRegressionPercent=10
```

The comparison task exits non-zero when a matched benchmark's median wall time,
thread allocation, or retained-heap estimate regresses beyond its threshold. A
10% local threshold is the default because CFML engine, JVM, database, and heap
noise make smaller one-run differences unreliable. Performance PRs should
report multiple-run medians and allocation changes, not a single fastest
result. Retained-heap failures should be confirmed with a profiler before
blocking a change.

The run task also exits non-zero if a requested benchmark group fails. Its JSON
file is still written first so the captured error remains available for
diagnosis.

## Measurement boundaries

- Warmup is never included in samples.
- Each sample times a batch and divides by its logical operation count.
- Database fixture setup occurs outside timed regions and is rolled back.
- Thread allocation counts measure churn, not retained object size.
- Retained heap is a post-GC estimate with a reference-array control. It is
  directional and should be confirmed with JFR or another allocation profiler.
- The framework is intentionally not part of normal CI. A dedicated,
  pinned-runner performance job can consume the JSON and comparison gate later.
