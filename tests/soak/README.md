# Release soak harness

Implementation of [the release soak plan](../../docs/release-soak-testing-plan.md).
This is under construction. The required release gate is **not enabled** and no
accepted baseline exists yet. A short local pilot or HTTP smoke pass does not
qualify a package for publication.

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
It currently runs detector, cancellation, and package-promotion self-tests;
capacity sweeps and full application calibration are not implemented yet.

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
inputs. They are not accepted release thresholds. Production analysis still
needs the plan's early/late ten-minute comparisons, five-minute windows, minimum
20-minute reclamation span, healthy-run noise, and absolute baseline occupancy.

## Application contracts

`app/` is a separate persistent, sessionless ColdBox application. Its engine is
Lucee 6.2.8+20, ColdBox is 8.2.0, JDBC is MySQL Connector/J 8.0.33, full-null
support is enabled, and Quick eager loading is serial. The dedicated server
binds to loopback port 60399. `SOAK_TOKEN` must be at least 32 characters;
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
eviction, and stable lifecycle identity. Automatic application provisioning,
Docker resource isolation, k6, full telemetry,
profiles, and the full run controller are still pending.

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
artifact promotion. A separate preparation/provider integration is required;
do not wire the current directory publisher behind the new gate.

## Remaining acceptance work

- Finish reproducible isolated provisioning and the remaining contract coverage
  (additional browse filters/projections and fixed error-classification counters).
- Implement arrival-rate k6 traffic, exact body assertions, negative contract
  self-tests, coverage and per-window sample requirements, and the 60-minute phases.
- Extend telemetry to database pools/locks/query latency, container budgets,
  generator health, operation latency, GC pressure, and recovery deadlines.
- Implement complete trend analysis and deliberate bad response, held connection,
  latency, saturation, and late-failure detection through the full harness.
- Run the capacity sweep and three full healthy CI trials, investigate noise,
  establish a justified reference, and review an accepted baseline manifest.
- Implement semantic-release preparation and real immutable package promotion,
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
