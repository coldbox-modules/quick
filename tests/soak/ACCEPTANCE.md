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

The first v12 full-hour CI trial is independently verified healthy at the
capacity-selected 6 journeys/second: traffic, delivery, resources and retained
memory reproduce from raw evidence, and its evidence seal verifies. Two more
matching healthy trials and the independent-host review remain required before
baseline acceptance.

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
| `ci-36252125924-trial-1/raw-trial-review.json` | First v12 full trial is `calibration-passed`: 14,401/14,401 journeys at 6/second, all four raw assessments reproduce and the evidence seal verifies. Maximum application sample gap is 10.099 seconds; idle starts 23 ms after generator completion. Collector flush and a 30,055,461-byte final JFR are retained. This is one healthy trial, not an accepted baseline. |
| `ci-36252125924-trial-1/profile-source-coverage-verification.json` | Current measured sources and calibrated profile match exactly. Each of five expected failure cases has 2,304 attempts, verifications and successful follow-ups; the minimum operation/window latency count is 212 against the 200 floor. Boot identity and final resource release checks pass. Retained growth is 18 MiB across 155 major cycles, with no memory warnings. |
| `calibration-archive-v12-36252125924/trial-1-remote-verification.json` | Original Actions ZIP matches GitHub's digest and all 212 members match the reviewed download. All five assets in draft evidence release `397323222` pass remote readback hashing. Replaying the archived analyzer sources reproduces the complete review. The draft remains editable; latest product release v13.0.4 is unchanged. |
| `development-v12-cadence-20260926/development-verification.json` | All 901/901 journeys completed, traffic/resources passed, maximum application observation gap was 5.183 seconds and idle began 26 ms after generator completion. Final JFR, collector flush and live owned-resource cleanup checks passed. Short-schedule memory remains inconclusive. |
| `ci-36252126235-measurement/raw-evidence-verification.json` | V12 raw JVM reanalysis reproduces healthy, retained-growth and late-growth classifications. Final recordings and all child exits verified; cancellation retained partial evidence and could not qualify. |
| `ci-36252126235-saturation/raw-evidence-verification.json` | Both v12 traffic and attribution results exactly match raw reanalysis: generator exhaustion is inconclusive (48/829 journeys), application overload fails (59/94). Final recordings and collector flush verified; original CI cleanup checks passed. |
| `ci-36252126235-application/raw-evidence-verification.json` | All five v12 cases match raw traffic analysis; all four completed cases also match resource and memory reanalysis. Healthy, held-connection, sustained-latency and late-latency cases each completed 901/901 journeys. Largest application sample gap was 5.065 seconds. Original CI passed eight HTTP contract probes, cancellation, observer loss and owned cleanup. |
| `ci-36252126235-application/profile-source-verification.json` | All five cases ran on N2 and match the current v12 measured source, runtime, images, resource limits, fixture fanout and report sizes. Development schedules and diagnostic faults remain explicit; this is not full-trial qualification. |
| `diagnostic-archive-v12-36252126235/archive-verification.json` | Bundle contains all three v12 diagnostic artifacts, raw reanalysis, reanalysis source and GitHub provenance. All 1,953 source files passed archive readback hashing. Remote-copy verification is recorded separately below. |
| `diagnostic-archive-v12-36252126235/remote-verification.json` | All four assets downloaded from draft evidence release `397309485` match their local SHA-256 hashes and GitHub digests. The draft points to the measured commit; latest product release v13.0.4 is unchanged. The retained draft is editable, not an immutable published release. |
| `development-v11-fanout-20260926/development-verification.json` | All development checks passed, including direct SQL fixture verification, 901/901 journeys, selected report coverage, collector flush, final recording and owned-resource cleanup. Memory remains inconclusive on this short schedule. |
| `ci-36246858832-measurement/raw-evidence-verification.json` | Raw JVM reanalysis matches all three saved detector results; child exits and final JFR verified. Canceled pilot retained partial evidence and did not qualify. |
| `ci-36246858832-saturation/raw-evidence-verification.json` | Raw attribution matches generator-capacity inconclusive and application-overload failure. Cleanup evidence comes from live checks on the original CI runner. |
| `ci-36246858832-application/raw-evidence-verification.json` | All five v11 application cases match raw k6 reanalysis, with flushed JVM data and final JFR present. Original CI checks passed malformed HTTP contracts, controller cancellation, observer loss and owned-resource cleanup. |
| `ci-36245768374-application/raw-evidence-verification.json` | All five v10 application cases match raw k6 reanalysis. Original CI checks passed HTTP contracts, controller cancellation and observer loss. This is historical v10 evidence. |
| `ci-36244968012/` | Repeated v10 capacity was ineligible after graph latency degradation. The failed attempt remains retained and is not replaced by an earlier eligible result. |
| `ci-36246554787/raw-trial-diagnosis.json` | V11 full trial at 6 journeys/second completed 14,401/14,401 journeys and passed retained memory. One 15.222-second telemetry gap at idle transition made resources inconclusive. Raw reanalysis exactly matches all assessments; the trial is not accepted. |
| `ci-36248290534/raw-trial-diagnosis.json` | Independent v11 full trial also completed 14,401/14,401 journeys and passed retained memory. Its only resource invalidity is a 15.239-second gap at idle transition. All three raw analyses match; this second inconclusive trial is retained and not accepted. |
| `v11-full-trial-comparison.json` | Rounded early per-operation p95 values are compared across both inconclusive v11 trials. Only empty-lookup failure exceeds 10% spread (9 versus 10 ms); retained-memory growth is +36 versus -36 MiB. These are diagnostic noise observations, not an accepted baseline or waived limits. |
| `v11-latency-quantization-investigation.json` | Raw nearest-rank p95 reproduces all 21 saved sample counts and rounded values in both trials. Empty-lookup spread is 9.80% raw versus 10.53% rounded; relationship-failure spread is 10.70% raw versus 9.52% rounded. Baseline review must inspect both representations; neither trial is accepted and the 10% criterion is unchanged. |
| `trial-review-verification-20260926/verification.json` | The reusable offline `review_trial.py` reproduces traffic, delivery, resources, memory and all 21 exact latency references from both v11 full trials. It rejects a deliberately altered saved assessment and preserves existing review files. Both v11 trials remain inconclusive; the first v12 trial above also verifies the real passing-trial seal path. |
| `controller-cadence-regression-20260926/` | The delayed-analysis regression reproduces that gap on the old controller and passes after the v12 change. All 123 telemetry and 57 release tests pass. Live v12 evidence remains required. |
| `v11-ci-host-policy-verification.json` | The bounded 64 KiB host-memory policy matches four actual N2 records with up to 40 KiB variation and rejects V3. Unit coverage rejects changed CPU/cache/heap and altered receipt bounds. |
| `v12-independent-early-host-comparison.json` | The independent v12 allocation is another four-core N2 with matching recorded CPU, image and kernel; usable RAM differs by 36 KiB within the fixed bound. This is early host evidence only; full runtime identity and workload results remain pending. |
| `no-release-current-tree-20260926/verification.json` | Actual semantic-release preparation against live provider identity produced a validation-only package from an identical source tree and rejected publication packaging. No refs changed or CI proof dispatched; complete no-release matrix/soak execution still requires an accepted baseline. |
| `full-proof-verifier-20260926/verification.json` | Failure proofs now reject a missing publication stub or an unexpected extra job. Both regressions reproduced before the fix; all 59 release tests, static checks and workflow drift checks pass. This hardens verification but does not replace native full-matrix execution. |
| `full-proof-cleanup-verifier-20260926/verification.json` | Successful full-matrix proofs now require retained cleanup evidence for the same run, including the anonymous database volume. Missing evidence and a leaked volume reproduced false acceptance before the fix; all 61 release tests pass after it, including rejection of another run's cleanup record. Generated workflow and diff checks pass; native full-matrix execution remains pending. |
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
GitHub artifact digests. A separate copy is retained in the
[draft evidence release](https://github.com/coldbox-modules/quick/releases/tag/untagged-c6b000fea7b0cccd7997)
(release ID `397309485`, bundle asset ID `591005637`). All four archive assets
passed downloaded-byte verification. Draft access requires repository permission;
the draft is editable and does not accept a baseline or publish Quick.

The first healthy full trial is retained in a separate
[draft calibration evidence release](https://github.com/coldbox-modules/quick/releases/tag/untagged-428fc0de3f77361e1253)
(release ID `397323222`). The original ZIP is 27,383,873 bytes, SHA-256
`5f8266d1df796f78303dd627b9f42ef110b095dd6459a6dc197aef2c5ceffd20`.
Its five assets include the member manifest, review source/results and archive
reproduction proof. Remote readback verification is recorded separately above.
This retains one healthy trial outside Actions expiry; baseline acceptance and
remaining trials are still pending.

Current CI handles, checked on 2026-09-26:

- [V12 calibration](https://github.com/coldbox-modules/quick/actions/runs/36252125924): capacity selection and trial one passed; raw trial evidence independently verified. Trial two started at 16:59:57 UTC with the same frozen target and profile.
- [Independent v12 calibration](https://github.com/coldbox-modules/quick/actions/runs/36254251872): capacity selection passed on another four-core N2; the first full-trial step started at 16:34:33 UTC. Measured source files and profiles match the primary v12 run exactly; all results will be retained. Dispatch rationale is recorded in `v12-independent-host-plan.json`.
- [V12 diagnostics](https://github.com/coldbox-modules/quick/actions/runs/36252126235): terminal success; all three jobs passed, and measurement, saturation and application raw evidence independently reanalyzed.
- [Primary v11 calibration](https://github.com/coldbox-modules/quick/actions/runs/36246554787): terminal failure after one full, inconclusive trial; raw diagnosis retained.
- [Independent v11 calibration](https://github.com/coldbox-modules/quick/actions/runs/36248290534): terminal failure after its first full trial repeated the idle-transition telemetry gap; complete raw diagnosis retained.
- [V11 diagnostics](https://github.com/coldbox-modules/quick/actions/runs/36246858832): all three jobs passed; measurement, saturation and application raw evidence independently reanalyzed.

## Acceptance order

1. Complete fresh v12 calibration after the cadence fix; matching diagnostics
   have passed and their raw evidence is verified. Retain every failure or partial run. Keep
   the independent v11 result as evidence of the earlier controller behavior.
2. Establish three healthy full trials, resolve noise and hardware differences,
   inspect raw and rounded latency variation, archive the evidence durably and
   review the baseline manifests and budgets.
3. Execute and verify every staged full-matrix scenario, including no-release
   validation and two overlapping all-pass runs contending for the publication
   guard. Verify actual tested/uploaded ZIP bytes and raw qualification receipts.
4. Enable the release-only gate with exactly one soak row after acceptance, then
   audit the final workflow, manifests, commands and evidence against the plan.
   Product publication remains part of a separately authorized normal release.
