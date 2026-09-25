# Release soak harness

Implementation of [the release soak plan](../../docs/release-soak-testing-plan.md).
This is under construction. The required release gate is **not enabled** and no
accepted baseline exists yet. A short local pilot or HTTP smoke pass does not
qualify a package for publication.

## Isolated development run

Prerequisites: Docker, Python 3, and CommandBox 6.3.5 on the host (for the seed
setup task). The measured application uses the digest-pinned CommandBox 6.3.1
container and Java 21.0.10+7 JDK from `docker/Dockerfile`.

```sh
tests/soak/run.sh --development
```

This creates a fresh private Docker network, application volume, MySQL database,
application JVM, external JVM collector, and k6 process. The development profile
uses the host Docker architecture, 5 journeys/second for a three-minute plateau,
and 15 seconds each of warmup, ramp, recovery, and idle observation. Setup and
bounded drain add time. It cannot qualify a release or establish a CI baseline.

The default profile declares the full 60-minute schedule and provisional CI
budgets. Its rate remains uncalibrated. Without `--development`, the controller
can collect that schedule but **always returns an inconclusive result** until
CI calibration, overload attribution, and accepted-baseline identity checks are complete.
Do not connect it to publication yet.

Optional inputs: `--output NEW_DIRECTORY`, `--candidate FULL_SHA`, and
`--package PREPARED_PACKAGE_DIRECTORY`. Without a prepared package, it builds an
explicitly diagnostic package from the selected commit; promotion rejects such
packages. Every installed candidate file is checked against its manifest.

Application code and the engine use a fresh Docker volume; host bind mounts are
reserved for evidence. Setup resolves the engine and checksum-pinned JDBC driver
before measured traffic starts. The measured containers have explicit resource
limits and no external network access. There is no published application port;
readiness and sparse diagnostics execute inside the application container.
The controller snapshots harness sources and records their hashes, all resolved
dependency file hashes, image identities, runtime settings, and actual budgets.

Each run retains JSON summaries, an offline HTML chart report, fixed-window
traffic/latency analysis, raw k6 and JVM observations, application/database/container
samples, rotating logs, and bounded JFR recordings. Cleanup removes only the run's
owned containers/network/volume. Failures and cancellation retain their evidence.

```sh
python3 tests/soak/verify_http_contracts.py \
  --output tests/results/soak/http-contracts
python3 tests/soak/verify_controller_cancellation.py \
  --output tests/results/soak/controller-cancellation
```

The HTTP proof checks actual k6 exit codes and metric summaries: wrong error
codes, unrelated exception types, unexpected success/500 responses, extra data,
and wrong validation fields must fail. Several cases deliberately keep the HTTP
status metric green to prove response-body assertions independently block them.
The container cancellation proof waits for completed HTTP work and JVM samples,
then verifies child removal, partial recording flush, and a non-passing result.

## Measurement pilot

From the repository root, with Python 3 and a Java 21 **JDK** (including `javac`):

```sh
python3 tests/soak/telemetry/pilot.py
```

This runs three fresh JVMs for 90 seconds each: healthy allocation churn,
controlled retained-object growth, and growth that begins near the end. Expected
results are `passed`, `failed`, and `inconclusive`, respectively. The command
returns zero only if every requested case produces the expected result. Each
individual summary has `releaseQualified: false`. Do not use `--cases healthy`
as a substitute for the complete detector self-test.

Artifacts go to `tests/results/soak/pilot-<UTC timestamp>/`. Use `--output PATH`
to select a new directory. Existing directories are refused. Each trial records
the exact Java version and flags, hardware, source hashes, periodic JVM/OS
samples, GC cycles, rotating GC logs, bounded JFR recordings, child exit codes,
`summary.json`, and an HTML report with occupancy charts. Failed runs are kept.

The manual GitHub Actions entry point is **Soak diagnostics (no publication)**
in `.github/workflows/soak-diagnostics.yml`. It pins Ubuntu 24.04, Temurin
21.0.10+7, and x64, has only read permission, and uploads evidence even on failure.
It runs measurement/package self-tests and a separate isolated-application job
with HTTP contract probes, all controlled-fault cases, read-only release preparation,
and container cancellation proof.
The diagnostic workflow also accepts explicit `soak-diagnostics-*` tags so it can
be validated before the new workflow exists on the default branch. These tags
have no publication capability and do not add soak traffic to branch/PR/cron
workflows. Capacity sweeps and full application calibration remain pending.

```sh
python3 -m unittest discover -s tests/soak/telemetry -p 'test_*.py' -v
python3 -m unittest discover -s tests/soak/release -p 'test_*.py' -v
python3 tests/soak/telemetry/verify_cancellation.py \
  --output tests/results/soak/cancellation-pilot
```

The cancellation test waits for a live target, live collector, and actual JVM
observations, then terminates the controller. It checks both children are gone,
partial telemetry and JFR survive, and the canceled run cannot pass. This proves
local process cleanup, **not yet GitHub matrix cancellation**.

## Memory measurement method

Method ID: `jdk21-zgc-nongenerational-periodic-jfr-v1`. The provisional runtime
uses non-generational ZGC with a fixed periodic collection interval, identically
in baseline and candidate. The pilot uses a 256 MiB heap and a five-second
interval to validate detection cheaply. The application starts with a 1 GiB
heap and a 15-second interval; those conditions still require calibration.

An external Java process attaches through the local JMX management agent and
uses the JDK's `RemoteRecordingStream`. It joins `jdk.GCHeapSummary` **After GC**
events with completed `jdk.GarbageCollection` events by `gcId`. On this JDK the
JFR collector name is `Z`; JMX reports `ZGC Cycles` and `ZGC Pauses`. Young-only,
unmatched, duplicate, or insufficient reclamation observations cannot establish
retained-heap stability. No explicit GC calls, repeated heap dumps, cache clears,
or application restarts are part of a measured trial.

Post-cycle occupancy includes allocations concurrent with reclamation. It is a
matched-load growth signal, not an exact live-object census. Source references:
[JDK RemoteRecordingStream](https://docs.oracle.com/en/java/javase/21/docs/api/jdk.management.jfr/jdk/management/jfr/RemoteRecordingStream.html),
[JDK diagnostic commands](https://docs.oracle.com/en/java/javase/21/docs/specs/man/jcmd.html).

The pilot's 16 MiB detector threshold and ten-second windows are detector-test
inputs. They are not accepted release thresholds. The application analyzer now applies early/late ten-minute medians, five-minute
windows, a minimum 20-minute reclamation span, sustained and late growth rules,
and unsettled-reference checks. It can compare calibrated noise and absolute
baseline occupancy, but those inputs remain unaccepted and are not wired into
release qualification. The four-minute development run correctly leaves this
memory assessment inconclusive.

The resource analyzer checks telemetry coverage, stable lifecycle identity,
declared heap/pool/cache/OS bounds, sustained container headroom, stop-the-world
GC pause windows, and idle connection/queue/scratch recovery. It compares idle
threads and descriptors with the early plateau. Profile `limits` are provisional
engineering bounds requiring CI calibration; they are not measured healthy-run
limits. RSS and total concurrent collection elapsed time do not substitute for
retained heap or stop-the-world pauses.

```sh
python3 tests/soak/verify_faults.py --output tests/results/soak/fault-suite
```

The verifier runs a healthy control and four fresh application/database cases:
a real pooled JDBC connection deliberately left borrowed, a wrong error code
from the normal Quick exception handler, sustained report latency, and report
latency beginning in the final comparison window. The process environment fixes
the fault before boot; authenticated HTTP can activate it once. `--fault` requires
`--development`, and all cases remain ineligible for publication. The held-connection
injector uses the pinned Lucee pool API solely to create the deliberate leak.
It retains one connection after a real `SELECT 1`, without adding a running query.
The verifier requires the specific detector reason and cleanup evidence; an
unrelated timeout or crash does not count as successful fault verification.

## Application contracts

`app/` is a separate persistent, sessionless ColdBox application. Its engine is
Lucee 6.2.8+20, ColdBox is 8.2.0, JDBC is MySQL Connector/J 8.0.33, full-null
support is enabled, and Quick eager loading is serial. The dedicated server
binds to loopback port 60399 when run directly; the container controller uses
private port 8080. `SOAK_TOKEN` must be at least 32 characters;
every harness HTTP request requires it in `X-Soak-Token`.

`fixtures/generate.py OUTPUT_DIRECTORY` generates immutable SQL and a manifest
for 20 teams, 1,000 users, 10,000 posts, 50,000 polymorphic comments, 100 tags,
and 17,144 pivots. It records expected relationship counts and report checksums.
The SQL deliberately uses `CREATE DATABASE`, never `DROP` or `TRUNCATE`: an
existing database causes setup to fail. Seed records occupy IDs through 10,000;
scratch posts start at 1,000,000 and missing IDs start at 2,000,000,000.

For an already provisioned disposable MySQL container with an empty schema,
the CommandBox setup task creates and seeds the database once:

```sh
SOAK_MYSQL_ROOT_PASSWORD="$YOUR_DISPOSABLE_ROOT_PASSWORD" box task run \
  taskFile=tests/soak/Seed.cfc :container=quick-soak-your-run-id \
  :output=tests/results/soak/YOUR-RUN-ID/fixtures
```

Container names must match `quick-soak-[a-z0-9-]+`. Output paths are relative to
the repository root. Repeating setup against an existing database fails.

The current HTTP verifier requires an already installed, seeded running app:

```sh
SOAK_TOKEN="$YOUR_LOCAL_SOAK_TOKEN" python3 tests/soak/http_smoke.py \
  --fixture-manifest tests/results/soak/dev-fixtures/fixture-manifest.json \
  --package-manifest tests/results/soak/dev-package/package-manifest.json \
  --installed-package tests/soak/app/modules/quick \
  --output tests/results/soak/http-smoke.json
```

It exercises actual HTTP contracts, concurrent committed writes and re-queries,
real Quick not-found paths, rollback, cleanup, deterministic reads, cache
eviction, and stable lifecycle identity. The controller now provisions those
dependencies automatically and exercises the endpoints with arrival-rate k6
traffic. Resource and memory analysis are integrated; CI calibration and release qualification remain pending.

## Package identity and promotion

`release/package.py build --repo REPO --prepared JSON --output DIRECTORY` builds
from a full commit SHA, independent of dirty files or dependency directories.
Prepared JSON supplies `candidateSha`, `version`, `lastRelease` (the immutable
provider identity used to prepare the version), and `notes`. A strict package
allowlist includes the runtime module and documentation files needed by the
package, excluding tests, engines, databases, reports, and nested build output.
Deterministic ZIP metadata permits repeated builds to be compared byte for byte.

`release/package.py verify --directory DIRECTORY --candidate FULL_SHA` checks
the ZIP checksum, all member hashes, metadata, version, and source identity.
The promotion protocol revalidates candidate and last-release identity, uploads
those exact bytes, checks the downloaded bytes, then publicizes. Its tests use a
fake publisher; there is no real provider adapter connected yet.

The inspected CommandBox semantic-release 4.1.0 publisher calls `package version`
and then `forgebox publish`, which rebuilds from the directory. CommandBox 6.3.5
also rebuilds the storage ZIP inside its ForgeBox endpoint despite having a
`zipPath` argument. Consequently the existing publisher cannot provide tested
artifact promotion. Read-only preparation now invokes the pinned 4.1.0 parser, filter, analyzer, and
notes generator against explicit Git object IDs. It verifies ForgeBox/GitHub
agreement, the exact last-release tag and commit, ancestry, and unchanged provider
state after preparation. Source/plugin hashes and preparation inputs are retained.
It does not invoke semantic-release's publishing or repository mutation hooks.

```sh
python3 tests/soak/release/verify_preparation.py -v
python3 tests/soak/release/prepare.py --repo . --candidate FULL_SHA --output NEW_DIRECTORY
```

Preparation requires CommandBox 6.3.5, installed `commandbox-semantic-release@4.1.0`,
an authenticated read-only-capable `gh` session, and a full Git checkout with tags.
It currently supports stable versions. A `noRelease: true` result has no proposed
version and must not be packaged or published. The integration verifier uses
actual disposable Git history and the actual plugins, with provider identities
supplied locally; it proves patch/minor/breaking/no-change/skip behavior and rejects
stale provider state or mismatched tags without altering the repository.

The real immutable provider adapter and guarded workflow promotion still need
implementation. Do not wire the directory publisher behind the new gate.

## Remaining acceptance work

- Validate the complete 60-minute workload in CI and finish capacity-sweep
  orchestration; only the short development schedule has run end to end.
- Finish overload attribution, accepted-baseline identity validation, and calibration
  of the implemented traffic/resource/memory/GC/recovery checks.
- Complete live proof of held-connection and saturation detection, and run all
  controlled faults on the final CI profile. Retain every unsuccessful proof.
- Run the capacity sweep and three full healthy CI trials, investigate noise,
  establish a justified reference, and review an accepted baseline manifest.
- Finish real immutable package promotion from the read-only prepared artifact,
  with provider/commit revalidation under repository publication concurrency.
- Enable exactly one soak row in the release-only fail-fast matrix **after**
  baseline acceptance, preserve all functional rows, and test both failure
  directions, explicit cancellation, and all-pass publication with a stub.
- Deliver full reports and final acceptance evidence. No milestone above can be
  substituted by the short pilot or by the fake-publisher unit tests.

## Local milestone evidence (2026-09-25)

These observations are development evidence on macOS/aarch64, not CI calibration:

- `tests/results/soak/pilot-20260925T203157Z/report.html`: all three expected
  detector outcomes observed on fresh Java 21.0.10+7 JVMs. Healthy growth was
  0 MiB; sustained leakage grew 66 MiB and failed; late leakage grew 65 MiB and
  was inconclusive. Each target and collector exited zero after collection.
- `tests/results/soak/cancellation-pilot-local/cancellation-verification.json`:
  a live controller was canceled, both child JVMs stopped, partial telemetry/JFR
  survived, and the canceled trial remained inconclusive.
- `tests/results/soak/http-smoke-instrumented.json`: real HTTP checks passed,
  including all five intentional failure cases, unrelated-exception rejection,
  16 concurrent committed write journeys, rollback, pivots, and cleanup. Boot
  identity stayed constant, application starts remained one, scratch count
  ended at zero, and derived entries stayed at 22 while evictions rose from
  18 to 51. The installed package's member hashes matched the candidate ZIP.
- `tests/results/soak/development-runtime-manifest.json` records the application
  source hashes and resolved dependency versions; `application-telemetry-pilot/`
  contains external telemetry/JFR from the actual ColdBox JVM.
- `tests/results/soak/http-smoke-final.json` repeats the HTTP checks on the final
  formatted source in a fresh JVM. All 12 ColdFusion components pass CFFormat.
- The seed task created 1,000 users, 10,000 posts, 50,000 comments, and 17,144
  pivots in its fresh database and refused to recreate an existing database.
- Nine analyzer tests and ten fake-publisher tests passed. The existing release
  workflow and ordinary PR/cron workflows have not been changed.
  The new manual diagnostics workflow has not been executed in CI yet.

Earlier development HTTP failures are not qualifying runs. In particular,
`http-smoke.json` records a cleanup failure; the retained row IDs and subsequent
cleanup through the corrected HTTP endpoint are recorded separately. No table
reset was used to turn that failed run into a pass.

### Container workload milestone

- `r20260925t213414-d01806/traffic-analysis.json`: all 900 offered plateau
  journeys started and completed; each intentional failure case was verified and
  recovered 36 times; all 32 query variants ran; every development comparison
  window met its declared coverage/sample requirements. Final scratch rows,
  borrowed connections, waiting borrowers, and queued requests were zero.
  Application starts stayed at one; derived entries stayed at 22 with 32 evictions.
- `controller-cancellation-20260925/cancellation-verification.json`: cancellation
  after real HTTP work removed every owned container and volume, flushed JFR,
  retained telemetry, and left an inconclusive canceled result.
- `http-contract-negative-final-20260925/verification.json`: both valid contracts
  passed and all six malformed contracts produced k6 threshold exit 99. Wrong
  body contracts failed even when their expected HTTP status metric passed.
- Twenty memory/traffic analyzer tests and eleven package-promotion tests pass.
  The manual diagnostics workflow passes actionlint 1.7.7; it has not run in CI.
- Earlier container runs are retained, including database readiness, offline JDBC,
  browse-builder, Linux configuration filename, and bind-mount performance failures.
  The 10- and 5-journey/second bind-mounted runs timed out and remain failed.
  Moving runtime files to a Docker volume changed the tested environment; their
  failures are not overwritten or counted as qualifying calibration trials.

- `development-final-20260925/` repeats the complete development schedule with
  source snapshots, dependency file identities, strict projections, configuration
  checks, and automatic reporting. It completed 901 plateau journeys for a nominal
  target of 900: k6 admitted one arrival 4.8 ms after the phase boundary. The old
  analyzer incorrectly labeled this overdelivery a shortfall. Its original
  inconclusive summary is preserved. `traffic-reanalysis-boundary.json` records
  the corrected analyzer's passing result on the unchanged raw observations.
  The correction accepts only one completed boundary arrival, never dropped or
  missing work; dedicated tests also reject an extra arrival away from the boundary.
  See the pinned [k6 arrival-timer/duration selection](https://github.com/grafana/k6/blob/v1.3.0/lib/executor/constant_arrival_rate.go#L327-L366).
- `controller-cancellation-final-20260925/cancellation-verification.json` repeats
  live cancellation on the final controller, additionally verifying ownership-
  labeled network removal and source/dependency snapshots. All ten checks pass.
- `controller-cancellation-volumes-20260925/cancellation-verification.json` adds
  explicit proof that MySQL's anonymous data volume is removed; all eleven checks
  pass. Earlier cleanup omitted Docker's `rm -v` flag. Twelve orphaned volumes
  attributable to recorded runs were removed after matching creation timestamps
  and inspecting synthetic fixture contents; the audit is retained in
  `anonymous-volume-cleanup-20260925.json`. No general Docker volume prune ran.

### Resource and fault-analysis milestone

- `resource-analysis-live-20260925/` completed all development phases with passing
  traffic and resource assessments. Threads recovered from an early median of 40
  to 44 (allowance 8), descriptors fell from 186 to 109, and idle connections,
  queues, and scratch rows cleared. Memory remained inconclusive because the
  required 20-minute observation span was not reached. The extended report was
  inspected in the browser.
- Forty-one memory/traffic/resource tests and eleven package tests pass. Eight
  integration tests exercise the real semantic-release preparation plugins and
  disposable Git repositories without publication or repository changes.
- `fault-suite-20260925/` preserves the initial full detector batch. Its healthy
  control, wrong-contract, sustained-latency, and late-latency cases verified
  their intended outcomes. The late latency result was inconclusive, with all
  offered work completed and resource recovery passing. The original held-query injector encountered a report timeout during
  JVM allocation stalls before idle recovery; it does **not** prove connection-leak
  detection. That failed run and its thread dump, GC logs, and JFR are retained.
  The injector was subsequently narrowed to borrowing and retaining one validated
  pool connection, removing the running query and CFML thread from this test.
