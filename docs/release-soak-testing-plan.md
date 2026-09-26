# Quick release soak testing plan

Status: implementation in progress. This document specifies the application,
continuous workload, measurements, and release gate. Verified milestones and
remaining acceptance work are recorded in `tests/soak/README.md`. The required
release gate remains disabled until calibration and acceptance are complete.

Run approximately 60 minutes of application load and observation in the release
workflow, starting alongside the regular tests. Cancel unfinished validation
jobs when any required job fails. Publish only after every required validation
job succeeds. Keep this workload out of ordinary branch/PR and scheduled test
workflows. Setup and artifact collection add time beyond the 60-minute profile.

1. **Build a dedicated, persistent ColdBox application.**

   Put the application under `tests/soak/app/` and make that directory the web
   root of its own CommandBox server. Give it its own `Application.cfc`,
   `index.cfm`, ColdBox configuration, routes, dependencies, and datasource.
   This isolates its lifecycle from `tests/Application.cfc`, whose TestBox
   virtual application is shut down at the end of each request.

   Use the normal ColdBox bootstrap: initialize once in `onApplicationStart`,
   dispatch each incoming HTTP request through ColdBox, and shut down only when
   the application actually ends. Set the application timeout beyond the entire
   run. Disable development reloads and response/event caching; keep Quick's
   normal metadata caches enabled. Never clear those caches, rebuild WireBox,
   reload the database, or restart the JVM between iterations.

   Expose a boot identifier, JVM uptime, and application start count in the
   diagnostic response. A changed boot identifier, falling uptime, or second
   application start invalidates the run, even if HTTP traffic recovers.

   Install the candidate Quick package into the application's module directory.
   Resolve fresh Quick entities/builders for each operation through its public
   API. Stateless singleton services may coordinate work, but must not retain
   request entities, query builders, result arrays, or request contexts.

   Start with a pinned Lucee 6 / ColdBox 8 / Java 21 / MySQL configuration as a
   provisional CI profile; select the affected production runtime instead when
   known. Record exact patch versions, JDBC driver, full-null setting, heap,
   pool limits, CPU/memory allocation, and resolved dependencies. Initially use
   Quick's default serial eager loading. Provide a separate opt-in parallel
   eager-loading profile with a bounded executor; do not change module settings
   halfway through a run or mistake serial coverage for parallel coverage.

   The application, MySQL, and k6 run as separate processes/containers inside
   the soak job, with measured resource usage and explicit budgets. Other matrix
   jobs use their own runners and databases. Calibrate against the chosen runner
   size; if k6 cannot sustain the rate within that budget, move generation to
   separate capacity before qualifying releases. Avoid requiring an external
   always-on load-testing service for the initial implementation.

2. **Give the application a small, meaningful domain and deterministic data.**

   Use purpose-built `Team`, `User`, `Post`, `Comment`, `Tag`, and `PostTag`
   entities. Adapt the existing test models' relationship patterns, but keep the
   soak application independent of the TestBox runner and test lifecycle hooks.
   Include belongs-to, has-many, many-to-many, and polymorphic relationships;
   aliased attributes; nullable fields; a custom cast; timestamps; and a
   lightweight lifecycle listener. These should all participate in real reads,
   persistence, and serialization.

   Proposed starting seed: 20 teams, 1,000 users, 10,000 posts, 50,000 comments,
   100 tags, and deterministic pivot assignments. Include empty relationships,
   a few high-fanout records, and null/non-null combinations. Use a fixed seed,
   indexes, and a recorded fixture manifest so identical inputs have known
   expected owners, counts, ordering, and checksums. Final sizes are calibration
   inputs, not assumed production scale.

   A CommandBox setup task creates and seeds a disposable `quick_soak` database
   once before the timer starts. Separate immutable read fixtures from scratch
   write records. Give each write journey an ownership token derived from the
   run ID and globally unique iteration ID. Concurrent workers must not
   accidentally overwrite one another's assertions.

   Ordinary write journeys commit changes, read them back through another HTTP
   request, delete their scratch records, and verify removal. A distinct rollback
   journey deliberately aborts a transaction and verifies that nothing persisted.
   Check scratch-table counts periodically and at the end. A failed cleanup is
   a test failure; do not reset tables during the run to hide it. The seeded
   dataset stays stable so database growth does not confound memory analysis.

3. **Expose actual HTTP workloads and explicit assertions.**

   All following routes are proposed, local test-harness endpoints. Implement
   them with ColdBox handlers, fresh Quick entities, real SQL, and JSON responses.
   Each request performs a bounded operation and returns. k6 supplies repetition
   and concurrency from outside the JVM.

   | Journey | Initial share of starts | Endpoints and work | Required checks |
   |---|---:|---|---|
   | Browse | 25% | `GET /api/users` with team, filters, ordering, and pages of 25/100 rows | Selected fields, team membership, page bounds, ordering, and known fixture values |
   | Entity detail | 15% | `GET /api/users/:id` loads and serializes a user with team and a bounded set of recent posts | Correct identity, relationships, casts, nulls, and excluded fields |
   | Relationship graph | 15% | `GET /api/posts` eagerly loads authors, comments/authors, and tags with bounded fanout | Correct foreign owners and relationship counts; no data from another concurrent request |
   | Write lifecycle | 10% | `POST /api/posts`, `PATCH /api/posts/:id`, `GET /api/posts/:id`, `DELETE /api/posts/:id`, then verify absence | Committed values survive re-query, timestamps/lifecycle behavior is correct, ownership matches, deletion succeeds |
   | Larger hydration and serialization | 10% | `GET /api/reports/posts?limit=...` hydrates 100/500/1,000 rows and serializes a bounded projection | Expected row count, representative values, stable checksum and payload size bounds |
   | Query variants | 5% | `GET /api/query-variants/:variant` varies query shapes over the same fixture domain | Correct aliases, projections, nulls and values across changing query shapes |
   | Expected failures and recovery | 20% | Rotate the five failure cases below, each followed by a valid request | The actual intended exception/rejection occurs, the exact response contract matches, and subsequent work succeeds |

   Expected failures are required continuous traffic. Initially allocate 20% of
   journey starts to them, split equally across these five cases (4% each), and
   interleave them with successful journeys throughout warmup, sustained load,
   and low-rate recovery. This is an intentional exception-path workload, not a
   claim about production error rates. Baseline trials must include the identical
   failure mix. Ordinary write/delete journeys also exercise post-delete misses.

   | Failure case | Application operation that must actually execute | Expected result and follow-up |
   |---|---|---|
   | Missing primary key | `GET /api/users/:id` calls Quick `findOrFail()` for a reserved nonexistent ID | Actual `EntityNotFound` becomes HTTP 404 with error code `EntityNotFound`; a subsequent valid user lookup returns the correct user |
   | Empty filtered lookup | `GET /api/users/lookup` uses guaranteed-unmatched filters and calls `firstOrFail()` | Actual `EntityNotFound` becomes the same documented 404 contract; a matching lookup succeeds without stale constraints |
   | Missing or out-of-scope relationship | `GET /api/users/:id/posts/:postId` queries the user's posts with `firstOrFail()`; alternate a nonexistent post and another user's existing post | Actual `EntityNotFound`, 404, and no foreign data; a valid related post then loads correctly |
   | Invalid write | `POST /api/posts` reaches the application's validation path with a deterministic invalid payload | HTTP 422 with stable code `ValidationFailed` and expected field errors; no row or pivot is written, and a valid write/cleanup afterward succeeds |
   | Exception during transaction | `POST /api/transactions/rollback` inserts scratch data, then invokes `findOrFail()` on a guaranteed-missing entity within the same transaction | The real `EntityNotFound` propagates out of the transaction, rollback completes, and the normal error handler returns 404; a separate request verifies no scratch data remains and another transaction succeeds |

   Configure fixed routes such as `/api/users/lookup` before parameterized ID
   routes. Reserve missing-ID ranges outside all seeded and scratch allocations;
   varying those IDs must never accidentally create a real match. Use ownership
   tokens for transactional verification so concurrent writers cannot invalidate
   one another's checks. ValidationFailed is the proposed harness application's
   contract, not a claim that Quick supplies that validation exception type.

   Let the Quick exception travel through the normal ColdBox error-handling
   path. The handler classifies the actual exception type and returns a bounded,
   sanitized JSON envelope. Do not manually throw a lookalike exception, return
   a canned 404, or catch every exception and label it EntityNotFound. Database
   errors, handler bugs, unexpected 500s, and timeouts remain test failures.
   Exercise both default not-found error messages and Quick's custom message/
   callback options within the missing-entity cases; verify stable contract
   fields rather than brittle stack traces or engine-specific message text.

   Preserve the exception-handling and logging configuration used for calibration.
   Rotate log files, retain bounded examples, and count classifications by fixed
   case/type labels. Never retain all exception objects, stack traces, request
   contexts, or missing IDs in application collections. Observe exception
   allocation in JFR and retained growth in the JVM, along with connections,
   threads, and file descriptors. Successful recovery must not require a server
   restart, cache clear, or pool reset.

   k6 must assert the exact expected status, error code, response shape, and
   persistence outcome for each intentional failure. Scope expected-status
   callbacks to individual requests, so a 404 is accepted only on a request
   explicitly expecting it. Do not globally allow all 4xx/5xx responses or
   classify by status alone: [k6 expected-status callbacks](https://grafana.com/docs/k6/latest/javascript-api/k6-http/expected-statuses/)
   only handle status classification, so response-body checks must independently
   fail the gate. An unexpected 200 on a missing entity is also a failure.

   Record attempted and verified expected failures, unexpected errors, and
   follow-up successes separately by fixed case label. Require at least 100
   verified executions of each failure case during the plateau and coverage in
   every five-minute plateau window. Enforce the separate latency sample-count
   rules when comparing per-case latency. Missing cases or mismatched exception
   contracts block release even when the aggregate HTTP error metric is green.
   Compare successful-request latency independently, so a higher proportion of
   cheap error responses cannot make the application appear faster.

   Use an allowlisted set of query-shape variants larger than the relevant
   derived-cache limit, while keeping entity mappings fixed. Varying only a
   bound SQL value is insufficient to exercise derived metadata variants. Probe
   eviction with bounded selections/aliases; do not generate CFC files or new
   model names indefinitely.

   `/health/ready` checks boot completion, the datasource, and seed completion.
   `/diagnostics` reports the boot identifier and bounded scalar metrics.
   Neither endpoint invokes TestBox, resets data, or becomes the primary load.
   Bind the application to the CI job's private network and require a per-run
   harness token. This token grants access to synthetic fixtures; it does not
   claim coverage of a consuming application's authentication system.

   Start with a sessionless API profile and a fixed pool of synthetic user/team
   identities. An optional session profile must explicitly preserve cookies,
   bound active users, and model turnover and expiration. Its result is distinct
   from the default Quick-focused profile. No outbound email, payment, or other
   third-party traffic is part of these endpoints.

4. **Keep the application continuously busy with an external k6 process.**

   Start metrics collection and recording, confirm readiness, and then launch
   one k6 run. Use arrival-rate scheduling to start journeys throughout the
   workload. Each iteration chooses a journey, fixture identifiers, and query
   variant from a reproducible distribution, executes its HTTP sequence, checks
   responses, and completes. The scheduler keeps starting more iterations until
   the phase ends; the application does not run an internal infinite loop.

   Maintain the same generator process and application across warmup, ramp,
   sustained load, and recovery. An illustrative sustained configuration is:

   ```javascript
   // Sustained phase only; the full script also defines warmup/ramp/recovery.
   {
     executor: 'constant-arrival-rate',
     exec: 'mixedJourney',
     rate: 30,
     timeUnit: '1s',
     duration: '40m',
     preAllocatedVUs: 100,
     maxVUs: 100,
     gracefulStop: '30s'
   }
   ```

   This example schedules 72,000 journey starts over the 40-minute plateau.
   It does not mean 72,000 HTTP requests: a write journey makes several requests.
   Report both journey rate and HTTP request rate, per-operation counts, and
   concurrent in-flight work. The example's 30 journeys/second and 100 virtual
   users are provisional calibration values, not promised capacity.

   k6 starts arrivals independently of response completion while virtual users
   are available. If requests slow, more users are needed to sustain the same
   rate. Preallocate users based on measured journey duration plus headroom;
   freeze that allocation and the target rate for candidate comparisons. Do
   not add an unconditional sleep after each arrival-rate iteration. These
   scheduling semantics are documented in [k6's arrival-rate executor](https://grafana.com/docs/k6/latest/using-k6/scenarios/executors/constant-arrival-rate/)
   and [virtual-user allocation](https://grafana.com/docs/k6/latest/using-k6/scenarios/concepts/arrival-rate-vu-allocation/).

   Do not reduce the target automatically when the candidate slows. Count
   dropped iterations and compare offered/completed traffic in each time
   window. Sustained generator saturation makes the run inconclusive;
   application saturation at the validated load fails it. Neither passes.
   Predeclare request timeouts; validate expected errors such as post-delete
   404s explicitly, and do not automatically retry unexpected failures.

   | Elapsed time | Load | Purpose |
   |---|---|---|
   | 0-5 minutes | Low-rate mixed traffic, initially 10% of target | Smoke assertions and warm every workload path |
   | 5-10 minutes | Ramp to the target | Establish concurrent load and warmed resource use |
   | 10-50 minutes | Fixed target arrival rate | Continuous sustained work and trend measurement |
   | 50-55 minutes | Low-rate traffic at 10% of target | Observe latency and backlog recovery |
   | 55-60 minutes | No workload arrivals; continue diagnostics | Observe resource release and drain remaining work |

   Keep the application/JVM alive for the idle observation. Allow a short,
   bounded in-flight drain at phase boundaries and record it separately.
   Shutdown, canceled requests, or changing traffic phases must not contaminate
   steady-state latency or retained-memory comparisons. The five-minute idle
   period does not prove release of resources with longer configured lifetimes.

   Seed input selection deterministically; ensure that every operation and size
   bucket reaches a minimum count. Normalize metric names by route template
   and operation, not user ID, request token, or full query string. Stream
   bounded metrics to disk; do not accumulate all response bodies or per-request
   results in either application or generator memory.

5. **Measure growth and preserve evidence.**

   Sample every 10-15 seconds: heap usage and collector-aware post-collection
   occupancy, metaspace, GC frequency/pause time, process resident memory, CPU,
   threads, open descriptors, JDBC pool active/idle/waiting counts, query latency,
   locks, request latency/errors, and executor queue depth where applicable.
   Read `EntityDefinitionRegistry.getStats()` for definition, bucket, entry,
   compilation, and eviction counts. Sample application diagnostics sparsely;
   use an external process for JVM/OS collection so an application hang does not
   also silence every measurement.

   Compare the first and last ten minutes of the sustained phase, plus the trend
   across that phase. Distinguish allocation churn, JVM heap reservation, bounded
   cache warmup, and retained objects. Use collector-aware observations across
   completed reclamation cycles; ordinary young-GC occupancy alone does not
   establish the live set. Do not force GC on each request or repeatedly clear
   caches. If the run cannot produce adequate memory evidence, mark the memory
   result inconclusive and use a separate diagnostic run to investigate.

   Keep a bounded JFR recording and rotating application/GC logs. Periodically
   persist recordings and metrics. On a threshold failure, capture thread dumps
   and, if appropriate and within disk/time limits, a heap dump before teardown.
   Diagnostic dumps that perturb execution are outside measured timing windows.
   Use native-memory tracking in a matching diagnostic profile when heap metrics
   do not explain process growth. Baseline and candidate must use identical
   instrumentation. [Oracle's memory-leak guidance](https://docs.oracle.com/en/java/javase/21/troubleshoot/troubleshooting-memory-leaks.html)
   explains why retained growth under stable load is more useful than heap
   growth alone.

   Produce `summary.json`, a readable report with time-series charts, runtime
   and package manifests, fixture/workload versions, actual traffic counts,
   error samples, GC logs, and JFR files. Keep artifacts under
   `tests/results/soak/<run-id>/` and upload them with the release workflow run.

6. **Define and calibrate the gate before trusting it.**

   Establish a baseline before finalizing traffic, latency, and memory-growth
   limits. Choose duration, fixtures, hardware, runtime, heap, and pools first:
   those are the conditions under which a baseline has meaning. Correctness,
   crash, lifecycle, and completion requirements can be enforced immediately.
   All numeric thresholds below are proposed engineering defaults, not measured
   Quick results or universal standards.

   Recommended initial calibration procedure:

   - Choose an exact release with evidence of stable behavior. Do not assume the
     latest release is healthy merely because it was published. If none is known,
     characterize the harness and investigate before designating a reference;
     the candidate's measurements alone are not evidence that it is healthy.
   - Start with a 1 GiB maximum JVM heap and a 2 GiB application container memory
     limit, leaving separate runner capacity for MySQL, k6, and collection. Adjust
     these initial sizing choices during calibration if necessary, then freeze
     them. Never enlarge memory automatically to make a candidate pass.
   - After warmup, run a bounded capacity sweep: initially 5, 10, 20, and 40
     journeys/second for three minutes each. Start lower if necessary. Stop
     increasing when latency rises sharply, errors or dropped work appear,
     pools queue, or the generator saturates. This explores capacity; it does
     not prove sustained stability.
   - Start the soak at 60% of the highest clean observed step. If 40 journeys/
     second is clean, try 24 journeys/second. If no tested step fails, this is
     still a conservative starting target, not a measured maximum. Resolve
     generator bottlenecks separately and retain resource headroom.
   - Run three full 60-minute trials at that frozen target, each with a fresh
     JVM and seeded database on the same CI profile. Retain every trial,
     including failures. Changes to conditions require restarting calibration.
     This costs about three runner-hours plus setup and the sweep once; ordinary
     releases subsequently run one trial against the accepted reference.
   - Require correct results, a stable retained-memory trend, sustained traffic,
     and recovery in each trial. A repeatable leak does not become acceptable
     by appearing in the baseline. Use the median of the three per-operation
     p95 values as the latency reference and retain their observed range.
     Three trials give an initial noise estimate, not strong statistical
     confidence. If variation exceeds the proposed warning bands, investigate
     runner contention, warmup, and fixtures before enabling comparison gates.
   - Store the accepted thresholds and profile alongside exact package,
     environment, fixture, and workload identities and raw reports. Requalify
     after changing the runner, runtime, driver, instrumentation, resource
     budgets, fixtures, workload, or dependencies other than the package being
     compared. Baseline changes require an explicit reviewed update; passing
     candidates never replace it automatically.

   Recommended initial triggers, to validate during calibration:

   | Signal | Warning or diagnostic trigger | Release-blocking result |
   |---|---|---|
   | Correctness/lifecycle | Capture the first mismatch and its reproducible inputs | Any incorrect result, cross-request contamination, unexpected restart, crash, OOM, or deadlock |
   | Unexpected HTTP failures | Capture the first error/timeout | Any unexpected error or timeout; intentional failures must match the exact per-request status, error contract, and persistence checks |
   | Expected failure coverage | Count each injected failure and successful recovery by case | Any wrong/missing expected exception, unintended persistence, failed follow-up, fewer than 100 verified plateau executions per case, or absent case in a five-minute plateau window |
   | Delivered load | Any dropped arrival or plateau traffic shortfall | Dropped plateau iterations or incomplete required work; application overload fails, generator/infrastructure failure is inconclusive |
   | Latency per operation | p95 increases more than 10% versus baseline or the early stable window | More than 20% AND at least 50 ms worse than either reference across three successive five-minute plateau windows; also block for calibrated absolute endpoint budget violations |
   | Retained heap growth | Late-versus-early growth exceeds max(32 MiB, 3% of maximum heap), beyond healthy-run noise | Growth exceeds max(64 MiB, 5% of maximum heap), exceeds healthy-run noise, and persists across multiple completed reclamation cycles and at least three five-minute plateau windows |
   | GC pressure | Stop-the-world GC pauses consume over 5% of a five-minute plateau window | Over 10% in each of three successive five-minute plateau windows; track concurrent GC work separately |
   | Memory headroom | Application container memory approaches its fixed budget | Over 90% of container memory limit for two minutes: capture available diagnostics, stop load, and fail; kernel/JVM OOM fails immediately |
   | Resource recovery | Borrowed connections, threads, descriptors, or queues grow at fixed traffic | Declared bounds exceeded, borrowed connections leaked, or backlog misses its recovery deadline; idle pooled threads/connections may legitimately remain |
   | Run validity | Telemetry gaps, inadequate samples, or unsettled warmup | Missing required evidence, mismatched baseline, abbreviated/canceled run, or unusable retained-memory comparison: inconclusive, never pass |

   Zero unexpected errors supersedes the earlier proposed 0.1% allowance: this
   synthetic application uses a local database and deterministic operations, so
   allowing unexplained failures would hide useful bugs. The latency bands
   replace the earlier blanket 10% blocking rule with a 10% warning and a
   conservative sustained 20% plus 50 ms blocking threshold. Freeze final bands
   after healthy-trial validation. Initially report p99 without gating it until
   per-operation sample counts support it.

   Require an initial minimum of 200 observations per operation per five-minute
   p95 comparison window. Increase coverage or combine explicitly compatible
   buckets during calibration if a path is rarer. Compare later windows with
   both the first stable ten minutes and the accepted per-operation baseline;
   also report the overall first/last ten-minute comparison. Cumulative end-of-
   run k6 percentiles alone cannot enforce sustained degradation rules.

   Evaluate the final complete comparison window explicitly. If a comparative
   blocking band is crossed near the end but too little time remains to confirm
   persistence, mark the result inconclusive and retain diagnostics. Do not pass
   merely because three later windows could not fit before the deadline. Hard
   correctness, HTTP, lifecycle, and resource-limit failures need no such trend
   confirmation. Report the exact observed windows and triggering rule.

   Retained-memory comparisons need usable reclamation observations in the early
   and late windows spanning at least 20 minutes of the plateau. Young-only
   collections do not establish full reclamation. These byte thresholds trigger
   release investigation; they do not define a leak. Report smaller persistent
   growth too. Normal GC sawtooth behavior, allocation churn, or JVM pages
   remaining resident during idle does not itself fail this rule. Compare
   absolute retained occupancy with the healthy reference and flag unexplained
   shifts even when the candidate's slope is flat. Track native memory and
   metaspace separately because heap rules do not cover them.

   Predeclare request timeouts, initially 10 seconds for these local bounded
   operations, with documented workload-specific exceptions. Select absolute
   endpoint latency budgets from healthy trial measurements and the operation's
   requirements; do not invent a universal 500 ms requirement. If the profile
   cannot produce usable retained-memory evidence on an engine, improve the
   diagnostic method/profile and recalibrate rather than silently passing it.

   Abort promptly for hard failures or sustained headroom exhaustion, with short
   bounded diagnostic capture where possible. Comparative warnings preserve the
   observation period and appear in passing reports. A sustained blocking trigger
   may stop the run early, but the result remains failed. Other required-job
   failures cancel the soak through the release matrix's fail-fast behavior.

   Convert correctness checks into failure-producing k6 thresholds; checks alone
   are not sufficient as the CI gate. Evaluate telemetry trends in a separate
   analyzer and combine its exit status with the generator's. Missing telemetry,
   insufficient traffic, or early termination never qualifies a release.

   Prove detection using controlled retained-object growth, a deliberately
   incorrect response, a held connection, and a latency regression. Run an
   actual previously failing release where it can be reproduced. Verify the
   corrected release passes under identical conditions. A 60-minute test can
   miss slow or timer-dependent failures; longer runs remain optional diagnostics.

7. **Integrate parallel execution and cancellation into release validation.**

   Extend the release workflow's existing engine/configuration matrix with a
   `kind` discriminator and exactly one soak row. Use an explicit include list
   with the soak row first; retain the functional combinations. Set
   `strategy.fail-fast: true`, replacing the current `false`. Branch setup/run
   steps by kind so the soak row launches its application and k6, and ordinary
   rows continue to run TestBox.

   The soak row has no dependency on functional-test completion. Do not impose
   a matrix concurrency cap that queues it behind those tests. All validation
   is eligible when the release workflow starts; actual start time still depends
   on runner availability. Confirm adequate concurrency during rollout. Each
   soak job provisions its own database and never probes another matrix job's
   TestBox server.

   GitHub's matrix fail-fast cancels queued and running sibling jobs when any
   required row fails. That includes cancellation of the soak row after a
   functional failure, and cancellation of unfinished functional rows after a
   soak failure. Keep required rows blocking. The semantic-release job depends
   on the whole validation matrix succeeding. [GitHub matrix cancellation](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations)
   provides the native mechanism; `needs` alone would only block publication.

   Handle termination signals in the soak controller: stop new arrivals, stop
   child processes, flush the evidence already collected, and shut down only
   this job's server. Use a short timeout for best-effort final diagnostics and
   artifact upload. Periodic writes are necessary because hard cancellation can
   prevent final cleanup. Never let cleanup success overwrite the original
   failure/cancellation, and never represent a canceled run as a full pass.

   Keep the existing release trigger and version-update skip rule. Add no soak
   job to ordinary PR/branch or cron workflows. Since the existing release
   workflow runs on main/master pushes, those release-triggering pushes will
   receive this gate. A 90-minute soak-job timeout is an initial budget for
   setup, 60-minute testing, and collection; calibrate setup time before adoption.

   Bind results to the exact candidate commit and package checksum. Build the
   candidate package in the soak row before loading it; this does not delay the
   other test jobs. Prepare release metadata before that build. Update release
   orchestration as needed so publication uses the tested package and does not
   silently rebuild from a moving branch or resolve new dependency versions.
   Validate the downloaded published package against the tested artifact.

   Account for overlapping release workflows: validation may run concurrently,
   but publication must be serialized through a repository release concurrency
   group with cancellation of an active publisher disabled. Under that guard,
   revalidate the candidate SHA, tested-package checksum, and the last-release
   identity used to prepare its version. If a newer publication invalidated
   that preparation, stop or supersede the stale candidate; never silently
   choose a new version and publish an untested rebuild. A newer push must not
   interrupt a publisher between its ForgeBox and GitHub operations.
   [GitHub concurrency controls](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency)
   can serialize the publishing job while allowing validation to start promptly.

8. **Implement in reviewable pieces and verify the entire path.**

   | Proposed location | Responsibility |
   |---|---|
   | `tests/soak/app/Application.cfc`, `index.cfm` | Persistent ColdBox bootstrap and lifecycle identity |
   | `tests/soak/app/config/Coldbox.cfc`, `Router.cfc` | Modules, routes, pools, caching, and profile settings |
   | `tests/soak/app/handlers/` | Read, relationship, report, write, rollback, readiness, and diagnostic endpoints |
   | `tests/soak/app/models/` | Domain entities, casts, listeners, and stateless workload services |
   | `tests/soak/Seed.cfc`, migrations/fixtures | Disposable schema, deterministic data, scratch-record invariants |
   | `tests/soak/k6/` | HTTP journeys, input selection, arrival schedule, correctness checks, thresholds |
   | `tests/soak/profiles/` | Pinned runtime/resource/workload settings and accepted baseline references |
   | `tests/soak/run.sh`, collector/analyzer scripts | Startup, telemetry, process supervision, cancellation, evaluation, reporting |
   | `.github/workflows/release.yml` | Parallel validation matrix, fail-fast, artifacts, publication dependency |

   First implement and behavior-test the HTTP contracts, deterministic fixtures,
   and persistent lifecycle. Then add generation and telemetry with a short
   development profile. Prove all routes continue to receive traffic and the
   application boot identifier stays constant. Prove real EntityNotFound paths
   return the expected contract and recover; deliberately suppress an expected
   exception or return a wrong error code in a harness self-test and verify that
   the gate fails. An unrelated exception must not be accepted as EntityNotFound.
   Calibrate with the complete success/failure mix and run the full
   profile before enabling the publishing gate.

   Finally exercise a deliberate functional-test failure while the soak is
   active, a soak failure while functional tests are active, explicit workflow
   cancellation, and an all-pass run. Verify that child processes stop, evidence
   is retained where cancellation permits, and publication is blocked or enabled
   correctly. Use a publication stub for failure-path tests. Real publication
   remains part of the normal authorized release process.

9. **Resolve the handoff risks in the first implementation milestones.**

   Treat the following as acceptance requirements, not additional design choices
   the implementer must ask the user to make before starting:

   - **Prove measurement viability first.** Build a small end-to-end measurement
     pilot on the selected JVM, with a healthy workload and a controlled retained-
     object leak. Demonstrate that the collector/analyzer distinguishes them and
     that a healthy run can satisfy the evidence requirements. A healthy JVM
     might not perform the reclamation cycles the draft analysis assumes. Select
     and record an explicit collector-specific method during this milestone;
     neither perpetual inconclusive results nor silently waived memory checks
     are acceptable. Any controlled GC/snapshot procedure requires its own
     matched baseline and must stay outside measured request windows. Heap dumps
     are high-impact and normally request a full GC; do not use repeated dumps
     as lightweight sampling. [JDK diagnostic command reference](https://docs.oracle.com/en/java/javase/21/docs/specs/man/jcmd.html)
   - **Bootstrap calibration without publishing.** Provide an explicit diagnostic/
     calibration entry point using the same harness as release CI, with no
     publication capability. Use it for the capacity sweep and baseline trials.
     Enable the required release gate only after the accepted baseline manifest
     and detector self-tests exist. After enablement, a missing baseline blocks
     publication; do not fall back to report-only mode. This avoids a circular
     dependency in which the first baseline requires an already passing gate.
   - **Verify package promotion early.** The current workflow invokes CommandBox
     semantic-release, which owns version preparation and publishing. Verify the
     relevant plugin interfaces before assuming they can consume a prebuilt
     artifact. Implement the necessary preparation/promotion integration and
     exercise it with a fake publisher. Check package contents exclude the soak
     application, generated reports, databases, engines, and nested build output;
     the harness must install the actual distributable without recursively
     including itself. Package provenance and overlapping-release tests are
     required before connecting a real publisher.
   - **Calibrate against CI noise, not a local laptop.** Pin the runner image and
     resource configuration and record available CPU/memory. A runner label alone
     does not prove identical performance. Verify the generator is not the
     bottleneck and record actual workload counts. If healthy trial variation
     is too large, stabilize the environment or revise the measured profile and
     rerun calibration. Do not repeatedly retry failures until one passes, or
     widen tolerances just to absorb unexplained drift.
   - **Bound v1 and state its coverage.** The required first profile remains one
     runtime, a sessionless persistent application, serial eager loading, the
     specified success/failure mix, and 60 minutes. Additional engines, parallel
     eager loading, sessions, and longer runs are separate profiles. Choose the
     runtime of a reported incident when known; otherwise record Lucee 6 as a
     provisional choice. A pass establishes only the tested profile's behavior.
     Reproducing a reported bad release is desirable; if none is identifiable,
     detector self-tests establish detection capability without claiming the
     historical incident has been reproduced.

   Completion requires more than a workflow file and a green smoke run: deliver
   the full healthy-run reports, accepted baseline/profile manifests, controlled
   failure detections (including a late failure), real expected-exception
   coverage, cancellation evidence, and publication-stub tests demonstrating
   artifact identity and serialization. Include one clear local command and
   one CI entry point, each with documented inputs and artifact locations.
