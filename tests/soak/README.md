# Release soak harness

Implementation of [the release soak plan](../../docs/release-soak-testing-plan.md).
This is under construction. The required release gate is **not enabled** and no
accepted baseline exists yet. A short local pilot or HTTP smoke pass does not
qualify a package for publication.
The [acceptance checklist](ACCEPTANCE.md) maps all nine plan items to current
evidence and outstanding requirements.

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
budgets. Its repository rate remains unaccepted. Without `--development`, this
diagnostic command can collect that schedule but cannot qualify a release.
Accepted-baseline comparisons and receipts use the separate `qualification.py`
entry point described below; ordinary diagnostic runs never become release passes.

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
The default output is `tests/results/soak/<run-id>/`; `--output` selects a new
directory instead.

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

## CI calibration

Use **Soak capacity calibration (no publication)** in
`.github/workflows/soak-capacity.yml`. It uses the standard four-core
`ubuntu-24.04-arm` runner and the serial profile in `profiles/lucee6-serial.json`.
The current workload has 25/50/100-row reports and 30-comment hot-post fanout;
the five-minute warmup, five-minute ramp, 40-minute plateau, five-minute recovery
and five-minute idle schedule remains fixed.

Before the workflow reaches the default branch, dispatch the reviewed harness
commit using a unique diagnostic tag. The tag path uses the workflow's pinned
healthy candidate, currently `af2c93d2604de73d7ccac23b7bf69c4be221dbb0`:

```sh
SOAK_CALIBRATION_TAG=soak-calibration-my-reviewed-run
git tag "$SOAK_CALIBRATION_TAG" HEAD
git push origin "refs/tags/$SOAK_CALIBRATION_TAG"
```

Choose a new tag name for each intentionally distinct run; retain failed and
partial attempts. Manual dispatch exposes `candidate` (a full healthy commit SHA)
and `trials` (set true for baseline calibration). A `soak-capacity-*` tag runs
only the sweep; a `soak-calibration-*` tag also runs three full trials, stopping
on failure. The sweep selects an eligible target with measured headroom and
coverage. Each trial uses a fresh application and database. Nothing publishes
or accepts a baseline automatically.

Actions artifacts are `soak-runner-<SHA>-<attempt>`, one
`soak-trial-<number>-<SHA>-<attempt>` after each trial, and
`soak-capacity-<SHA>-<attempt>` with the complete retained evidence. The last
artifact contains `capacity/`, available `trial-1/` through `trial-3/`, and a
baseline proposal only when all three trials permit it. Artifacts have 30-day
retention; accepted evidence must be archived before expiry. Current run handles
and verification scope are in [ACCEPTANCE.md](ACCEPTANCE.md).

Review a downloaded, completed full trial from the repository root:

```sh
python3 tests/soak/review_trial.py \
  --run PATH_TO_DOWNLOADED_TRIAL \
  --output NEW_REVIEW_JSON
```

This offline command checks recorded analyzer versions, measurement identity
and capacity/package identity, records raw-input hashes, then recomputes all four saved
traffic, delivery, resource and memory assessments. Passing calibration trials
also require a valid evidence seal. It reports exact and rounded early p95,
observation gaps, idle-transition timing and recording completeness. Exit zero
means the saved results reproduce; an inconclusive or failed trial remains so.
It cannot accept a baseline or qualify a release. Partial trials need separate
diagnosis, and existing review files are never overwritten.

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
workflows. Capacity selection and full baseline trials use the separate CI
calibration entry point above; completed full calibration remains pending.

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

Method ID: `jdk21-zgc-generational-major-periodic-jfr-v1`. The provisional v12
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
baseline occupancy through `qualification.py`, but no accepted reference exists
yet. The short development plateau correctly leaves this
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
30 for the standard/parallel profiles, 180 for the larger-report profile.
The standalone generator accepts `--high-fanout-comments 30`; omitting it retains
the historical 180-comment SQL. The seed task's corresponding optional input is
`:highFanoutComments=30`. Profile and fixture identities record the choice.
The SQL deliberately uses `CREATE DATABASE`, never `DROP` or `TRUNCATE`: an
existing database causes setup to fail. Seed records occupy IDs through 10,000;
scratch posts start at 1,000,000 and missing IDs start at 2,000,000,000.

For an already provisioned disposable MySQL container with an empty schema,
the CommandBox setup task creates and seeds the database once:

```sh
SOAK_MYSQL_ROOT_PASSWORD="$YOUR_DISPOSABLE_ROOT_PASSWORD" box task run \
  taskFile=tests/soak/Seed.cfc :container=quick-soak-your-run-id \
  :output=tests/results/soak/YOUR-RUN-ID/fixtures :highFanoutComments=30
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
version and must not produce a publishable package. The separate validation
builder below preserves full testing without permitting publication. The integration verifier uses
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
repository-wide native concurrency guard; the staged integration still requires
full native proof and activation. Fake-provider tests prove rejected evidence causes zero provider calls
and a rebuilt package cannot replace the qualified ZIP between checks. Do not wire
the directory publisher behind the new gate.

`qualification.py --baseline ACCEPTED_JSON --profile PROFILE_JSON --package
PREPARED_DIRECTORY --candidate FULL_SHA` is the explicit candidate gate entry
point. There is no accepted baseline checked in yet. It requires a reviewed
proposal with three distinct sealed CI trials, durable evidence and detector
references, and an absolute budget for every operation. It verifies matching
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
The staged workflow selects this path when preparation reports no release;
full native no-release validation remains an acceptance requirement.

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

The no-release native scenario needs a candidate that contains the accepted
baseline and current harness but prepares no new version. The pinned
semantic-release filter only removes the version-update marker; a `docs:` or
`test:` commit does not establish that condition. For this diagnostic, use
`git commit-tree` to make a separate commit with the accepted source tree,
the provider-verified last release as its sole parent, and the exact message
`__SEMANTIC RELEASE VERSION UPDATE__`. Record both source commit/tree and
diagnostic commit, verify tree equality, then run the ordinary `prepare.py`
and `validate_candidate.py build` commands. Require `noRelease: true` and
`validationOnly: true` before dispatching an `all-pass` diagnostic tag.
Do not move the implementation branch or an existing release tag. The full
proof deliberately removes the release-marker skip condition, allowing this
candidate to execute all 23 functional rows and the complete soak; the live
release workflow keeps its existing skip condition.

The local rehearsal in `no-release-current-tree-20260926/verification.json`
used source commit `418ee99` with live provider identity reads and the actual
semantic-release 4.1.0 APIs. It produced a verified 49-file validation package
and rejected the same preparation through the publication builder. Git refs
were unchanged. This proves preparation and packaging only; that diagnostic
commit has no accepted baseline and was not dispatched. Recreate the candidate
from the accepted tree before running the required full native proof.

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
and owned-resource cleanup. Failure proofs also require exactly 25 jobs, including
the named publication stub: a missing stub or an unexpected extra job cannot
establish blocked publication. Both malformed evidence cases reproduced before
the verifier fix; all 59 release tests pass afterward, with Pyflakes and generated
workflow drift checks clean. Evidence is in `full-proof-verifier-20260926/`.
These full-matrix scenarios are staged and unit
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

- Complete fresh v12 calibration with continuous observation on the standard
  GitHub runner. V11 trial `36246554787` completed all 14,401 journeys and passed
  retained-memory checks, but a 15.222-second application telemetry gap made
  resources inconclusive. Independent v11 run `36248290534` reproduced that
  outcome with a 15.239-second gap. Both inconclusive trials remain retained.
  Primary v12 run `36252125924` is in its first full trial; independent host
  calibration `36254251872` uses the same measured source and profile.
- Review the completed v12 diagnostic evidence alongside full-trial results
  before accepting a baseline. Run `36252126235` passed measurement, saturation,
  all application faults, cancellation and observer loss; independent raw
  reanalysis matches. Short diagnostic results do not establish full-trial
  qualification, and every earlier attempt remains retained.
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

The following entries are chronological history, including superseded profiles
and the observations that prompted each change. Their pending-state statements
describe that milestone. Use [ACCEPTANCE.md](ACCEPTANCE.md) for current status and
the operational sections above for current commands.

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

V9 diagnostics `36241478992` subsequently completed successfully. Its downloaded
application artifact (`ci-36241478992-application/`) passes the complete five-case
fault suite and both interruption probes. The healthy, sustained-latency and
late-latency cases each completed 901/901 plateau journeys; the held-connection
case completed 900/900 and failed only the final/idle JDBC-active checks. Wrong
contract failed the intended assertion before plateau. Both latency cases have
only their exact sustained/late report-100 detector reason. All fault cases and
both interruption probes passed their recording and owned-resource cleanup checks.
This completes v9 diagnostic proof but does not change its rejected capacity target.

### V9 capacity result and provisional v10 report calibration

Capacity `36241479101` completed collection cleanly. The 60-comment graph no
longer crossed the sharp-latency threshold at 10/second: its p95 rose from
479 to 569 ms (18.8%). Application median CPU was 27.8% of quota at 5/second
and 71.0% at 10/second; generator medians were 7.4% and 22.1%. Resources passed.
The remaining rejected operations were the 100-row report (117 to 175 ms) and
250-row report (283 to 373 ms). Both crossed the relative and absolute latency
thresholds, leaving the highest clean step at 5/second and the proposed target
at 3/second. That target provides only 108 rare-operation samples in the first
window; full-trial preflight rejected it. No full baseline trial started.

Continuing the approved workload reduction for the standard GitHub runner,
v10 uses **25, 50 and 100** report rows while retaining 60-comment graph fanout.
The 50-row report still hydrates real Quick entities, validates the complete
projection and deterministic checksum, and has its own 200-sample latency floor.
The existing larger report sizes remain available, and the optional larger-report
profile retains 100/500/1,000 rows with 180-comment fanout. A default-profile pass
does not establish that larger profile's behavior.

The seeded domain, journey percentages, four real repetitions, exception paths,
resource budgets, full 60-minute schedule and all acceptance thresholds remain
unchanged. Fresh capacity and detector evidence are required; failed v9 evidence
is retained in `tests/results/soak/ci-36241479101/` and is not retried unchanged.

The local `development-v10-reports-20260926` run passed all 900 offered plateau
journeys with traffic/resources passing and no summary reasons. All three report
sizes received samples in all six development windows; the new 50-row report
passed the same projection/checksum contract. `development-verification.json`
confirms the declared 60-comment fixture, report-window coverage, final recording,
clean collector flush and removal of owned containers, named/anonymous volumes
and network. Its short memory assessment remains inconclusive.

V10 calibration `36242953744` and diagnostics `36242953890` test commit
`fe1eb954ba735c1e1a0bad03b76a32daa0762a14`. The downloaded measurement artifact
(`ci-36242953890-measurement/`) confirms the expected healthy, sustained-growth
and late-growth outcomes, plus successful live cancellation and retained partial
evidence. Capacity/full trials and application detectors remain pending; the
release gate is still disabled.

V10's first saturation suite (`ci-36242953890-saturation/`) verifies generator
exhaustion, but its application injection was too weak: reducing the application
to one CPU still completed all 901 offered journeys with correct traffic and
healthy resources. The suite correctly rejected this as overload-detector proof;
the application was never overloaded. That failed attempt remains retained.

The diagnostic application injection now uses 0.25 CPU only after normal startup
and warmup, then restores the original quota before cleanup. This changes neither
the three-CPU release profile nor the workload or acceptance thresholds. The
helper is outside measured-source identity; the existing v10 capacity run remains
valid for its recorded inputs. `soak-saturation-*` tags run only the saturation
job in the diagnostic workflow so this controlled-fault correction can be tested
without restarting healthy calibration or the unrelated detector jobs.

### V10 eligible capacity and setup-identity correction

Calibration `36242953744` measured clean 5/second and 10/second steps, then
stopped increasing at the unclean 20/second step. Complete collection produced
an eligible **6 journeys/second** target (60% of 10), 216 expected samples for the
rarest first-window operation, and a 12-VU double-headroom requirement within
the declared 100 VUs. This is capacity evidence, not sustained-stability proof.

The first full trial provisioned a fresh application but stopped before workload
arrivals on `seedCommandBox` identity mismatch. Both runs used
`CommandBox 6.3.5+00887`; only the first invocation printed its one-time home/library
initialization banner. Identity now extracts exactly one version line while
retaining the original raw log. Missing/ambiguous versions are rejected, and real
version changes still require recalibration. Reanalysis of both actual setup
identities matches after this correction; the failed trial remains failed in
`ci-36242953744/`, with a separate `seed-version-identity-reanalysis.json`.

The local quarter-CPU overload probe ended on a diagnostic HTTP process timeout
before traffic analysis, so it supplies no passing attribution proof. Its raw
evidence remains in `saturation-v10-quarter-cpu-20260926/`. Diagnostic process
timeouts now omit authentication headers from exception output; they still fail
the run. This controller-source change requires fresh calibration and matching
detector evidence. No workload, resource budget, duration or acceptance threshold
has changed, and no full baseline trial has completed.


### Standard-runner hardware and reviewed baseline selection

Recorded `ubuntu-24.04-arm` hosts include both Neoverse-N2 and Neoverse-V3.
Their model/stepping and L2/L3 cache sizes differ; the label alone does not prove
comparable hardware. `v10-ci-host-comparison.json` retains the comparison of four
actual CI host records. N2 hosts otherwise matching the recorded runner image,
Docker/kernel identity and core count also differed by exactly 4,096 bytes in
Docker's host memory total (16,722,006,016 versus 16,722,010,112 bytes).

Identity comparison preserves and checksums every raw value. It permits only a
4,096-byte host-memory reporting difference when every other measured value is
identical. Container memory, JVM heap, CPU model/caches, image version, workload,
resources, dependencies and executed sources still match exactly. Qualification
records the signed difference and comparison policy in the sealed
`baseline-comparison.json`; verification recomputes that record.

The baseline entry point can be one accepted leaf or a catalog with schema 1,
status `accepted-catalog`, and `baselines` listing unique sibling JSON filenames.
Every leaf must independently contain three complete matching trials and the
existing explicit review, durable evidence, budgets and detector records. A
catalog selects exactly one reviewed leaf using the actual host identity before
provisioning; unknown hardware and ambiguous matches stop validation. Only the
selected leaf's calibrated arrival rate can replace the provisional profile rate.
All other workload and budget settings must already match. Artifact verification
requires that exact leaf checksum to remain a catalog member. The native release
proof verifier downloads the catalog and its leaves from the exact tested commit.

No catalog or accepted leaf has been created yet. The current v10 calibration
continues collecting evidence for its actual hardware; it cannot accept another
CPU model. This selection/comparison work does not change normal measured sources
or invalidate that running calibration.

The targeted quarter-CPU CI probe `36244253719` reproduced the local problem:
generator exhaustion was attributed correctly, but application diagnostic HTTP
timed out before traffic analysis. The failed attempt is retained under
`ci-36244253719-saturation/`. The next diagnostic injection uses half a CPU after
warmup, restoring the original allocation before cleanup. Its result is pending;
no application overload proof is claimed from the quarter-CPU attempt.


V10 diagnostics `36242953890` subsequently finished with only its weak one-CPU
saturation case failing. The complete five-case application fault suite, malformed
HTTP response contracts, controller cancellation and observer-loss verification
all passed. Sustained and late latency had only their intended report-100 reason;
the held connection failed only final/idle JDBC-active checks. The raw artifact
is retained in `ci-36242953890-application/`.

Commit `d1059d6` passes 118 telemetry and 57 release unit tests, Pyflakes and the
staged full-matrix workflow comparison. A subsequent receipt-verification test
also proves the hardware-comparison record is recomputed and that removing the
selected leaf from its catalog invalidates qualification. Applying the comparison
policy to the four real host records accepts the three N2 observations and
rejects V3, recorded in `v10-ci-host-policy-verification.json`.

Fresh diagnostics `36245768374` test that commit's half-CPU injection and current
normal measured sources. Calibration `36244968012` continues separately at
`734f112`, with the same normal measured sources. Neither running workflow is
completion evidence, and neither has accepted a baseline or qualified a release.


### Rendered report verification

The real `development-v10-reports-20260926/report.html` was inspected in headless
Chromium at 1440×1000 and 390×844. The title, visible qualification warning,
assessment details, latency tables and 16 charts render with meaningful content;
no page overflow, framework overlay or browser console errors were observed.
Following the Summary evidence link loads that run's actual `summary.json` at
both widths. This is browser rendering/interaction evidence, separate from the
previous comparison of table values and raw files.

The first mobile inspection found that SVG scaling made axis labels about six
pixels tall. Chart range/time labels now use ordinary HTML text at the report's
normal size; plotted data and numeric scaling are unchanged. A second desktop
and mobile inspection confirms readable labels and working evidence links.
The Impeccable detector reports no findings, and Pyflakes passes. Screenshots and
the temporary Playwright check are retained outside the repository under
`/tmp/quick-soak-report-*`; physical mobile devices and other browser engines were
not tested. Rendering occurs after measurement and is outside measured-source
identity, so this presentation-only change does not invalidate active calibration.


The measurement job in `36245768374` completed successfully. Raw JVM telemetry
was reanalyzed locally with the recorded pilot windows and matches every saved
assessment field: healthy passes, sustained growth fails, and late growth is
inconclusive with its exact expected reason. All six child exit codes are zero,
and each final recording is nonempty. Cancellation stopped both children,
retained partial evidence and never qualified the interrupted run. This proof
is saved in `ci-36245768374-measurement/raw-evidence-verification.json` and does
not stand in for the still-running application or full calibration work.


### V10 repeated capacity and provisional v11 fanout

Fresh calibration `36244968012` on Neoverse-N2 did not reproduce the earlier
eligible v10 rate. Complete collection recorded a clean 5/second step, then
an inconclusive 10/second step with the single blocking reason
`late-latency-regression-needs-observation:graph`. Graph p95 increased from
520 to 626 ms (20.4%, +106 ms). Reports at 25/50/100 rows changed from
44/76/141 to 49/93/190 ms and did not cross both blocking bands. Resources
passed at both rates. The resulting 3/second target supplies only 108 rare
first-window samples; full-trial preflight rejected it before provisioning.
The complete failed attempt is retained in `ci-36244968012/`. No full trial
started, and the earlier 6/second result is not treated as repeatable acceptance.

V11 continues the approved reduction for standard GitHub hardware by lowering
the hot-post fanout from 60 to **30 comments**. Total comments remain 50,000
(45,000 Post / 5,000 User); remaining comments are deterministically distributed
across the other populated posts, and the reserved empty post remains empty.
Thirty is still substantially above ordinary post fanout. Report sizes remain
25/50/100. The success/failure mix, timing, budgets, repetition and all numerical
acceptance thresholds are unchanged. The fixture generator retains explicit
60 and historical 180 options; the optional large-report profile retains 180.
Actual generated SQL, manifest counts, determinism and the historical SQL hash
are checked. Fresh development, capacity and detector evidence is required.


V10's half-CPU saturation probe in `36245768374` passed on Neoverse-N2. Raw
reanalysis reproduces both saved attributions: the generator case is inconclusive
with `delivery-generator-capacity-exhausted` (47 of 829 offered journeys
completed); application overload fails with `delivery-application-overloaded`
and observed response errors (60 of 94 completed before abort). Application
samples reached roughly 99% of the injected half-CPU allocation while generator
utilization remained low. Both cases retained flushed JVM telemetry/final JFR,
restored the diagnostic quota, and passed live CI owned-resource removal checks.
`ci-36245768374-saturation/raw-evidence-verification.json` records the reanalysis;
CI cleanup proof is taken from the original runner, not the local Docker daemon.

V11 commit `e458c93` passes 119 telemetry tests and starts fresh calibration
`36246554787` and diagnostics `36246858832`. The local
`development-v11-fanout-20260926` run has a direct database fixture check confirming
45,000 Post comments, 5,000 User comments, hot-post count 30 and empty-post count
zero. Its workload is still running. The v10 probe does not substitute for
matching v11 detector evidence, and no full baseline trial has completed.


The local v11 development run subsequently passed all 901 offered plateau
journeys. Traffic and resource assessments pass with no summary reasons; memory
remains inconclusive on the short schedule. Each selected report size has
samples in every development comparison window and meets its development sample
floor. `development-verification.json` confirms real SQL fixture counts,
manifest/profile agreement, preserved domain size, complete arrivals, clean
collector flush/final recording, and removal of owned containers, named/anonymous
volumes and network. This is development proof only; v11 CI calibration and
matching diagnostics are still running.


The v11 measurement job in `36246858832` passes. Downloaded raw JVM telemetry
reproduces every saved healthy/sustained-growth/late-growth assessment, all target
and collector exit codes are zero, and final recordings are retained. The live
cancellation probe stopped both children and retained partial evidence without
qualification. `ci-36246858832-measurement/raw-evidence-verification.json` records
this completed milestone; application diagnostics and capacity remain pending.

A comparison of both v10 capacity artifacts confirms greater application pressure
in the rejected repeat: median quota use at 10/second rose from 64.3% to 75.3%,
while generator use rose only from 22.0% to 23.9%. Both were Neoverse-N2 with
passing resource assessments. `v10-repeated-capacity-comparison.json` retains
these values and graph p95 evidence. The earlier green step is not used to
dismiss the repeat's latency failure or justify accepting v10 unchanged.


### Readable traffic report coverage

The report now exposes the plan's previously raw-only traffic evidence: configured
journey rate, total HTTP requests from plateau journeys including drain,
windowed journey/HTTP completion rates, per-operation verified-request totals and
descriptive p99, and sampled active application requests (including diagnostics).
P99 uses streamed, bounded 1 ms histograms; success and expected-failure labels
remain separate. It does not add a release gate. Incomplete runs show rates as
unavailable instead of dividing partial traffic by the planned full duration.

On the actual v11 development artifact, all 5,122 HTTP requests match both the
verified-operation totals and descriptive latency sample counts. The six
30-second windows record 5.00 journey completions/second and alternating
28.40/28.50 HTTP completions/second. `report-traffic-verification.json` preserves
this cross-check. All 121 telemetry tests pass, including phase separation and
incomplete-run reporting. Pyflakes and the Impeccable detector pass.

Rendered Chromium checks at 1440×1000 and 390×844 confirm meaningful page content,
readable rates/p99 tables and active-request charts, no overflow or browser errors,
and a working Summary evidence link. Screenshots and the temporary browser check
remain under `/tmp/quick-soak-report-v11-*`. Physical mobile devices and other
browser engines remain untested. This post-measurement report work changes no
workload, instrumentation or acceptance threshold and leaves active calibration
comparable.


V11 saturation attribution in `36246858832` passes on Neoverse-N2. Raw reanalysis
reproduces the generator-capacity classification (47 of 828 offered journeys
completed) and application-overload failure (58 of 94 completed before the hard
response-error abort). The application injection was 0.5 CPU; the generator
probe used bounded CPU work at its normal 0.25 CPU allocation. Both cases restored
the recorded quota, retained flushed JVM telemetry and final JFR, and passed
original-runner cleanup checks. The downloaded evidence and independent
attribution comparison are under `ci-36246858832-saturation/`. This completes
matching v11 saturation proof; full application diagnostics and calibration
remain in progress.


### Inspecting long calibrations and runner variation

New capacity workflow runs upload the public runner identity before toolchain
setup and retain each complete or partial trial immediately after that trial's
step. Three separate trial steps preserve stop-on-failure behavior; proposal
generation requires all three to succeed. A preflight rejection may create no
trial directory, so that immediate upload can be empty; the original final
always-upload still retains capacity evidence and every existing trial directory.
The workflow passes actionlint. These orchestration changes leave the runtime,
workload, sampler and comparison inputs unchanged.

V11 calibration `36246554787` advanced from the completed capacity sweep to the
three-trial step at 14:19:27 UTC. The step's status is not proof of completed
workload or a passing full trial. One independent calibration on another standard
runner will provide additional evidence about between-runner variation. Both
attempts and any differing CPU identities must be retained and evaluated before
baseline acceptance.


Independent v11 calibration `36248290534` runs commit `0ce62ec` on a fresh
four-core Neoverse-N2 host, with runner image `ubuntu24-arm64` version
`20260920.129.1`. Its immediately available `soak-runner-*` artifact is retained
under `ci-36248290534-runner/`. The first calibration remains in its three-trial
step. Neither run has completed a full trial yet; the independent attempt is
additional evidence for runner variation, and every outcome remains part of
acceptance review.

### Completed v10 application diagnostic evidence

The full v10 diagnostic workflow `36245768374` passed. Downloaded raw k6 data for
all five application cases reproduces every field of the saved traffic analysis
with the identical recorded analyzer source. Healthy and held-connection cases
completed 900/900 plateau journeys; only the held connection failed final/idle
JDBC-active checks. The wrong response contract failed during warmup. Sustained
and late latency cases each completed 901/901 journeys and produced their exact
blocking and inconclusive reasons respectively. Original CI verification also
passed HTTP contracts, controller cancellation, observer loss, recording
retention and owned-resource cleanup. Those cleanup checks ran on the original
runner; local raw-data reanalysis does not repeat them. Evidence is retained in
`ci-36245768374-application/`, including `raw-evidence-verification.json`.
This completes v10 detector evidence; v11 still requires its matching application
result and full calibration.

### Completed v11 detector evidence

Diagnostic workflow `36246858832` passed all three jobs. Downloaded application
evidence under `ci-36246858832-application/` contains the matching 30-comment,
25/50/100-row profile in every case. Raw k6 reanalysis with the recorded analyzer
source reproduces every saved traffic-analysis field. Healthy traffic completed
901/901 journeys. The held-connection case completed 900/900 and failed only
final/idle JDBC-active checks. Wrong-contract detection stopped during warmup.
Sustained latency completed 900/900 and failed for the intended report regression;
late latency completed 901/901 and was inconclusive for its intended final-window
regression. Flushed JVM data and nonempty final JFR files are present for all five
cases. Original CI verifications passed malformed HTTP contracts, controller
cancellation, observer loss, partial evidence retention and owned-resource
cleanup. The raw-data verification records that remote cleanup was checked on
the original runner, not repeated against the local Docker daemon.

Together with the previously reanalyzed measurement and saturation artifacts,
this completes matching v11 detector proof. Full calibration, accepted baselines
and the native full release-matrix proofs remain outstanding.

### V11 full-trial result and v12 continuous observation

Run `36246554787` selected 6 journeys/second from a clean 10/second capacity step
on Neoverse-N2. Its first full trial completed 14,401/14,401 plateau journeys,
including the permitted completed boundary arrival. Traffic passed; retained
memory passed with 155 usable major cycles and 36 MiB late-versus-early growth,
below the unchanged 307.2 MiB band. Raw reanalysis reproduces traffic, memory and
resource results exactly in `ci-36246554787/raw-trial-diagnosis.json`.

The trial remains inconclusive: one application observation gap was 15.222 seconds
against the declared 15-second maximum. Every other gap was at most 10.020 seconds.
The gap ended at idle start, after 5.146 seconds of synchronous traffic-file
analysis followed the normal ten-second sample interval. The controller now
starts idle observation immediately after successful generation and defers full
traffic analysis until idle sampling and final diagnostics finish. Failed
generation is still classified and aborted promptly. Delivery classification
uses the original workload observations, excluding subsequent quiet idle samples.

Independent run `36248290534` completed its full trial on another standard N2
runner and reproduced this outcome: 14,401/14,401 journeys, passing traffic and
retained memory, and one 15.239-second resource-observation gap ending 1 ms after
the idle marker. Synchronous analysis took 5.162 seconds. All three saved
assessments match raw reanalysis in `ci-36248290534/raw-trial-diagnosis.json`.
Its memory growth was -36 MiB across 155 usable major cycles. Both v11 trials
remain inconclusive. `v11-full-trial-comparison.json` retains their early p95
comparison: the only rounded operation above 10% spread is empty-lookup failure at
9 versus 10 ms. This diagnostic comparison does not accept a baseline or waive
the required investigation of fresh v12 trial variation.

`v11-latency-quantization-investigation.json` separately derives nearest-rank p95
from the original request timings, using the same two early plateau windows and
boundary exclusions. All 21 operations reproduce their saved sample counts and
rounded p95 values. Rounding to whole milliseconds crosses the 10% noise boundary
in both directions: empty-lookup spread is 9.80% raw versus 10.53% rounded, while
relationship-failure spread is 10.70% raw versus 9.52% rounded. Review of fresh
baseline trials must inspect both representations and investigate discrepancies.
This observation changes neither the automated proposal criteria nor the 10%
limit, and does not rehabilitate either inconclusive trial.

The regression test inserts a 20-second analyzer delay: it reproduces the exact
telemetry-gap failure on the old controller and passes on the corrected one. It
also verifies immediate failed-generator handling and unchanged delivery inputs.
All 123 telemetry tests and 57 release tests pass, with Pyflakes clean. The new
standard and parallel profile IDs are v12; resource budgets, workload, schedule,
sample floors and thresholds are unchanged. Controller identity changed, so
fresh calibration and matching diagnostics are required. The live local
development check is `development-v12-cadence-20260926/`.

### Bounded usable-memory variation on standard runners

`v11-ci-host-comparison.json` adds the full trial's Neoverse-N2 host to the earlier
records. Every recorded CPU, cache, topology, image, kernel and Docker field
matches the N2 reference except usable memory: the observed spread is 40 KiB.
[Linux documents MemTotal](https://docs.kernel.org/filesystems/proc.html) as usable
RAM after reserved memory and kernel code, rather than an installed-DIMM identity.
The current comparison policy allows at most **64 KiB** difference in that single
host field, replacing the earlier one-page allowance. It preserves original
values and hashes and records both the bound and signed difference in the receipt.
Every other measurement input, including container limits and JVM heap, remains
exact. The bound does not grow automatically and does not change resource,
latency, retained-memory or coverage gates.

`v11-ci-host-policy-verification.json` confirms all four recorded N2 hosts match
while V3 still fails. Regression tests cover both 64 KiB boundaries, rejection
one byte beyond either boundary, observed 40 KiB variation, CPU/cache/heap drift,
and tampering with the receipt's difference or bound. All 123 telemetry and 57
release tests pass. Identity policy is outside measured workload source, so this
comparison correction does not change the active v12 measurement conditions.

### V12 development and measurement evidence

`development-v12-cadence-20260926/development-verification.json` passes after the
controller correction: 901/901 plateau journeys completed, traffic and resources
passed, maximum application observation gap was 5.183 seconds and idle began
26 ms after generator completion. The full declared development idle period,
recorded controller source, collector flush, final JFR and live removal of owned
containers, named/anonymous volumes and network were verified. Its short-schedule
memory result remains inconclusive; this is not full calibration evidence.

The measurement job in v12 diagnostic run `36252126235` passed. Downloaded raw
JVM data independently reproduces healthy, retained-growth and late-growth
classifications, with all child exit codes zero and final recordings retained.
The canceled pilot preserved partial evidence, stopped both children and never
qualified. Its evidence is under `ci-36252126235-measurement/`.

The same run's saturation job passed. Raw k6 and container-observation reanalysis
exactly reproduces both saved assessments: bounded generator CPU work completed
48 of 829 offered journeys and is inconclusive for generator capacity; a
half-CPU application completed 59 of 94 and fails for application overload and
unexpected HTTP/contract errors. Both collectors flushed and retained nonempty
final JFR recordings; the original CI verification confirms restored quotas and
owned-resource cleanup. Evidence is under `ci-36252126235-saturation/`.

The application job also passed, making diagnostic run `36252126235` terminal
success. `ci-36252126235-application/raw-evidence-verification.json` reproduces
all five traffic assessments and all four available resource/memory assessments
from raw data. The healthy, held-connection, sustained-latency and late-latency
cases each completed 901/901 plateau journeys; the wrong contract failed during
warmup as intended. The held connection failed its exact final/idle JDBC checks,
sustained latency failed `report_100`, and late latency remained inconclusive.
All five retained a final JFR and collector flush. Completed cases had maximum
application sampling gaps between 5.061 and 5.065 seconds.

`profile-source-verification.json` confirms matching v12 measured sources,
runtime, images, budgets, fixture fanout and report sizes on N2. Development
timing and explicit faults remain distinct from full trials. Original CI checks
also passed all eight HTTP contract probes, controller cancellation and observer
loss, including live owned-resource cleanup; downloaded evidence is not checked
against the local Docker daemon. The reproducible local reanalysis helper is
`tests/results/soak/reanalyze_application.py`, whose SHA-256 is recorded in the
verification report. Full calibration `36252125924` remains running.

`diagnostic-archive-v12-36252126235/` packages all three v12 artifacts, raw
reanalysis, the reanalysis helper source and GitHub provenance. Every one of its
1,953 source files was read back from the archive and SHA-256 verified. The
106,316,566-byte bundle has SHA-256
`22eb95f8fdc39b5ea2a47c2abddd7883cdec33c79216070aca531f2707dd1343`.
The bundle, manifest, provenance and local archive verification are also retained
in [draft evidence release 397309485](https://github.com/coldbox-modules/quick/releases/tag/untagged-c6b000fea7b0cccd7997).
`remote-verification.json` records matching SHA-256 values for all four downloaded
assets and GitHub digests, the exact measured target commit, and unchanged latest
product release v13.0.4. The bundle asset ID is `591005637`. The draft is a retained
remote copy requiring repository permission; it remains editable and does not
accept a baseline or publish Quick. Actions artifact expiry remains recorded in
`github-provenance.json`.

Independent calibration `36254251872` was dispatched once on the same standard
runner label to measure between-host variation with v12. Before dispatch,
`v12-independent-host-plan.json` records the fixed scope: accept the next assigned
host, retain every outcome, and run three full trials only if its capacity sweep
is eligible. Git comparison confirms that commit `59e4fa6` has identical measured
source files and profiles to the primary v12 run at `60a7248`; intervening changes
are comparison/proof verification and documentation. This is an additional host
observation, not a replacement for either inconclusive v11 trial or for any v12
failure. Neither calibration has an accepted baseline yet.
