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
five minutes of warmup, and 15 seconds each of ramp, recovery, and idle observation. Setup and
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
python3 tests/soak/verify_controller_cancellation.py --mode collector-stop \
  --output tests/results/soak/collector-failure
```

The HTTP proof checks actual k6 exit codes and metric summaries: wrong error
codes, unrelated exception types, unexpected success/500 responses, extra data,
and wrong validation fields must fail. Several cases deliberately keep the HTTP
status metric green to prove response-body assertions independently block them.
The container cancellation proof waits for completed HTTP work and JVM samples,
then verifies child removal, partial recording flush, and a non-passing result.
The observer-loss mode waits for live HTTP, JVM samples and a retained recording,
then kills only the run-owned collector. It requires an inconclusive result with
the explicit observer-loss and incomplete-recording reasons, preserved partial
evidence, and removal of every owned resource. It cannot report healthy memory
after telemetry disappears.

## Measurement pilot

From the repository root, with Python 3 and a Java 21 **JDK** (including `javac`):

```sh
python3 tests/soak/telemetry/pilot.py --generational
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
21.0.10+7, and ARM64, has only read permission, and uploads evidence even on failure.
It runs measurement/package self-tests and a separate isolated-application job
with HTTP contract probes, all controlled-fault cases, read-only release preparation,
and container cancellation proof.
The diagnostic workflow also accepts explicit `soak-diagnostics-*` tags so it can
be validated before the new workflow exists on the default branch. These tags
have no publication capability and do not add soak traffic to branch/PR/cron
workflows. An eligible capacity result and full application calibration remain pending.

```sh
python3 -m unittest discover -s tests/soak/telemetry -p 'test_*.py' -v
python3 -m unittest discover -s tests/soak/release -p 'test_*.py' -v
python3 tests/soak/telemetry/verify_cancellation.py \
  --output tests/results/soak/cancellation-pilot
```

The cancellation test waits for a live target, live collector, and actual JVM
observations, then terminates the controller. It checks both children are gone,
partial telemetry and JFR survive, and the canceled run cannot pass. This proves
local process cleanup. Separate verified native matrix cancellation runs are
recorded under **Native matrix cancellation proof** below.

## Memory measurement method

Method ID: `jdk21-zgc-generational-major-periodic-jfr-v1`. The provisional v9
runtime uses generational ZGC with a fixed periodic major collection interval,
identically in baseline and candidate. The pilot uses a 256 MiB heap and a
five-second major interval to validate detection cheaply. The application uses
a 6 GiB heap and 15-second major interval; these conditions require calibration.
The earlier non-generational method remains supported for historical evidence.

An external Java process attaches through the local JMX management agent and
uses the JDK's `RemoteRecordingStream`. It joins `jdk.GCHeapSummary` **After GC**
events with completed `jdk.GarbageCollection` events named `ZGC Major` by `gcId`.
JMX must report all four generational cycle/pause collectors. Minor, unmatched,
duplicate, or insufficient reclamation observations cannot establish retained
stability. Concurrent major/minor cycle durations are reported separately;
they are not added together or treated as stop-the-world pause time. No explicit
GC calls, repeated heap dumps, cache clears, or application restarts are part
of a measured trial.

Post-cycle occupancy includes allocations concurrent with reclamation. It is a
matched-load growth signal, not an exact live-object census. Source references:
[JDK RemoteRecordingStream](https://docs.oracle.com/en/java/javase/21/docs/api/jdk.management.jfr/jdk/management/jfr/RemoteRecordingStream.html),
[JDK diagnostic commands](https://docs.oracle.com/en/java/javase/21/docs/specs/man/jcmd.html).

The pilot's 16 MiB detector threshold and ten-second windows are detector-test
inputs. They are not accepted release thresholds. The application analyzer now applies early/late ten-minute medians, five-minute
windows, a minimum 20-minute reclamation span, sustained and late growth rules,
and unsettled-reference checks. It can compare calibrated noise and absolute
baseline occupancy, but those inputs remain unaccepted and are not wired into
release qualification. The short development plateau correctly leaves this
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
Development runs now retain five minutes of warmup after a CI detector case
encountered allocation stalls before fault activation. Latency injection delays
are derived from the declared warmup/ramp schedule, so they still begin at the
intended sustained or final plateau windows. This changes diagnostic timing,
not the already-declared full release schedule.
`late-latency-full-warmup-20260925/verification.json` verifies the revised local
timing: all offered work completed, resources recovered, and the exact late
report-latency rule produced an inconclusive result. CI v5 subsequently passed
the complete suite in run `36218946123`; the latest profile requires its own
matching evidence.

## Application contracts

`app/` is a separate persistent, sessionless ColdBox application. Its engine is
Lucee 6.2.8+20, ColdBox is 8.2.0, JDBC is MySQL Connector/J 8.0.33, full-null
support is enabled, and Quick eager loading is serial by default. The dedicated server
binds to loopback port 60399 when run directly; the container controller uses
private port 8080. `SOAK_TOKEN` must be at least 32 characters;
every harness HTTP request requires it in `X-Soak-Token`.

The separate `--profile tests/soak/profiles/lucee6-parallel.json` opt-in profile
requests parallel eager loading on the relationship graph through Quick's public
`with(..., true)` API. It uses four workers, a 64-task bounded queue, and an
8-second worker timeout. The executor is configured once during boot before
readiness. Diagnostics record worker activity, completed tasks, and queue depth;
resource analysis requires actual worker completions during sustained traffic
and zero active/queued work after drain. Serial and parallel measurements have
different profile identities and require separate calibration and acceptance.
Neither profile has an accepted release baseline yet. The first live opt-in run
(`tests/results/soak/parallel-bounded-20260925`, pinned Quick `af2c93d`) loaded
four-worker/64-queue settings but failed its first graph request with
`QuickParallelEagerLoadingException: Datasource [quick_soak] doesn't exist`.
Quick's worker context did not resolve this application's datasource. The run
retains the actual HTTP 500 and application log; it provides no passing parallel
coverage. The harness does not replace that failure with a serial fallback.

`fixtures/generate.py OUTPUT_DIRECTORY` generates immutable SQL and a manifest
for 20 teams, 1,000 users, 10,000 posts, 50,000 polymorphic comments, 100 tags,
and 17,144 pivots. It records expected relationship counts and report checksums.
The controller passes the profile's `fixtures.highFanoutComments` explicitly:
60 for the standard/parallel profiles, 180 for the larger-report profile.
The standalone generator accepts `--high-fanout-comments 60`; omitting it retains
the historical 180-comment SQL. The seed task's corresponding optional input is
`:highFanoutComments=60`. Profile and fixture identities record the choice.
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
fake publisher; no real provider adapter is connected to the release workflow yet.

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

`release/provider.py` implements the ForgeBox storage/publish protocol inspected
in CommandBox 6.3.5 and the [GitHub releases API](https://docs.github.com/en/rest/releases/releases).
It submits the exact tested ZIP, verifies the downloaded SHA-256, creates the
release at the full candidate SHA, and verifies the resulting tag. It rechecks
candidate/provider state at the upload boundary, rejects existing versions and
partial uploads, records durable checkpoints before each write, and never
automatically retries writes. API tokens and signed storage URLs are excluded
from its journal. Fake HTTP integration tests cover these behaviors, including
corrupt downloads and uncertain partial publication. A live read-only request
verified the current ForgeBox response/version-inventory shape; no real write
has been made. `release/promote_qualified.py` now verifies the complete raw
qualification receipt before creating the provider adapter, freezes its package
manifest and prepared notes, and binds the final publication receipt to baseline
and evidence hashes. Its CLI rejects local, PR, tag, and wrong-candidate contexts.
Those context checks do not replace the required whole-matrix dependency and
repository-wide native concurrency guard; guarded workflow integration remains
pending. Fake-provider tests prove rejected evidence causes zero provider calls
and a rebuilt package cannot replace the qualified ZIP between checks. Do not wire
the directory publisher behind the new gate.

`qualification.py --baseline ACCEPTED_JSON --profile PROFILE_JSON --package
PREPARED_DIRECTORY --candidate FULL_SHA` is the explicit candidate gate entry
point. There is no accepted baseline checked in yet. It requires a reviewed
proposal with three distinct sealed CI trials, durable evidence and detector
references, and an absolute budget for every operation. It verifies identical
measurement inputs before load, applies the accepted latency and memory
references, and verifies the generator again after the complete run. Only all
passing assessments can produce `qualification.json`; its receipt binds the
candidate SHA, exact ZIP, accepted-baseline checksum, and raw evidence. Promotion
must call `verify_qualification` after downloading the artifacts. A missing
baseline, development run, calibration trial, diagnostic package, or changed
evidence cannot qualify publication. This entry point remains disconnected from
the live release workflow until baseline and detector acceptance are complete.

No-release preparations use the separate `package.py build-validation` command.
It retains the original preparation inside the artifact metadata, reuses the last
released version, and marks the package validation-only. Ordinary `build` still
rejects no-release input. `qualification.py --validation-only` runs the same full
schedule and accepted-baseline comparisons, but produces `validation-passed` and
`validation.json`, with `releaseQualified: false`. Receipt purposes cannot be
interchanged, and promotion rejects the artifact before any provider calls.
The workflow still needs to select this path when preparation reports no release.

## Disabled release integration template

`release/release.yml.pending` is a reviewable replacement for the release workflow;
GitHub does not execute it from that location. The live `.github/workflows/release.yml`
remains unchanged. Before activation, finish the acceptance work below, freeze the
capacity-selected profile and review `baselines/lucee6-serial.json`, then install
the template as the live release workflow in that reviewed update.

The template retains the main/master trigger and version-update skip rule. Its
explicit matrix has one soak row first and the same 23 functional combinations,
native fail-fast and no concurrency cap. Only functional rows receive the legacy
MySQL service; the soak owns its isolated database. Preparation and package build
occur inside the soak row, so functional work starts independently.

`release/validate_candidate.py` selects the publication or no-release validation
builder from the prepared metadata. `release/supervisor.py` launches the full
qualification independently, reuses the native-tested single-signal handoff,
and allows up to 90 minutes for observation. Always-run cleanup waits for owned
resources to disappear. A missing baseline stops before provisioning; it cannot
select a report-only fallback. Full native validation with this wrapper remains
pending accepted-baseline availability.

The publisher depends on the entire validation matrix and holds one repository
publication concurrency group with cancellation disabled. After artifact download,
inspection verifies the full receipt before emitting publication eligibility.
No-release validation emits false; only a verified publication receipt reaches
the immutable provider adapter. The adapter rechecks release-branch/provider
state under the guard and verifies downloaded package bytes. `actionlint` and
matrix-structure checks passed for the template; these do not replace actual
full-matrix rollout and publication-stub evidence.

The staged native entry point **Full release validation proof (no publication)**
in `.github/workflows/soak-release-proof.yml` uses that exact pending validation
job (23 real TestBox rows and one full qualification row). Generate/check it with:

```sh
python3 tests/soak/release/stage_full_probe.py
python3 tests/soak/release/stage_full_probe.py --check
```

The generator preserves every validation row, workload command and qualification
step. It removes the release-marker skip condition, adds diagnostic fault hooks
and TestBox JSON output retention, and replaces the entire publisher job.
Diagnostic CI checks these explicit transformations against the pending template.
This full proof uses manual dispatch or `soak-release-proof-<mode>-*` tags;
dispatch waits for accepted baseline availability. It retains the same fail-fast
behavior, supervisor, receipt checks, package artifact and timeouts. It is not
a development fallback.

After every validation succeeds, `release/probe_qualified.py` verifies the full
downloaded receipt. A publication candidate traverses `promote_qualified()` and
`package.promote()` with a local-only publisher, retaining the actual ZIP upload,
readback checksum and checkpoints. A no-release candidate verifies its complete
validation receipt and never constructs that publisher. The proof has read-only
repository permissions and no ForgeBox credential. Tags containing
`-serialization-` hold its dedicated diagnostic publication guard for 180 seconds.
Artifacts are `release-soak-<SHA>-<attempt>` and
`full-publication-proof-<run ID>`. Unit checks prove routing and exact-byte local
promotion; full native receipt/promotion evidence is still pending calibration.
After a full proof run reaches a terminal state, download and inspect it with:

```sh
python3 tests/soak/release/verify_full_probe.py --run-id RUN_ID \
  --output tests/results/soak/full-matrix-RUN_ID
```

This verifier loads the baseline and matrix template from the tested commit,
requires all 23 exact functional combinations plus the soak, checks real TestBox
execution overlaps soak observation, verifies the raw receipt against that
baseline, and checks publication starts after every validation finishes. It
hashes the actual stub-uploaded ZIP; a claimed checksum is insufficient.
All 23 rows must also retain nonempty, passing TestBox JSON reports. A green
job cannot hide a failed report.

Full-matrix modes are `all-pass`, `functional-failure`, `soak-failure` and
`explicit-cancel`. Functional failure waits for live soak evidence, then adds
one deliberately failing TestBox assertion in the Lucee 6 / ColdBox 8 / full-null
row. That row executes the normal full TestBox command; the verifier requires
the exact assertion failure in its raw report and canceled soak cleanup.
Soak failure waits for a retained JFR and actual TestBox execution, then kills
only its owned application. The verifier requires that application's exit 137,
a failed soak, cancellation of the observed functional sibling, partial evidence
and complete removal of owned resources. An unavailable final recording after
the deliberate target death is not mistaken for successful telemetry flush.

For `explicit-cancel`, tag the run with `soak-release-proof-explicit-cancel-*`
and use the bounded helper, which refuses other workflows/tags:

```sh
python3 tests/soak/release/cancel_full_probe.py --run-id RUN_ID \
  --output tests/results/soak/full-cancel-RUN_ID.json
```

It waits until both live soak and real TestBox work are observed in the same
workflow, records that snapshot, and cancels that existing run once. After its
terminal state, pass `--mode explicit-cancel --cancellation-evidence PATH` to
`verify_full_probe.py`. For the other failure modes, pass their matching `--mode`.
Every failure verifier requires blocked publication, retained HTTP/JVM evidence,
and owned-resource cleanup. These full-matrix scenarios are staged and unit
checked; their real native executions remain pending baseline acceptance.
The isolated CommandBox/TestBox probe
`full-fault-assertion-20260926/verification.json` executes the actual injected CFC
and verifies exactly one intended failed assertion, zero errors and the precise
JSON status/message fields. It validates the fixture/report contract, not native
matrix cancellation.

For two complete `all-pass` runs whose tags contain `-serialization-`, run:

```sh
python3 tests/soak/release/verify_full_serialization.py \
  --evidence tests/results/soak/full-matrix-FIRST tests/results/soak/full-matrix-SECOND \
  --output tests/results/soak/full-serialization
```

It re-verifies each raw full receipt and actual uploaded ZIP, then requires real
contention (the second validation is ready while the first guard is held),
nonoverlapping guard jobs/promotion bodies, and both three-minute holds. Separate
preparations may embed different timestamped notes; each uploaded ZIP must match
its own tested receipt. The native proof establishes guard behavior; adapter
tests separately prove rejection when provider state invalidates preparation.

## Remaining acceptance work

- Obtain an eligible capacity target and validate the complete 60-minute workload
  in CI; only development schedules have completed end to end so far.
- Repeat controlled detector proofs after any further profile change and retain
  every unsuccessful attempt. The complete v8 CI diagnostics, including
  generator/application saturation attribution and both latency faults, passed
  in run `36221908854`; they do not establish an eligible capacity target.
- Run three full healthy CI trials, investigate noise and hosted-runner variance,
  establish a justified reference, and review an accepted baseline manifest.
- Integrate verified immutable promotion under repository-wide publication
  concurrency, including full validation of candidates that require no release.
- Enable exactly one soak row in the release-only fail-fast matrix **after**
  baseline acceptance, preserve all 23 functional rows, reuse the verified native
  cancellation handoff, and verify the full release matrix with a publication
  stub. The two-row diagnostic all-pass proof has passed (`36218396157`).
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
- `held-pool-connection-20260925/verification.json` verifies that narrowed
  injector: traffic passed, while final and idle borrowed-connection checks
  failed for the intended reason. JFR flushed and all owned resources were removed.

### Capacity calibration entry point

Run `python3 tests/soak/capacity.py --candidate <full-healthy-sha>` or the
independent **Soak capacity calibration (no publication)** workflow. The latter
also accepts explicit `soak-capacity-*` tags while this workflow is being
validated before merge. It is absent from ordinary branch, PR, cron, and release
workflows and has read-only repository permissions.

The sweep keeps one application JVM, database, and collector alive across
warmup and bounded rate steps. The five-minute capacity warmup runs at 10% of
the first sweep rate (0.5 journeys/second for a 5/second first step), independently
of the as-yet unmeasured release target. It stops after the first unclean step, observes
idle resource recovery between clean steps, and proposes 60% of the highest
clean rate with measured journey-duration headroom. A proposed trial profile is
written only after successful evidence collection and only if its rate can
satisfy the full latency sample floor. No baseline is accepted automatically.
CI capacity steps collect at least 200 observations per operation and compare
aggregate step p95s before increasing the rate. Low-rate steps consequently take
longer (the v2 5/second step takes seven minutes). They do not replace the
independent five-minute windows or 60-minute baseline trials. Development probes
remain short and cannot produce a qualifying profile.

`capacity-controller-local-20260925/` is development evidence: 5 journeys/second
passed, while 10 encountered HTTP timeouts and dropped arrivals. The sweep
stopped, preserved both steps, flushed JFR, and removed its resources. This local
arm64 run uses shortened warmup and sample requirements and cannot produce a
qualifying trial profile.

CI run `36209974082` preserved an inconclusive first capacity attempt. All
offered work completed at 5/second and resources recovered, but report latency
crossed the late-window band with only 5-10 observations. The revised sweep
requires 200 per operation before comparing rates; the original inconclusive
evidence is retained. Run `36210905572` then reached the 2 GiB container's
headroom limit during that longer first step. Run `36212346552`, using the
provisional 3 GiB container, failed on a cold 1,000-row report during warmup;
it also verified two clean image builds produced identical amd64 image IDs.
The warmup had been running at 2.4/second based on the unmeasured release target,
which is now corrected to the first sweep rate above. These failed observations
remain preserved; neither provides a capacity target or a baseline.

### Full baseline bootstrap and input matching

`python3 tests/soak/calibration.py --capacity <complete-ci-capacity-directory>`
validates the capacity evidence and runs one complete 60-minute trial using its
exact candidate ZIP and proposed target. It rejects changed hardware, runner
image, executable harness sources, runtime, fixture data, dependencies, budgets,
or workload before arrivals. Actual Lucee/ColdBox versions and JVM arguments are
recorded. The complete source snapshot is retained; review metadata and baseline
pointers are excluded from the comparison digest to avoid self-reference.
Preparation/publication tooling also remains in the complete audit snapshot,
while exact package bytes are bound separately. Changing a publisher does not
change the measured runtime identity; changing workload or measurement code does.

The capacity workflow's `trials` option (or explicit `soak-calibration-*` tag)
runs three trials sequentially on the same runner, creating a fresh application
and database for each. `calibration-passed` never means `releaseQualified` and
does not accept or replace a baseline. Missing eligibility stops before trials.

Completed trials seal their raw measurements, package, manifests, assessments,
and final JFR in `trial-evidence.json`. After three complete matching trials,
`baseline.py --trials <trial-1> <trial-2> <trial-3> --output <proposal.json>`
produces a review proposal with measured p95 variation, memory noise, proposed
per-operation absolute budgets, and resource recovery. Reused JVMs, changed
evidence, differing inputs, and incomplete trial windows are rejected. More
than 10% run-to-run p95 variation or unexplained retained-growth/noise blocks
proposal readiness. This tool cannot accept a baseline or qualify a release.
The telemetry/calibration and package/provider policy suites pass;
no three-trial proposal has been produced from real full-length runs yet.

Runtime image builds use a fixed `SOURCE_DATE_EPOCH=0` following
[Docker's reproducible-build guidance](https://docs.docker.com/build/cache/invalidation/).
Two earlier CI runners produced different runtime image IDs from the same
Dockerfile and pinned inputs. `verify_image.py` now builds twice without cache
and checks identical image identities before CI capacity work. The local arm64
proof in `runtime-image-reproducibility-20260925/verification.json` produced
identical image IDs on both fresh builds. CI run `36212346552` also produced
identical amd64 image IDs on two clean builds.

Delivery analysis aligns shortfall windows with container CPU budgets and
application/database queues. Proven application saturation fails; generator
capacity loss, joint saturation, or unresolved attribution is inconclusive.
Wrong responses and unexpected HTTP failures remain hard failures regardless
of generator pressure. Actual capacity saturation proof remains pending.

`verify_saturation.py` provides separate real-container detector cases:

```sh
python3 tests/soak/verify_saturation.py \
  --candidate af2c93d2604de73d7ccac23b7bf69c4be221dbb0 \
  --output tests/results/soak/saturation-suite
```

Each case provisions the real application and database and retains the full
development warmup. The generator case adds bounded CPU work before plateau
requests in four VUs, retaining actual HTTP assertions. The application case
reduces its Docker CPU quota from 3 to 1 after warmup. The verifier uses only
post-injection resource observations and requires the exact attribution,
non-qualifying result, owned cleanup and final recording. It records the fault
mechanism, actual quota and generated workload hash. Quotas are restored only
after measurement for teardown; that restoration is not recovery evidence.
`--cases generator` or `--cases application` is a partial diagnostic and is
explicitly marked as an incomplete suite. CI runs both in the separate
**Distinguish live generator and application saturation** diagnostic job.

CI run `36208965667` passed measurement/promotion tests and verified the healthy,
held-connection, wrong-contract, and sustained-latency application cases. Its
late-latency case timed out on a graph request before fault activation, with ZGC
allocation stalls in the retained recording/logs. That case remains unproven in
CI; the workflow's overall result is failed and has not been waived.

CI capacity run `36210905572` stopped at 5/second after application container
memory exceeded 90% of its 2 GiB budget for two minutes. The run is failed, not
a baseline. Across its observation, metaspace remained about 61-63 MiB and
post-cycle heap medians varied with allocation (roughly 128-326 MiB in two-minute
groups); these short observations do not establish retained-memory stability.
The next provisional profile allows 3 GiB of container memory while retaining
the same 1 GiB heap. New per-sample cgroup memory categories distinguish anonymous,
file/shared, and kernel usage; they are overlapping categories and are not summed.
This is a diagnostic/calibration change requiring fresh capacity and baseline
trials, not acceptance of the failed run or an explanation of the growth.

### Native matrix cancellation proof

`soak-matrix-proof.yml` is an isolated, read-only diagnostic workflow with one
real development soak and one explicitly labeled functional stub. It proves
Actions scheduling/cancellation and the whole-matrix publication dependency;
it does not claim TestBox coverage or replace the eventual 23 functional rows.
Its soak row is first, `fail-fast` is true, and no concurrency cap is set.
The publication stub only records a JSON marker and has no provider calls.

Select `functional-failure`, `soak-failure`, `explicit-cancel`, or `all-pass`
through workflow dispatch, or an explicit `soak-matrix-<mode>-<suffix>` tag.
The functional-failure mode waits until the soak has completed HTTP work and
collected at least three JVM samples before failing. The soak-failure mode
uses the actual wrong-contract fault while its functional sibling is live.
For explicit cancellation, wait for the **Observe live soak** step, then cancel
the workflow normally. Cleanup checks and evidence uploads use `always()`.

After terminal workflow state, run:

```sh
PROBE_MODE=functional-failure python3 tests/soak/matrix_probe.py verify-remote \
  --run-id <github-run-id> --output <new-evidence-directory>
```

The verifier downloads artifacts and checks actual job conclusions, workload
liveness, owned container/volume/network removal, final collector flush, retained
recording, and publication-stub execution only for all-pass. The terminal native
proofs and outstanding all-pass evidence are recorded below.

CI diagnostic run `36210905683` retained five-minute warmup and completed every
request in its late-latency case, with resource recovery. It nevertheless failed:
`report_100` and rollback latency crossed sustained comparison bands before the
late injection, so it did not prove the intended late-only detector. Its earlier
healthy, held-connection, wrong-contract and sustained-latency cases passed their
specific checks. The overall run remains failed. Hosted runners in these probes
reported EPYC 9V45, 9V74 and 7763 models; their recorded measurement identities
remain distinct. Full capacity and baseline evidence must resolve this variance.

The first native runs confirmed the required failure directions: `36213861303`
(soak failure) passed the downloaded-evidence verifier; `36213859780`
(functional failure) and `36213862382` (explicit cancellation) removed owned
resources and preserved JFR but failed the probe's signal-receipt check. The
runner signaled the shell entry process, so the observation step now uses
`exec python3` and immediately hands cancellation to its independently supervised
controller. The always-run cleanup step waits for completion. This follows
[GitHub's documented cancellation signal sequence](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-cancellation).
The original incomplete proofs remain retained. Also, whole-workflow cancellation
can mark an unstarted publication job `cancelled`; verification requires that it
has no executed steps and no publication-stub artifact.

With the direct entry process, `36214152174` passed functional-failure native
cancellation and all cleanup/evidence checks. Explicit-cancel run `36214153690`
received the signal but exposed a second termination from the always-run cleanup
step, which interrupted the controller's teardown. The probe now records one
shared stop request; subsequent cleanup invocations wait rather than sending a
second signal. That failed run remains preserved and requires a fresh proof.

The first all-pass scenario, `36213863486`, did not pass: the real development
workload timed out during its plateau, and aligned delivery evidence classified
application overload. The functional stub succeeded, the soak failed, and the
publication stub was skipped. This is retained as failed workload evidence;
there is still no successful all-pass native publication-stub proof.

The idempotent handoff passed explicit cancellation in `36214387610`: the live
observation received the runner signal, the controller remained inconclusive,
all owned resources were removed, JFR/HTTP evidence was retained, and the unstarted
publication stub had no steps or artifact. Native cancellation now has terminal
verified evidence for functional failure (`36214152174`), soak failure
(`36213861303`), and explicit cancellation (`36214387610`). The all-pass scenario
and final release-workflow integration remain outstanding.


### Provisional v2 coverage and resource calibration

Capacity run `36213189453` completed a clean 21-minute step at 5 journeys/second
on v1, then lost application responsiveness at 10/second and failed final
collection. Its 3/second recommendation could provide only 27 observations for
the rarest operation in the first comparison window; it is ineligible for
baseline trials. The failure and raw measurements remain retained.

The provisional v2 profile assigns the application 3 CPUs, 2 GiB heap and 4 GiB
container memory, MySQL 0.5 CPU, the generator 0.25 CPU and the collector 0.25 CPU.
The earlier clean step showed low database/generator CPU consumption and substantial
application work. These revised allocations still require measured headroom.
The journey mix stays fixed. Each report, query-variant and expected-failure
journey executes four actual request sequences, with independent assertions and
unique ownership tokens for each repeated write/recovery. Journey counters still
count one arrival; operation counters count only completed requests. Historical
profiles without `coverageRepeats` retain one sequence.

The latency floor stays at 200 observations per operation per comparison window.
The capacity feasibility check now accounts for those real repeated operations;
actual window counts still decide validity. The full schedule and failure checks
are unchanged. This workload/resource revision invalidates prior calibration:
fresh capacity, full trials and detector proofs are required. No v2 baseline is
accepted, and the release gate remains disabled.

Baseline acceptance requires a separate `late-latency` detector reference as well
as sustained latency. A passing sustained-fault proof cannot substitute for the
required final-window behavior. Missing either reference blocks qualification.


The local v2 development run `development-v2-20260925` passed all traffic and
resource checks: all 901 offered plateau journeys completed. Its separately
retained coverage verification matches four actual HTTP sequences to every
repeated journey. This short run does not satisfy retained-memory duration.
CI capacity `36215259336` failed the first 5/second step after a high-fanout graph
request timed out. The GC log records 680 individual allocation stalls, up to
2.55 seconds, and sampled heap occupancy reached the 2 GiB maximum. After load
stopped it fell to roughly 120 MiB. This supports an allocation-pressure
investigation, not a retained-leak conclusion. Native all-pass run `36215301275`
also failed on a 1,000-row report timeout and failed final collector flush;
publication remained blocked. Both CI runners reported EPYC 7763 processors.

The analyzer now has a separate generational ZGC measurement method,
`jdk21-zgc-generational-major-periodic-jfr-v1`. It requires the exact generational
JMX collector set, explicit generational mode and a positive periodic **major**
collection interval. Only `After GC` summaries joined by ID to completed
`ZGC Major` events qualify; `ZGC Minor` events cannot fill missing observations
or hide retained growth. The earlier non-generational method remains available
for interpreting its historical evidence. The measurement pilot accepts
`--generational` to exercise the new method on fresh healthy, leaking and
late-leaking JVMs. Application adoption requires those real detector results.


The real `generational-pilot-20260925` passed all three expected outcomes:
healthy churn passed, sustained retained growth failed, and late growth remained
inconclusive. The v3 application profiles now select generational ZGC with a
15-second periodic major interval. CPU, heap, container budgets, workload and
request timeouts remain as in v2. The capacity workflow verifies the same three
measurement cases on its CI JVM before starting a fresh sweep and any eligible
full trials. This is a new calibration profile, not acceptance of the failed v2
runs. Generational collection targets the observed short-lived allocation pattern;
its application benefit remains to be measured ([Java 21 generational ZGC](https://inside.java/2023/11/28/gen-zgc-explainer/)).


### Provisional v4 ARM64 runner calibration

The generational measurement pilot passed on CI in `36216508204`, but the v3
capacity sweep still timed out on a graph request during its first 5/second step.
Native all-pass run `36216529683` failed on the same graph iteration. Its
application approached its 3-CPU quota and recorded allocation stalls while the
generator had headroom. Generational collection did not establish adequate
application capacity. Neither run qualifies a baseline or permits publication.

The next provisional profile uses `ubuntu-24.04-arm` and native ARM64 Java/images.
GitHub documents the same 4-CPU, 16-GB standard public-runner allocation for this
label ([runner specifications](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)).
Workload, request timeouts, sample floors, GC mode, heap and container budgets
remain those of v3. Local ARM development success motivates this experiment but
is not evidence for the hosted ARM machine. The actual CPU model, runtime image
and runner identity remain part of calibration; no x64 evidence is reused as an
ARM baseline. Fresh image reproducibility, measurement pilots, capacity, full
trials and application detectors are required. The release workflow template
selects ARM only for its soak row; its 23 functional rows are unchanged.


### Provisional v5 allocation headroom calibration

ARM capacity `36217622384` failed its first 5/second step; the repaired all-pass
probe `36217735768` timed out on a 1,000-row report. The latter recorded 249
allocation stalls, up to 1.19 seconds, and reached its 2 GiB heap limit. Its
Neoverse-N2 runner, generator headroom and completed cleanup are retained. ARM
alone did not resolve the capacity failure, and neither run is accepted.

V5 changes only the application memory budget from v4: a fixed 6 GiB heap inside
an 8 GiB container on the 16 GiB runner. CPU allocations, collector method,
request timeouts, sample floors and actual work remain fixed. This tests the
allocation headroom needed while concurrent collection runs, following the
[ZGC heap-sizing guidance](https://docs.oracle.com/en/java/javase/21/gctuning/z-garbage-collector2.html).
It is an explicit calibration experiment on the pinned diagnostic candidate;
release candidates never trigger automatic budget increases. All memory and
latency acceptance still requires fresh capacity and three full healthy trials
under the new immutable profile. The live release gate remains disabled.


### First successful v5 native all-pass proof

CI run `36218396157` passed, and its downloaded artifact verifier passed every
native matrix check. The soak completed all 901 offered plateau journeys;
traffic and resource assessments passed, all owned resources were removed and
the final recording was preserved. Its functional stub overlapped live HTTP/JVM
work and succeeded. The publication stub executed only after both rows passed,
with no provider calls. This proves the diagnostic two-row all-pass path, not
the disabled 24-row release integration or a full qualification.

No allocation stalls were recorded in this short run. Application median CPU
was 71.2% of its quota and maximum container memory was 88.3% of its budget.
The six 30-second 1,000-row report p95 values ranged from 1,180 to 1,543 ms.
These are observed development measurements, not accepted absolute budgets.
Capacity and full retained-memory/latency trials remain required.

Local saturation diagnostics independently proved application overload after a
3-to-1 CPU quota change (`saturation-v4-20260925/application`) and generator-only
capacity exhaustion from bounded CPU work (`saturation-cpu-work-v5-20260925`).
Both verified cleanup and recording preservation. The first tiny-generator-quota
experiment is retained as failed detector evidence because it also caused HTTP
timeouts. The final CI suite additionally binds the generated CPU-work script
by hash and must pass both cases before its evidence can be reviewed.


### Provisional v6 standard-runner report sizes

V5 capacity `36218384344` completed a clean 5/second step, with application median
CPU at 80.1% of its quota, then failed at 10/second. Its conservative target of
3/second provides only 108 observations for the rarest first-window operation.
Full trials correctly refused that target; no sample requirement was waived.
The clean short/native result does not make this a viable release profile.

The default v6 profile explicitly reduces report sizes to **25, 100 and 250**
rows. All three still hydrate Quick entities, serialize projections, validate
fixture checksums and have separate 200-sample latency requirements. The prior
100/500/1,000-row workload is preserved as
`profiles/lucee6-serial-large-reports.json`; its report scope is not claimed by
a future default-profile pass. The API and HTTP contract smoke test support all
five bounded sizes. Historical profiles without `reportSizes` retain the original
three limits, and duplicate, unsupported or unordered selections are rejected.

The large seeded domain, 180-comment high-fanout relationship graph, fixed
journey mix, four real repeated report/variant/failure sequences, exception paths,
resource budgets, 60-minute schedule and all acceptance thresholds stay fixed.
This reduces work per report request rather than reducing the number of measured
requests. Fresh capacity and detector proofs are required for the new profile;
all previous failed or successful measurements remain evidence only for their
recorded inputs. No baseline or release gate is enabled by this change.

### Native artifact transport and contended publication guards

Runs `36219423715` and `36219423717` both passed their downloaded native
verifiers. Their workflows overlapped on the same commit, and the second
validation completed while the first publication guard held its 180-second
lease. The provider job intervals and recorded stub bodies did not overlap.
Both publishers waited for every validation job, downloaded the actual tested
ZIP and verified its copied bytes against SHA-256
`60477d696d1b7e46e72506a59207ec716c4d180fac9b7e4a99c4fc956b48b881`.
The combined verifier passed in
`tests/results/soak/native-serialization-v5-20260925/verification.json`.
These are diagnostic two-row proofs with no provider writes; the full release
matrix and a qualified publication remain separate acceptance requirements.

### Provisional v7 collector headroom

The local v6 development run stopped because the observer JVM exhausted its
128 MiB Java heap. Docker reported exit 1 without a container OOM kill; the
collector log contains `OutOfMemoryError: Java heap space`. Replaying the
retained 25 MiB JFR file alone reached approximately 124 MiB of Java heap,
leaving little headroom for live JMX and streaming. This is an observer failure,
not proof of an application leak. The incomplete run is retained as failed
evidence and cannot become a baseline.

V7 gives the collector an explicit 512 MiB heap inside a 768 MiB container,
keeping its 0.25 CPU quota. The collector records its own maximum, used and
committed heap; resource validation requires the configured maximum and valid
usage samples. A collector process failure is inconclusive and still blocks
qualification. Application/DB process failures retain their failure outcome.
The application workload, application resources and acceptance thresholds are
unchanged from v6. This measurement-resource change requires fresh capacity,
full trials and detector evidence before baseline acceptance.

CI capacity `36219732077` independently reproduced the v6 observer heap OOM:
the 5/second step passed, then the observer stopped during 10/second. The
completed 5/second step used a median 33.9% of the application's CPU budget,
but incomplete observer evidence prevents selecting a calibration target.
Local development evidence `development-v7-20260925` completed all 901 offered
plateau journeys with traffic/resources passing, a final recording and cleanup.
Its collector peaked at 194.9 MiB of Java heap. This run used the v7 resource
draft before the final observer-loss classification/heap-validation edits;
its retained source snapshot records that distinction. It is neither a full
memory qualification nor CI baseline evidence.

The live `collector-failure-v7-20260925` probe passed every check after sending
SIGKILL to its owned collector during completed HTTP work. The controller
returned inconclusive, identified observer loss and the incomplete final
recording, retained the earlier recording/HTTP/JVM samples and removed owned
containers, named/anonymous volumes and network. The same probe is included in
future diagnostic CI runs through `--mode collector-stop`.
The paired `controller-cancellation-v7-20260925` run also passed the normal
SIGTERM path, including a clean collector end marker, final recording and full
owned-resource cleanup.

### Complete v5 CI detector evidence

Run `36218946123` completed successfully. Its downloaded application artifact
(`ci-36218946123-application/fault-suite/verification.json`) verifies all five
fresh cases: healthy control passed; held JDBC connection, wrong response
contract and sustained latency failed for their required reasons; final-window
latency was inconclusive with the exact late-regression reason. Every case
passed its cleanup/recording and same-harness checks. The paired container
cancellation proof also passed. Its separate saturation artifact verifies both
application-overload and generator-capacity attribution, and the measurement
job passed healthy, retained-growth and late-growth pilots. This is complete
diagnostic evidence for v5, not an accepted v7 baseline or a full healthy trial.

### V8 configured versus usable observer heap

V7 capacity `36220760764` completed correct traffic at 5/second but rejected the
resource evidence solely for `collector-heap-budget-mismatch`. Its observer
stayed alive and flushed cleanly. The new check incorrectly equated configured
`-Xmx` with `Runtime.maxMemory()`: the CI observer returned 518,979,584 usable
bytes for a 536,870,912-byte limit. A real Java 21 reproduction with Serial GC
returns those exact values; G1 returns 536,870,912 for both.

V8 records the observer's actual `MaxHeapSize` VM option through
[HotSpotDiagnosticMXBean](https://docs.oracle.com/en/java/javase/21/docs/api/jdk.management/com/sun/management/HotSpotDiagnosticMXBean.html),
its usable maximum and GC names separately. Resource analysis requires the
configured option to equal the declared 512 MiB, then requires usable maximum
and samples to stay within their respective bounds. The test covers Serial's
actual CI values and rejects usage above its smaller usable maximum. No budget,
workload, duration, sample floor or acceptance threshold changes. The rejected
v7 run remains evidence of the validator defect; fresh v8 calibration is required.

### V8 capacity result: sample-ineligible target

Run `36221908906` completed collection and a clean 5/second step. At 10/second,
traffic stayed correct and resources passed, but the single capacity window
detected sharp p95 increases relative to 5/second: graph 1,074 to 1,495 ms,
100-row report 123 to 313 ms, and 250-row report 288 to 583 ms, among others.
The step was inconclusive under the late-latency rule and was not accepted.
Application median CPU rose from 33.7% to 82.4% of its quota; generator median
at 10/second remained 26.0% of its own quota. Observer heap accounting and final
collection passed. This is not another observer OOM or generator limitation.

The resulting 60%-of-clean target is 3/second, with only 108 expected samples for
the rarest first-window operation. Full trials rejected it before provisioning;
no baseline trial started and no sample floor or latency threshold was waived.
The current v8 workload remains unaccepted. The repository reports zero
configured self-hosted runners, and the organization API reports larger hosted
runners unsupported. Fixture sizing or additional CI capacity must be resolved
before a fresh complete calibration can establish a release baseline.

### Complete v8 CI detector and interruption evidence

[Run 36221908854](https://github.com/coldbox-modules/quick/actions/runs/36221908854)
completed successfully on diagnostic commit
`9c19d0672fe2ef6a747dc1e1c7a02ca59d871fe2`. Its downloaded application artifact
is retained in `tests/results/soak/ci-36221908854-application/`. The complete
five-case verifier passed, with raw summaries confirming:

- Healthy control: 901/901 plateau journeys, traffic/resources passed, no reasons.
- Held connection: 900/900 journeys; the final and idle JDBC-active checks failed.
- Wrong contract: the exact response-body assertion failed while the HTTP-status
  metric remained green; the controller stopped before plateau traffic.
- Sustained latency: 900/900 journeys, healthy resources, and only
  `sustained-latency-regression:report_100` in the summary reasons.
- Late latency: 901/901 journeys, healthy resources, and only
  `late-latency-regression-needs-observation:report_100`; outcome inconclusive.

All five cases retained a final recording and clean collector end marker, used
the same harness, and passed owned-container, named/anonymous-volume and network
removal checks. The healthy observer recorded the expected 536,870,912-byte
configured limit and 518,979,584-byte usable maximum; resource validation passed.

The live controller-cancellation proof also passed: signal 15 produced an
inconclusive canceled result with a clean end marker and final recording.
The live observer-loss proof killed the collector with exit 137, produced an
inconclusive aborted result, explicitly identified observer loss and incomplete
final recording, retained the earlier 7,538,962-byte recording plus HTTP/JVM
samples, and verified removal of all owned resources. Both verification JSON
files passed every check.

The same workflow's separately downloaded measurement and saturation artifacts
(`ci-36221908854-partial/`) verify healthy/sustained-growth/late-growth outcomes
and correct generator-versus-application overload attribution. These complete
the v8 diagnostic evidence. They are development/controlled-fault proofs, not
full 60-minute healthy trials, an accepted baseline, or full release-matrix
qualification. The capacity rejection above remains unresolved.

### Provisional v9 standard-runner relationship fanout

The user approved reducing the high-fanout relationship fixture for the standard
GitHub runner after v8 capacity could not support the required sample floor.
V9 assigns 60 comments to the hot post instead of 180 and redistributes the
remaining comments across the other nonempty posts. The total 50,000 comments
(45,000 Post and 5,000 User), all other table counts, polymorphic cases, empty
relationships, five-post graph shape and journey mix remain intact. Reports
still use 25/100/250 rows. The optional larger-report profile retains 180-comment
fanout and its original report sizes; its scope is not covered by the default.

`fixtures.highFanoutComments` is validated, passed through the real seed task,
checked against the generated manifest and bound into measurement identity.
The generator's default 180-comment SQL retains its historical checksum; the
60-comment fixture has a distinct checksum and must be recalibrated. Tests
inspect actual SQL rows for counts and distribution, rather than trusting only
the manifest. Both profiles preserve deterministic report checksums and pivots.

Resource budgets, the 60-minute schedule, sample floors, latency/memory rules,
and the 60%-of-clean capacity policy are unchanged. Fresh capacity, three full
trials and detector proofs are required before acceptance. No previous v8 pass
is reused as a v9 baseline, and the live release gate remains disabled.

The local `development-v9-fixture-20260926` run completed all 900 offered
plateau journeys with traffic/resources passing. Its real MySQL query confirms
45,000 Post comments, 5,000 User comments, 60 comments on the hot post and zero
on the empty post. `development-verification.json` verifies the declared fanout,
final recording, clean collector end marker and removal of owned containers,
named/anonymous volumes and network. Memory remains inconclusive for the short
development schedule. The earlier `development-v9-20260926` attempt supplied a
mistyped candidate SHA and stopped before provisioning; it is retained separately.

V9 CI calibration `36241479101` and diagnostics `36241478992` test commit
`cc695d76f3ba9eeaf19c9f8f3b756a2a893c70c7`. The completed measurement artifact
(`ci-36241478992-measurement/`) confirms healthy memory passed, sustained retained
growth failed, late growth was inconclusive, and live cancellation stopped both
children while retaining partial evidence. Capacity, full trials and application
detector results remain pending; this completed job is not a full workflow pass.

The completed v9 saturation artifact (`ci-36241478992-saturation/`) also passes
both cases. Its raw generator summary is inconclusive with
`delivery-generator-capacity-exhausted`, a real workload shortfall and no
incorrect responses. Its application case fails with
`delivery-application-overloaded` and the observed incorrect/error responses.
Both cases verify their controlled injection, restoration of the diagnostic
quota, final recording/collector flush and removal of all owned resources.
