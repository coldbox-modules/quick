# V12 baseline review — 2026-09-26

Reviewer: Codex. Scope: the standard four-core GitHub ARM Neoverse-N2 cohort,
Ubuntu image `20260920.129.1`, Lucee 6 / ColdBox 8 / Java 21, serial loading,
6 journeys/second and the complete 60-minute schedule.

## Decision and preserved limits

Accept the primary three-trial reference for this measured cohort, with the
report-100 latency-noise warning explicitly retained. This is baseline acceptance
only. The live release gate stays disabled until all full-matrix integration
proofs pass. Unknown CPUs/images remain inconclusive and require calibration.

The plan defines 10% as a warning that requires investigation. It defines a
release-blocking comparative regression as more than 20% and at least 50 ms
across three consecutive windows, plus calibrated absolute endpoint budgets.
The original proposal, measured noise, median references and absolute budgets
are preserved. No trial is replaced, no comparison band is widened, and no
memory-growth investigation is waived. The initial primary host was selected
before the independent-host observations; the independent observations validate
that reference rather than replacing it with the slower host's timings.

## Noise investigation

The primary report-100 exact early p95 values are 125.828450, 116.307361 and
113.356936 ms: a 12.471514 ms range, or 10.722893% of the median. Raw sample
reconstruction eliminated two separate integer-rounding artifacts; this genuine
warning remains in the proposal. The independent proposal also retains six
10.3–19.1% within-host warnings. It is retained as corroborating evidence rather
than accepted as a second baseline for the same hardware.

All six trials use the same healthy package, measured sources, workload,
fixtures, runtime and resource limits. Host comparison permits only the already
fixed 64 KiB usable-RAM reporting difference. Each trial starts a fresh JVM and
seeded database, completes warmup and ramp, passes exact response and failure
contracts, delivers 14,401/14,401 plateau journeys, and passes every required
sample floor. Full raw reanalysis and evidence seals verify for all six.

Resource observations show zero saturation samples for application, database
and generator. The collector has one isolated saturation sample in independent
trial two; all other collector samples remain below saturation, and every trial
passes sampling-cadence and resource checks. Median application CPU consumption is 33.5–33.8% of
its allocation on the primary host and 39.7–42.7% on the independent host.
Database timings also differ. This establishes observed between-allocation
variation; it does not identify physical-host contention or CPU frequency,
which were not directly measured. No fixture, source or runtime drift explains
the variation. Within-run windows, warmup/ramp completion, resource recovery and
full-hour correctness were inspected; none requires extending warmup or reducing
the frozen load on this evidence.

The full six-trial replay uses the primary proposal's unchanged latency AND
memory references. Every trial passes. Latency warnings are retained (11, 8,
4, 154, 161 and 153 per trial). Thus the observed noise triggers diagnostics
without a false release-blocking result in these six trials. That is the basis
for resolving the review requirement while retaining the warning. Six trials
provide an initial noise estimate, not a guarantee about future hosted runners.
The graph operation has only 4 ms of headroom beneath its 399 ms absolute budget
at the highest observed five-minute p95. That budget remains unchanged; a future
breach must fail and be investigated, not automatically widen the baseline.

## Reviewed latency budgets

Budgets are the original primary proposal's maximum observed five-minute p95
plus max(50 ms, 20%). They provide bounded sub-second response requirements for
this local synthetic workload. The operation-specific limits below retain
failure-path sensitivity without gating sub-millisecond variation by percentage
alone. They do not claim a user-facing production SLA.

| Operation | Reference p95 (ms) | Maximum window p95 across six trials (ms) | Absolute budget (ms) |
|---|---:|---:|---:|
| `browse` | 59 | 80 | 114 |
| `failure:empty_lookup` | 9 | 14 | 60 |
| `failure:invalid_write` | 4 | 4 | 54 |
| `failure:missing_pk` | 11 | 21 | 63 |
| `failure:post_delete` | 10 | 14 | 61 |
| `failure:relationship` | 20 | 27 | 71 |
| `failure:rollback` | 32 | 43 | 85 |
| `graph` | 324 | 395 | 399 |
| `lookup_recovery` | 10 | 15 | 61 |
| `post_create` | 26 | 34 | 78 |
| `post_delete` | 31 | 42 | 83 |
| `post_read` | 27 | 37 | 79 |
| `post_read_updated` | 27 | 37 | 79 |
| `post_update` | 20 | 28 | 72 |
| `query_variant` | 11 | 16 | 61 |
| `relationship_recovery` | 20 | 27 | 72 |
| `report_100` | 117 | 172 | 188 |
| `report_25` | 35 | 49 | 89 |
| `report_50` | 63 | 81 | 118 |
| `scratch_verify` | 20 | 25 | 71 |
| `user_detail` | 37 | 56 | 91 |

## Memory and resource review

Keep the primary retained-heap reference of 280 MiB and measured noise of
111 MiB. Neither exceeds the provisional blocking band. The 6 GiB heap retains
the original max(64 MiB, 5% heap, healthy noise) blocking threshold (307.2 MiB)
and max(32 MiB, 3% heap, healthy noise) warning threshold (184.32 MiB).
Observed late-versus-early growth is +18, +46, +34, -5, 0 and -11 MiB; all six
pass raw replay with the baseline's noise and occupancy reference. No memory
warning is present. Each trial supplies 154–155 usable completed major GC cycles.

Keep all measured resource budgets and recovery bounds: application 3 CPU /
8192 MiB, MySQL 0.5 CPU / 768 MiB, generator 0.25 CPU / 512 MiB and collector
0.25 CPU / 768 MiB. The application JDBC pool is capped at 16. Maximum application
container-memory observations are 87.64–88.89%, below the unchanged sustained
90% failure rule; this narrow memory margin remains monitored. The 15-second
telemetry gap bound, zero leaked borrowed connections/backlog/scratch records,
256-thread and 1024-descriptor bounds, and +8 idle thread/descriptor recovery
allowances remain unchanged. All six raw resource assessments pass with one
application lifecycle and complete collector flush/final recording.

## Detector evidence and archives

V12 diagnostics run `36252126235` independently reproduces retained-growth failure,
late-growth inconclusive, incorrect-contract failure, held-connection failure,
sustained-latency failure, late-latency inconclusive, and generator-exhaustion
versus application-overload attribution. These are controlled detector proofs;
short schedules do not qualify release memory. Cancellation and observer-loss
proofs preserve partial evidence and never qualify a release.

The accepted manifest links the independently verified detector records by hash
and their containing remotely verified draft archive. Complete primary and
independent calibration ZIPs, their original rejected proposals, corrected raw
proposals and all trial reviews are in draft release `397323222`; matching
detectors are in draft release `397309485`. Drafts are editable, so evidence
hashes remain part of the reviewed manifest and every candidate receipt.

Earlier v11 full trials remain explicitly inconclusive for the reproduced
idle-transition telemetry gap. V12 moved analysis after idle observation; all
six v12 trials then passed continuous observation. Earlier failed capacity,
coverage, workload and detector attempts remain indexed in README.md and
ACCEPTANCE.md. None is silently replaced with a passing retry or accepted as a
baseline. Optional parallel and larger-report profiles remain unaccepted.

## Reproduction and next gate

`review_baseline.py` reproduces the original primary proposal from its first
three sealed trials, checks matching identities and healthy package across all
six, independently reanalyzes every trial, and replays the original latency and
memory limits. Its JSON is investigation evidence, never a qualification receipt.
The review record resolves only the named latency warning and links that JSON
by SHA-256. Qualification still requires a new complete candidate run.

Next: run the real 23-row functional matrix plus one full qualification row,
both fail-fast directions, explicit cancellation, no-release validation, and
overlapping serialized publication stubs. Only after those proofs may the live
release workflow be activated. Product publication is not part of this review.
