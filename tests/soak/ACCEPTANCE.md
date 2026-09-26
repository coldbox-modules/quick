# Release soak acceptance

Current assessment: **incomplete**. This checklist maps the numbered
[implementation plan](../../docs/release-soak-testing-plan.md) to evidence and
remaining acceptance work. It is an evidence index, not an accepted baseline.
See [README.md](README.md) for commands and the retained calibration history.

The current standard profile is v11: Lucee 6, ColdBox 8, Java 21, MySQL,
serial eager loading, 25/50/100-row reports and 30-comment hot-post fanout on
the standard four-core GitHub ARM runner. The dataset remains 20 teams,
1,000 users, 10,000 posts, 50,000 comments, 100 tags and 17,144 pivots.
The 60-minute schedule, exception mix, sample floors and blocking criteria
remain unchanged. The separate parallel and larger-report profiles are not
qualified by standard-profile evidence.

## Requirements and proof boundaries

| Plan item | Implementation and available evidence | Still required for completion |
|---|---|---|
| 1. Persistent isolated application | `app/Application.cfc` uses normal ColdBox bootstrap, a four-hour application timeout, sessionless requests and lifecycle identifiers. The controller provisions isolated application, database and generator containers with recorded budgets and package/dependency identities. The v11 development run passed lifecycle/resource checks. | Matching full-hour CI trials must establish continuous lifecycle and healthy behavior under the final load. |
| 2. Deterministic domain | `fixtures/generate.py`, `Seed.cfc` and six domain entities preserve the domain and separate scratch IDs. V11's live SQL check and manifest verify 45,000 Post comments, 5,000 User comments, 30 on the hot post and zero on the reserved empty post. | Full trials must retain fixture identity and scratch cleanup throughout sustained work and recovery. |
| 3. Real HTTP assertions and exceptions | `app/handlers/Api.cfc` and `k6/` exercise reads, relations, writes, rollback, reports, derived-cache variants and real Quick `findOrFail`/`firstOrFail` paths. V11 CI passed malformed contracts and all five application cases; raw k6 reanalysis matches every saved result. Healthy traffic completed 901/901 plateau journeys. | Full-trial evidence must prove all failure cases, follow-ups and per-window coverage at the calibrated rate. Development diagnostics do not prove the full schedule. |
| 4. Continuous external load | Profiles declare 5-minute warmup, 5-minute ramp, 40-minute plateau, 5-minute recovery and 5-minute idle observation. Calibration freezes an eligible rate; it never reduces candidate load automatically. V11 saturation diagnostics distinguish generator exhaustion from application overload. | Complete full-hour traffic delivery, VU headroom, sample coverage and recovery at the capacity-selected rate. |
| 5. Measurement and reports | External JVM/JFR collection, database query/lock counters, application diagnostics and container measurements feed traffic, resource and retained-memory analyzers. V11 measurement pilots independently reproduce healthy, retained-growth and late-growth classifications. Development reports include journey/HTTP rates, per-operation counts/p95/p99 and active requests. | Usable retained-memory observations across the full plateau, complete raw reports and durable storage of accepted evidence. Short development memory remains inconclusive. |
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
| `development-v11-fanout-20260926/development-verification.json` | All development checks passed, including direct SQL fixture verification, 901/901 journeys, selected report coverage, collector flush, final recording and owned-resource cleanup. Memory remains inconclusive on this short schedule. |
| `ci-36246858832-measurement/raw-evidence-verification.json` | Raw JVM reanalysis matches all three saved detector results; child exits and final JFR verified. Canceled pilot retained partial evidence and did not qualify. |
| `ci-36246858832-saturation/raw-evidence-verification.json` | Raw attribution matches generator-capacity inconclusive and application-overload failure. Cleanup evidence comes from live checks on the original CI runner. |
| `ci-36246858832-application/raw-evidence-verification.json` | All five v11 application cases match raw k6 reanalysis, with flushed JVM data and final JFR present. Original CI checks passed malformed HTTP contracts, controller cancellation, observer loss and owned-resource cleanup. |
| `ci-36245768374-application/raw-evidence-verification.json` | All five v10 application cases match raw k6 reanalysis. Original CI checks passed HTTP contracts, controller cancellation and observer loss. This is historical v10 evidence. |
| `ci-36244968012/` | Repeated v10 capacity was ineligible after graph latency degradation. The failed attempt remains retained and is not replaced by an earlier eligible result. |
| `ci-36248290534-runner/` | Independent v11 host identity: four-core Neoverse-N2, Ubuntu ARM image `20260920.129.1`. This proves identity, not workload completion. |
| `diagnostic-archive-v11-36246858832/archive-verification.json` | Local archive contains all three v11 diagnostic artifacts, raw reanalysis and GitHub provenance. All 1,908 files passed SHA-256 archive readback verification. This prepares diagnostic evidence for durable storage; it does not establish remote archival. |

The diagnostic bundle is `diagnostic-archive-v11-36246858832/v11-diagnostics-36246858832.tar.gz`
(107,150,144 bytes), SHA-256
`94fad5414f2a6e864b47289cdba75468096d2c8ba69652986fe109d10f39d4f0`.
Its `manifest.json` records every member's hash and size; `github-provenance.json`
records the original run SHA and artifact digests and retention dates.

Current CI handles, checked on 2026-09-26:

- [Primary v11 calibration](https://github.com/coldbox-modules/quick/actions/runs/36246554787): full-trial step running; no full trial verified yet.
- [Independent v11 calibration](https://github.com/coldbox-modules/quick/actions/runs/36248290534): first full-trial step started at 14:50:31 UTC on another standard runner; no full trial verified yet.
- [V11 diagnostics](https://github.com/coldbox-modules/quick/actions/runs/36246858832): all three jobs passed; measurement, saturation and application raw evidence independently reanalyzed.

## Acceptance order

1. Inspect complete raw evidence from both current calibration attempts. Retain
   failures and partial runs alongside the verified matching diagnostic suite.
2. Establish three healthy full trials, resolve noise and hardware differences,
   archive the evidence durably and review the baseline manifests and budgets.
3. Execute and verify every staged full-matrix scenario, including no-release
   validation and two overlapping all-pass runs contending for the publication
   guard. Verify actual tested/uploaded ZIP bytes and raw qualification receipts.
4. Enable the release-only gate with exactly one soak row after acceptance, then
   audit the final workflow, manifests, commands and evidence against the plan.
   Product publication remains part of a separately authorized normal release.
