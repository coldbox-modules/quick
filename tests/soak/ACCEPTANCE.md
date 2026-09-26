# Release soak acceptance

Current assessment: **incomplete**. This checklist maps the numbered
[implementation plan](../../docs/release-soak-testing-plan.md) to evidence and
remaining acceptance work. It is an evidence index, not an accepted baseline.
See [README.md](README.md) for commands and the retained calibration history.

The current standard profile is v12: Lucee 6, ColdBox 8, Java 21, MySQL,
serial eager loading, 25/50/100-row reports and 30-comment hot-post fanout on
the standard four-core GitHub ARM runner. The dataset remains 20 teams,
1,000 users, 10,000 posts, 50,000 comments, 100 tags and 17,144 pivots.
The 60-minute schedule, exception mix, sample floors and blocking criteria
remain unchanged. The separate parallel and larger-report profiles are not
qualified by standard-profile evidence.
V12 moves traffic-file analysis after idle observation to preserve sampling
cadence. This changes controller identity and requires fresh calibration and
matching diagnostics; the retained v11 results below remain prior evidence.
Hardware comparison permits a fixed 64 KiB difference in reported host usable
RAM, covering the observed 40 KiB spread on otherwise identical N2 hosts. Raw
values and the comparison bound remain recorded; all other inputs stay exact.

## Requirements and proof boundaries

| Plan item | Implementation and available evidence | Still required for completion |
|---|---|---|
| 1. Persistent isolated application | `app/Application.cfc` uses normal ColdBox bootstrap, a four-hour application timeout, sessionless requests and lifecycle identifiers. The controller provisions isolated application, database and generator containers with recorded budgets and package/dependency identities. The v12 development run passed lifecycle/resource checks. | Matching full-hour CI trials must establish continuous lifecycle and healthy behavior under the final load. |
| 2. Deterministic domain | `fixtures/generate.py`, `Seed.cfc` and six domain entities preserve the domain and separate scratch IDs. V11's live SQL check and manifest verify 45,000 Post comments, 5,000 User comments, 30 on the hot post and zero on the reserved empty post. | Full trials must retain fixture identity and scratch cleanup throughout sustained work and recovery. |
| 3. Real HTTP assertions and exceptions | `app/handlers/Api.cfc` and `k6/` exercise reads, relations, writes, rollback, reports, derived-cache variants and real Quick `findOrFail`/`firstOrFail` paths. V12 CI passed malformed contracts and all five application cases; raw traffic, resource and memory reanalysis matches every available saved assessment. Healthy traffic completed 901/901 plateau journeys. | Full-trial evidence must prove all failure cases, follow-ups and per-window coverage at the calibrated rate. Development diagnostics do not prove the full schedule. |
| 4. Continuous external load | Profiles declare 5-minute warmup, 5-minute ramp, 40-minute plateau, 5-minute recovery and 5-minute idle observation. Calibration freezes an eligible rate; it never reduces candidate load automatically. V12 saturation diagnostics distinguish generator exhaustion from application overload. | Complete full-hour traffic delivery, VU headroom, sample coverage and recovery at the capacity-selected rate. |
| 5. Measurement and reports | External JVM/JFR collection, database query/lock counters, application diagnostics and container measurements feed traffic, resource and retained-memory analyzers. V12 measurement pilots independently reproduce healthy, retained-growth and late-growth classifications. Development reports include journey/HTTP rates, per-operation counts/p95/p99 and active requests. | Usable retained-memory observations across the full plateau, complete raw reports and durable storage of accepted evidence. Short development memory remains inconclusive. |
| 6. Calibrated gate | `capacity.py`, `calibration.py`, `baseline.py`, `identity.py` and `qualification.py` implement capacity selection, sealed trials, noise investigation, reviewed baseline requirements and exact candidate receipts. No accepted baseline JSON exists. | Three healthy full trials per accepted hardware cohort, investigation of every retained attempt and runner variation, reviewed absolute latency/resource/memory references, matching detector evidence and durable archive references. |
| 7. Parallel release validation and cancellation | `release/release.yml.pending` and the generated full-proof workflow stage 23 functional rows plus one soak row, native fail-fast, unchanged release triggers/skip semantics, immutable promotion and guarded publication. Smaller native diagnostic proofs and provider tests are retained separately. The live release workflow is not enabled. | Actual full-matrix all-pass, both directions of failure cancellation, explicit cancellation, no-release validation and overlapping serialized publication-stub runs. Then install the verified release workflow. |
| 8. Reviewable delivery and entire-path verification | The README documents local development, measurement, diagnostics, calibration, qualification and full-proof commands plus artifact locations. Diagnostic workflows have no publication capability. | Deliver accepted manifests, full reports, full-matrix/stub evidence and a final requirement-by-requirement audit of the activated gate. |
| 9. Handoff risks | Measurement viability and package/promotion interfaces have dedicated pilots and tests. Bootstrap calibration is separate from publishing. Hardware identity distinguishes Neoverse-N2 and V3; unknown hardware fails closed. Coverage is explicitly limited to the accepted serial sessionless profile. | Resolve CI noise and hardware coverage with measured evidence; complete baseline acceptance and native promotion/cancellation proof. Do not claim reproduction of a historical incident without identifying and reproducing it. |

## Current evidence

Evidence directories below are under `tests/results/soak/` and are local retained
downloads. Their existence does not establish durable archival. The corresponding
GitHub Actions artifacts have finite retention.

| Evidence | Verified result |
|---|---|
| `development-v12-cadence-20260926/development-verification.json` | All 901/901 journeys completed, traffic/resources passed, maximum application observation gap was 5.183 seconds and idle began 26 ms after generator completion. Final JFR, collector flush and live owned-resource cleanup checks passed. Short-schedule memory remains inconclusive. |
| `ci-36252126235-measurement/raw-evidence-verification.json` | V12 raw JVM reanalysis reproduces healthy, retained-growth and late-growth classifications. Final recordings and all child exits verified; cancellation retained partial evidence and could not qualify. |
| `ci-36252126235-saturation/raw-evidence-verification.json` | Both v12 traffic and attribution results exactly match raw reanalysis: generator exhaustion is inconclusive (48/829 journeys), application overload fails (59/94). Final recordings and collector flush verified; original CI cleanup checks passed. |
| `ci-36252126235-application/raw-evidence-verification.json` | All five v12 cases match raw traffic analysis; all four completed cases also match resource and memory reanalysis. Healthy, held-connection, sustained-latency and late-latency cases each completed 901/901 journeys. Largest application sample gap was 5.065 seconds. Original CI passed eight HTTP contract probes, cancellation, observer loss and owned cleanup. |
| `ci-36252126235-application/profile-source-verification.json` | All five cases ran on N2 and match the current v12 measured source, runtime, images, resource limits, fixture fanout and report sizes. Development schedules and diagnostic faults remain explicit; this is not full-trial qualification. |
| `diagnostic-archive-v12-36252126235/archive-verification.json` | Local bundle contains all three v12 diagnostic artifacts, raw reanalysis, reanalysis source and GitHub provenance. All 1,953 source files passed archive readback hashing. Durable remote storage remains pending. |
| `development-v11-fanout-20260926/development-verification.json` | All development checks passed, including direct SQL fixture verification, 901/901 journeys, selected report coverage, collector flush, final recording and owned-resource cleanup. Memory remains inconclusive on this short schedule. |
| `ci-36246858832-measurement/raw-evidence-verification.json` | Raw JVM reanalysis matches all three saved detector results; child exits and final JFR verified. Canceled pilot retained partial evidence and did not qualify. |
| `ci-36246858832-saturation/raw-evidence-verification.json` | Raw attribution matches generator-capacity inconclusive and application-overload failure. Cleanup evidence comes from live checks on the original CI runner. |
| `ci-36246858832-application/raw-evidence-verification.json` | All five v11 application cases match raw k6 reanalysis, with flushed JVM data and final JFR present. Original CI checks passed malformed HTTP contracts, controller cancellation, observer loss and owned-resource cleanup. |
| `ci-36245768374-application/raw-evidence-verification.json` | All five v10 application cases match raw k6 reanalysis. Original CI checks passed HTTP contracts, controller cancellation and observer loss. This is historical v10 evidence. |
| `ci-36244968012/` | Repeated v10 capacity was ineligible after graph latency degradation. The failed attempt remains retained and is not replaced by an earlier eligible result. |
| `ci-36246554787/raw-trial-diagnosis.json` | V11 full trial at 6 journeys/second completed 14,401/14,401 journeys and passed retained memory. One 15.222-second telemetry gap at idle transition made resources inconclusive. Raw reanalysis exactly matches all assessments; the trial is not accepted. |
| `ci-36248290534/raw-trial-diagnosis.json` | Independent v11 full trial also completed 14,401/14,401 journeys and passed retained memory. Its only resource invalidity is a 15.239-second gap at idle transition. All three raw analyses match; this second inconclusive trial is retained and not accepted. |
| `v11-full-trial-comparison.json` | Early per-operation p95 values are compared across both inconclusive v11 trials. Only empty-lookup failure exceeds 10% spread (9 versus 10 ms); retained-memory growth is +36 versus -36 MiB. These are diagnostic noise observations, not an accepted baseline or waived limits. |
| `controller-cadence-regression-20260926/` | The delayed-analysis regression reproduces that gap on the old controller and passes after the v12 change. All 123 telemetry and 57 release tests pass. Live v12 evidence remains required. |
| `v11-ci-host-policy-verification.json` | The bounded 64 KiB host-memory policy matches four actual N2 records with up to 40 KiB variation and rejects V3. Unit coverage rejects changed CPU/cache/heap and altered receipt bounds. |
| `v12-independent-early-host-comparison.json` | The independent v12 allocation is another four-core N2 with matching recorded CPU, image and kernel; usable RAM differs by 36 KiB within the fixed bound. This is early host evidence only; full runtime identity and workload results remain pending. |
| `no-release-current-tree-20260926/verification.json` | Actual semantic-release preparation against live provider identity produced a validation-only package from an identical source tree and rejected publication packaging. No refs changed or CI proof dispatched; complete no-release matrix/soak execution still requires an accepted baseline. |
| `full-proof-verifier-20260926/verification.json` | Failure proofs now reject a missing publication stub or an unexpected extra job. Both regressions reproduced before the fix; all 59 release tests, static checks and workflow drift checks pass. This hardens verification but does not replace native full-matrix execution. |
| `ci-36248290534-runner/` | Independent v11 host identity: four-core Neoverse-N2, Ubuntu ARM image `20260920.129.1`. Full-trial outcome is recorded separately above. |
| `diagnostic-archive-v11-36246858832/archive-verification.json` | Local archive contains all three v11 diagnostic artifacts, raw reanalysis and GitHub provenance. All 1,908 files passed SHA-256 archive readback verification. This prepares diagnostic evidence for durable storage; it does not establish remote archival. |

The diagnostic bundle is `diagnostic-archive-v11-36246858832/v11-diagnostics-36246858832.tar.gz`
(107,150,144 bytes), SHA-256
`94fad5414f2a6e864b47289cdba75468096d2c8ba69652986fe109d10f39d4f0`.
Its `manifest.json` records every member's hash and size; `github-provenance.json`
records the original run SHA and artifact digests and retention dates.

The current v12 diagnostic bundle is
`diagnostic-archive-v12-36252126235/v12-diagnostics-36252126235.tar.gz`
(106,316,566 bytes), SHA-256
`22eb95f8fdc39b5ea2a47c2abddd7883cdec33c79216070aca531f2707dd1343`.
Its manifest and provenance preserve every member's hash/size and the original
GitHub artifact digests. This is a verified local archive, not remote durability.

Current CI handles, checked on 2026-09-26:

- [V12 calibration](https://github.com/coldbox-modules/quick/actions/runs/36252125924): capacity selection passed; the first full-trial step started at 15:57:59 UTC with the corrected controller. No full trial verified yet.
- [Independent v12 calibration](https://github.com/coldbox-modules/quick/actions/runs/36254251872): assigned another four-core N2 and running the measurement pilot. Measured source files and profiles match the primary v12 run exactly; all results will be retained. Dispatch rationale is recorded in `v12-independent-host-plan.json`.
- [V12 diagnostics](https://github.com/coldbox-modules/quick/actions/runs/36252126235): terminal success; all three jobs passed, and measurement, saturation and application raw evidence independently reanalyzed.
- [Primary v11 calibration](https://github.com/coldbox-modules/quick/actions/runs/36246554787): terminal failure after one full, inconclusive trial; raw diagnosis retained.
- [Independent v11 calibration](https://github.com/coldbox-modules/quick/actions/runs/36248290534): terminal failure after its first full trial repeated the idle-transition telemetry gap; complete raw diagnosis retained.
- [V11 diagnostics](https://github.com/coldbox-modules/quick/actions/runs/36246858832): all three jobs passed; measurement, saturation and application raw evidence independently reanalyzed.

## Acceptance order

1. Complete fresh v12 calibration after the cadence fix; matching diagnostics
   have passed and their raw evidence is verified. Retain every failure or partial run. Keep
   the independent v11 result as evidence of the earlier controller behavior.
2. Establish three healthy full trials, resolve noise and hardware differences,
   archive the evidence durably and review the baseline manifests and budgets.
3. Execute and verify every staged full-matrix scenario, including no-release
   validation and two overlapping all-pass runs contending for the publication
   guard. Verify actual tested/uploaded ZIP bytes and raw qualification receipts.
4. Enable the release-only gate with exactly one soak row after acceptance, then
   audit the final workflow, manifests, commands and evidence against the plan.
   Product publication remains part of a separately authorized normal release.
