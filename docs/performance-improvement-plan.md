# Quick performance improvement plan

## Status and scope

- Branch: `codex/quick-performance-audit`
- Baseline: `next` at `fbcf9687d0048f0fc222a4dcb26513720b479fc8`
- Audit date: 2026-08-28
- Baseline runtime: Lucee 6.2.8.20, Java 21.0.10, Apple Silicon, local MySQL
- Compatibility smoke: BoxLang 1.17.0+58 on Java 21.0.12.1

This branch adds a repeatable performance framework and this plan. It does not
retain any production optimization experiments. Expected percentages below are
wall-time reductions, allocation reductions, or retained-heap reductions for
the named operation. They are not additive and are not promises for an entire
application request.

## Executive summary

Quick's dominant local cost is entity construction and the map, function, and
string allocation it triggers in the CFML engine. A warmed, wide `User` entity
allocated about 338 KB before hydration. A local 1,000-row query allocated about
1.8 KB per raw row versus 302 KB per hydrated row. Because the database is
local, hydrated rows were about 92 times slower than raw rows; production
database latency will reduce that ratio, but not the memory pressure.

The most actionable findings are:

1. A duplicate cast and repeated alias/column resolution in `assignAttribute()`
   costs 14-18% in attribute-state operations. A temporary implementation
   measured 18.4% lower assignment time and 21.5% lower assignment allocation.
2. `retrieveAttributesData()` performs a full accessor synchronization and
   state copy. It accounts for 93.5% of a clean `isDirty()` call's time and
   93.9% of its allocation.
3. `QuickBuilder.getEntities()` clones the configured query for every hydrated
   result set, even when no virtual projection needs it. Deferring that clone
   reduced a warmed one-row hydrated query by 22.4% and its allocation by 20.3%
   in a temporary experiment. The gain is below 1% for a 1,000-row result because
   the clone occurs once per result set.
4. Normal post-DI setup adds 18.9% wall time over Quick's internal shallow
   construction boundary for a narrow entity. Deferring memento and no-listener
   lifecycle state until first use should recover 10-16% of entity construction
   time for entities that are never serialized.
5. Lucee shallow component duplication demonstrates a much larger ceiling:
   36.6-48.2% lower construction time and 51.3% lower allocation. It is not safe
   today because mutable instance caches and options leak between the prototype
   and clone. A state-safe factory is the highest-upside, highest-risk project.

A reasonable target for the low- and medium-risk work is 15-30% less Quick CPU
time and 15-30% less allocation in entity-heavy workloads. A state-safe
instantiation redesign could move the total to 35-50% less entity construction
and hydration time. End-to-end application improvement depends on the fraction
of request time spent in Quick.

## Performance framework

The opt-in suite is under `tests/performance` and is deliberately separate from
the functional TestBox suite.

It provides:

- untimed warmup followed by multiple measured samples;
- median, p95, standard deviation, and operations per second;
- current-thread CPU time and allocated bytes through JVM management beans;
- directional post-GC retained-heap probes with a reference-array control;
- JSON output with runtime and configuration metadata;
- raw-versus-hydrated database measurements with fixture work outside the timed
  region and transaction rollback;
- a comparison task with separate wall-time, allocation, and retained-memory
  regression thresholds; and
- 14 CPU/object scenarios, 2 optional database scenarios, and 5 retained-memory
  scenarios.

Run it against an initialized Quick test server with:

```bash
box run-script performance
```

Compare two results with:

```bash
box task run taskFile=tests/performance/Compare.cfc \
    :baseline=tests/results/baseline.json \
    :candidate=tests/results/candidate.json \
    :maxWallRegressionPercent=10 \
    :maxAllocationRegressionPercent=10 \
    :maxRetainedRegressionPercent=10
```

The old `EntityCreationSpec.cfc` mixed fixture setup into two single timings and
printed them during the functional suite. It is replaced by the opt-in harness
so performance results do not make normal tests slow or flaky.

### Measurement rules

1. Compare the same engine, engine version, JVM, heap, database, power mode, and
   machine.
2. Run each revision at least twice in a fresh server process and discard the
   first run. For a claimed improvement, use at least five warmed runs and
   report the median of their medians.
3. Treat wall-time changes below 10% as noise unless CPU and allocation evidence
   agree across runs. Allocation counts were more repeatable than wall time in
   this audit.
4. Confirm retained-heap movement with JFR or another heap profiler. The harness
   estimate is directional, not an object-size API.
5. Keep profiler runs separate from timing runs. JFR sampling materially slowed
   these microbenchmarks, so its timing output was not used.

## Current baseline

These are warmed medians from the second expanded baseline. Allocation is bytes
on the benchmark thread per logical operation.

| Scenario | Median wall time | Allocated bytes |
| --- | ---: | ---: |
| Wide entity construction | 361.04 us/entity | 338,021/entity |
| Narrow entity construction | 285.96 us/entity | 290,133/entity |
| Narrow internal shallow boundary | 240.56 us/entity | 273,741/entity |
| Wide entity construction plus hydration | 432.38 us/entity | 405,693/entity |
| Batch hydration, 100 wide entities | 356.81 us/entity | 404,613/entity |
| Attribute read | 13.82 us/read | 11,936/read |
| Attribute assignment | 10.00 us/write | 8,301/write |
| Attribute-state snapshot | 566.50 us/snapshot | 496,185/snapshot |
| Clean `isDirty()` | 605.88 us/check | 528,353/check |
| Default memento | 151.69 us/memento | 108,163/memento |
| Builder construction | 678.11 us/builder | 622,013/builder |
| Configured builder clone | 806.78 us/clone | 776,021/clone |
| Builder plus common SQL composition | 1,151.11 us/query | 876,597/query |
| `hasMany` relationship construction | 2,234.38 us/relation | 1,615,485/relation |
| Local database raw result, 1,000 rows | 3.19 us/row | 1,845/row |
| Local database hydrated result, 1,000 rows | 292.82 us/row | 302,273/row |

Directional retained-heap medians were:

| Live object | Approximate retained bytes |
| --- | ---: |
| Unloaded wide entity | 159,977 |
| Hydrated wide entity | 161,811 |
| Normally initialized narrow entity | 134,043 |
| Internal shallow narrow entity | 127,568 |
| Builder | 172,762 |

One unloaded-entity retained sample was an outlier. The median is shown, and
allocation/JFR evidence should drive decisions before retained-heap estimates.

## Profiler findings

A 30-second JFR profile recorded 4,970 allocation samples and 64 garbage
collections. One implausible request-cleanup allocation sample above 10 MB was
excluded from the weighted allocation summary.

The leading sampled allocation types were `byte[]` (9.85%), Lucee concurrent-map
entries (8.62%), concurrent-map entry arrays (8.01%), `Object[]` (7.35%),
`String` (6.74%), `HashMap.Node` (5.92%), and `LinkedHashMap.Entry` (4.97%). Stack
traces repeatedly reached `BaseEntity` and concrete entity component
initialization, property accessor creation, `ComponentImpl.registerUDF`, and
mementifier interception. This agrees with the harness: collection and function
metadata churn, not the row copy alone, dominates hydration.

## Prioritized improvements

The percentages in this table are scoped to the affected operation. “Measured”
means a temporary implementation or an existing decomposition produced the
number. “Target” is the acceptance range for a future implementation.

| Priority | Improvement | Expected wall-time reduction | Expected memory reduction | Evidence and confidence |
| --- | --- | ---: | ---: | --- |
| P0 | Cast once and resolve alias/column once in `assignAttribute()` | 14-18% for reads, writes, snapshots, and dirty checks | 14-21% allocated bytes for those operations | Measured; high |
| P0 | Lazily clone the refresh query only when returned rows contain virtual data | 15-25% for one-row/tiny hydrated results; less than 1% at 1,000 rows | 15-22% allocation for one-row/tiny results; less than 1% at 1,000 rows | Measured; high |
| P0 | Replace full snapshot/sort/hash dirty checks with direct, metadata-ordered state comparison | 55-75% for clean `isDirty()` | 60-80% allocation per check | Snapshot is 93.5% of wall and 93.9% of allocation; medium-high |
| P0 | Skip the transformation array copy when no entity transformers or memento conversion are configured | 0-3% for large result handling | Less than 1% in entity-heavy results | Static path analysis; medium |
| P1 | Lazily prepare memento and no-listener lifecycle state | 10-16% entity construction when no memento is requested | 5-6% allocation and 4-5% retained heap per narrow entity | Full versus internal shallow boundary; medium-high |
| P1 | Cache a hydration plan per entity metadata/result shape | 5-12% entity hydration | 5-10% hydration allocation | Repeated `hasAttribute`, alias, column, and cast resolution; medium |
| P1 | Remove dead per-entity state and copy-on-write lazy containers | 2-5% entity construction | 1-4% allocation and retained heap | Static analysis; medium |
| P1 | Pre-normalize and share immutable memento defaults; lazily create date formatters | 15-30% per `getMemento()` | 15-30% allocation per memento | 108 KB/memento plus mementifier source analysis; medium |
| P1 | Lazily allocate builder arrays/maps and cache normalized eager-load graphs | 3-8% builder setup; 10-30% of eager-load setup | 2-8% builder allocation | Static analysis against 622 KB builders; medium-low |
| P2 | Avoid constructing a related entity, builder, and relationship when only an unloaded default/capability is needed | 20-40% for default relationship initialization; 5-15% for normal relationship construction | 10-25% for those paths | 2.23 ms and 1.62 MB per `hasMany`; medium-low |
| P2 | Add a lazy materialized index for deep runtime-attribute overlay chains | 20-50% for lookups at overlay depth above five; no expected default-path gain | 10-30% for repeated deep overlay lookups | Complexity analysis; low until a deep-overlay benchmark is added |
| P3 | Introduce a state-safe entity factory/prototype architecture | 30-45% entity construction and hydration | 35-50% allocation; target 15-30% retained heap | Unsafe prototype measured 36.6-48.2% wall and 51.3% allocation; high upside, high risk |

### P0: remove redundant work

#### 1. Single-pass attribute assignment

`assignAttribute()` currently resolves the alias and column repeatedly and calls
`castValueForSetter()` twice for a normal value. The experimental single-pass
version measured:

| Operation | Wall-time change | Allocation change |
| --- | ---: | ---: |
| Attribute read | -14.5% | -14.9% |
| Attribute assignment | -18.4% | -21.5% |
| Attribute snapshot | -14.4% | -14.8% |
| Clean dirty check | -14.1% | -13.9% |

Implement this first because it is small and reduces the cost of later dirty
tracking work. Preserve null handling, cast-cache semantics, loaded-key guards,
Quick-entity key extraction, custom setters, and runtime attributes.

#### 2. Lazy refresh-query cloning

`getEntities()` currently clones `variables.qb` before it knows whether a row
contains a virtual projection. `loadEntity()` only stores that clone for virtual
data. Detect the projection from the consistent result shape, clone at most once,
and pass no refresh query otherwise.

For a one-row local query, the second experimental run changed:

- total hydrated wall time: 2.176 ms to 1.688 ms (-22.4%);
- total allocation: 1,189,616 to 948,096 bytes (-20.3%);
- hydration surcharge over the matching raw query: -57.4% wall and -43.9%
  allocation.

Keep clone behavior unchanged for virtual attributes, discriminated children,
`fresh()`, and `refresh()`.

#### 3. Direct dirty comparison

`isDirty()` calls `retrieveAttributesData()`, which synchronizes every generated
accessor by routing it through `assignAttribute()`, builds a new struct, sorts
keys, builds a string, and hashes it. The same broad work happens for a
single-attribute dirty check.

Build and cache a metadata-ordered comparison plan. Read each current value from
the accessor-backed variables scope when present, otherwise from `_data`, and
compare its null/value state with `_originalAttributes` without materializing a
full output struct. Cache the original normalized comparison state at hydration
and update or invalidate it only at existing state-transition points.

Do not introduce a dirty set that misses direct generated setter calls. Tests
must cover direct setters, custom setters/getters, casts, nulls, aliases, reset,
replicate, refresh, save, composite keys, and runtime attributes.

### P1: make optional state genuinely optional

#### 4. Lazy memento and event preparation

Every normal entity builds memento defaults from all attributes. Mementifier then
injects helper UDFs and creates two `SimpleDateFormat` instances per decorated
entity. Many entities are never serialized.

Prototype a Quick-owned lazy gateway that preserves `getMemento()` and custom
memento overrides while deferring normalized defaults and formatters until the
first serialization. Cache immutable defaults in entity metadata; copy only
when instance-level memento configuration is mutated. Separately verify whether
the interceptor service can expose a safe no-listener fast path. Never cache a
negative listener result if listeners can be registered dynamically.

The narrow full-versus-shallow boundary supports a target of 10-16% lower
construction time, 5-6% lower allocation, and 4-5% lower retained heap when no
memento is requested. First-use serialization may shift, rather than erase, some
of this cost and must remain within 5% of the current memento benchmark.

#### 5. Lazy/copy-on-write instance containers

Audit `assignDefaultProperties()` and `QuickBuilder.init()` field by field:

- `_globalScopeExclusions`, `_applyingGlobalScopes`, and
  `_globalScopesApplied` are unused on `BaseEntity`;
- `_nullValueArgumentSentinel` can be replaced with `arguments.keyExists()`;
- `_withoutRelationshipConstraints` eagerly creates a Java `HashSet`;
- relationship data, relationship-loaded flags, cast caches, caster caches, and
  runtime overlay containers start empty for every entity;
- several empty metadata containers are immediately replaced by cached metadata;
- `_virtualAttributes` copies the declared metadata array even when the entity
  never adds a runtime virtual attribute; and
- builders eagerly allocate eager-load, transformer, memento-settings,
  global-scope, and alias containers plus a fallback lazy-loading closure.

Use explicit lazy getters and copy-on-write before mutation. Do not share mutable
empty structs or arrays. Generated accessors and existing introspection methods
must continue to return the documented empty value.

#### 6. Cached hydration plans

`populateAttributes()` performs repeated attribute existence, alias, column, and
cast lookup for every row. Compile an immutable plan from cached entity metadata
and the result column shape, then apply it to each entity in the caller thread.
Invalidate only when a runtime attribute overlay changes the effective shape.

This should be developed after the single-pass setter work. Target 5-12% lower
hydration time and 5-10% lower hydration allocation without changing event,
cast, null, or original-state behavior.

### P2: reduce relationship and eager-load setup

`hasMany()` construction currently creates the related entity, its builder, the
relationship component, and constraints. Cache immutable relationship
capabilities in entity metadata so new-entity default initialization can return
the correct empty collection/null value without constructing the query graph.
Create the builder on the first query-mutating or execution method.

Also cache `denestEagerLoads()` output until `_eagerLoad` changes. Add dedicated
benchmarks for one relation, multiple independent relations, nested relations,
parameter-limit chunking, raw mode, memento mode, and empty results before
claiming an end-to-end gain.

The opt-in parallel eager-loading work exists on a separate remote feature
branch, not on `next`. Benchmark it independently after hydration allocation is
reduced. Parallel I/O can improve wall time for independent, latency-bound
relations but can increase peak memory and database pressure; it is not a
substitute for the allocation work in this plan.

### P3: state-safe entity instantiation

A temporary Lucee experiment used `duplicate( prototype, false ).resetToNew()`.
It was 36.6-48.2% faster and allocated 51.3% less than WireBox construction.
Simple attribute data was isolated, but the relationship-constraint set, cast
cache, and query options were shared. That reproduces the class of correctness
problem that caused Quick's earlier shallow-duplicate factory to be removed.

Do not restore shallow duplication directly. First define every field as one of:

- immutable mapping metadata that may be shared;
- dependency/function state that may be shared only if the engine guarantees it;
- mutable instance state that must be newly allocated; or
- optional mutable state that starts absent and is allocated on first mutation.

Then prototype either:

1. an engine-specific factory that shallow-copies immutable component structure
   and installs a fresh explicit state carrier, or
2. a broader entity-definition/entity-state split that keeps mapping and
   function metadata out of each row object.

The acceptance target is 30-45% lower construction/hydration wall time and
35-50% lower allocation while proving no cross-instance state leaks. Keep the
WireBox path as the fallback on engines where the optimized factory is not
provably safe.

## Delivery sequence

Use small PRs so each percentage can be accepted or rejected independently:

1. Benchmark framework and audit plan.
2. Single-pass attribute assignment and lookup.
3. Direct dirty comparison.
4. Lazy refresh-query clone and no-op result transformation.
5. Lazy memento/lifecycle preparation.
6. Lazy/copy-on-write entity and builder containers.
7. Cached hydration plan.
8. Relationship capability metadata and lazy builders.
9. State-safe entity factory prototype behind an internal feature flag.

Each PR should include its focused regression tests, before/after JSON from the
same runtime, at least five warmed measurements, allocation evidence, and the
full functional matrix result. Revert an optimization whose gain does not clear
the noise threshold unless it materially simplifies memory behavior.

## Verification matrix and gates

Functional behavior must remain identical across:

- Lucee 5 and 6;
- Adobe ColdFusion 2021, 2023, and 2025;
- BoxLang 1 in native and CFML compatibility modes;
- full-null-support on and off;
- inherited/discriminated entities and composite keys;
- declared and runtime attributes, aliases, all cast types, and null values;
- custom getters/setters and direct generated accessors;
- lifecycle methods, Quick interception points, custom dispatched events, and
  `withoutFiringEvents()`;
- default and overridden mementos, profiles, nested relationships, date masks,
  and timezones;
- refresh queries with virtual projections;
- new, loaded, replicated, reset, saved, refreshed, and deleted entities; and
- new-entity relationship defaults, eager loading, lazy-loading prevention, and
  relationship-loaded hooks.

Performance acceptance gates:

- no functional TestBox failures;
- no public API or serialized-shape change;
- no cross-instance mutable-state leak;
- no greater than 5% regression in an unaffected core benchmark;
- claimed wall-time gain above 10% across warmed runs, or corroborating CPU and
  allocation evidence for a smaller hot-path gain;
- no allocation or retained-memory regression unless explicitly justified; and
- a follow-up JFR showing no new high-pressure allocation class or increased GC
  frequency for the same workload.

A future CI performance job should use a pinned, dedicated runner and preserve
the JSON artifacts. Shared hosted runners are suitable for smoke execution, not
hard wall-time gates.

## Expected aggregate impact

Do not sum the individual rows. They overlap heavily.

- P0 only: target 10-20% less Quick CPU and allocation in state-heavy code, with
  up to 25% lower latency for tiny hydrated result sets.
- P0 plus P1: target 15-30% less entity-heavy wall time and allocation, and
  5-15% less retained heap depending on memento, casts, and relationships.
- With a successful P3 factory: target 35-50% less entity construction/hydration
  time and 35-55% less allocation. A local 1,000-row hydrated query should target
  25-45% lower total wall time.

For an application request, apply Amdahl's law. If Quick accounts for 40% of the
request and the affected Quick work becomes 30% faster, the expected request
improvement is about 12%, not 30%.

## Evaluation log

### 2026-08-28: single-pass attribute assignment — accepted

Five warmed Lucee 6.2.8.20 runs compared the branch baseline with the candidate
using 10 warmups, 15 samples, 50 iterations, and the median of run medians.

| Scenario | Wall-time change | Allocation change |
| --- | ---: | ---: |
| Attribute assignment | -20.66% | -21.65% |
| Attribute read | -16.13% | -15.01% |
| Attribute snapshot | -15.42% | -15.04% |
| Clean `isDirty()` | -14.43% | -14.15% |

The full Lucee suite passed with 616 passes, 0 failures, 0 errors, and 3 skips.
The implementation was retained because it clears both the wall-time and
allocation gates while preserving entity-key assignment behavior.

### 2026-08-28: lazy refresh-query clone — accepted

Five warmed runs measured database hydration with one row and 1,000 rows. The
one-row median fell from 2.700 ms to 1.937 ms (-28.26%) and allocation fell from
1,186,120 to 947,168 bytes (-20.15%). At 1,000 rows, per-row time fell 5.03%
while allocation was effectively unchanged (-0.08%), confirming that the
removed clone is a fixed per-result-set cost. The existing `loadEntity()`
virtual-data guard remains responsible for cloning when refresh state is
actually required.

### 2026-08-28: direct dirty comparison — abandoned

A prototype compared `_data` directly with `_originalAttributes` after syncing
generated accessors. It caused 10 Lucee suite failures involving partially
selected, null, excluded, saved, and refreshed state. The hash path's exact key
presence semantics are part of current behavior, so the prototype was reverted
without a commit. A future attempt needs a canonical metadata-ordered state
model plus explicit cross-engine null/missing-value tests before timing.

### 2026-08-28: no-op transformation copy — abandoned

Skipping the result-array copy when no entity transformers were configured did
not clear the gate. Across five warmed 1,000-row runs, hydrated time changed
from 265.502 to 268.957 us/row (+1.30%) and allocation fell only 0.16%. The
candidate was reverted without a commit.

### 2026-08-28: lazy relationship-constraint container — abandoned

Deferring the per-entity `HashSet` was measured across five warmed wide and
narrow construction runs. Wide construction regressed 2.57% with 0.05% more
allocation; narrow construction improved only 0.50% with allocation unchanged.
The extra branches did not recover measurable memory, so the candidate was
reverted without a commit.

### 2026-08-28: lazy deep runtime-attribute index — accepted

A new benchmark resolves the oldest attribute in a ten-node runtime overlay.
Across five warmed runs, median lookup time fell from 4.709 to 2.202 us
(-53.23%) and allocation fell from 4,112 to 2,064 bytes (-49.80%). The declared
attribute-read control changed by +1.13% with allocation unchanged. The index
is per entity, appears only after traversal reaches six nodes, and is invalidated
when another runtime attribute is registered. The full Lucee suite passed with
617 passes, 0 failures, 0 errors, and 3 skips.

### 2026-08-28: lazy memento/lifecycle preparation — abandoned

A prototype omitted eager mementifier setup. Across five warmed runs, wide
construction improved 3.13% with 2.86% less allocation; narrow construction
improved only 0.29% with 4.30% less allocation. It missed the wall-time gate and
immediately broke `getMemento()` because the injected mementifier expects the
public `this.memento` configuration to exist. `instanceReady` also remains an
observable lifecycle contract and cannot be deferred. The prototype was
reverted without a commit.

### 2026-08-28: cached hydration plan — abandoned on this branch

The proposed plan would need to cache alias, column, virtual, cast, and setter
decisions by both entity metadata version and result shape. Quick entities can
add runtime attributes after construction, child discrimination can select a
different mapping per row, and custom casts/setters remain instance behavior.
The current metadata has no stable version covering all of those mutations.
Caching only declared aliases would duplicate the now-cheap map lookups while
leaving the expensive cast and entity construction paths unchanged. No safe,
bounded prototype was retained; this requires an explicit immutable mapping
definition/version before it can meet the public-behavior gate.

### 2026-08-28: remaining copy-on-write entity containers — abandoned

The relationship-constraint `HashSet` prototype was the only isolated container
with a clear lazy boundary, and it recovered no measurable allocation. The
remaining `_data`, original-state, relationship-state, cast, and eager-load
containers are exposed through generated accessors or participate in reset,
clone, and new-entity behavior. Removing them independently would add branches
without removing the component/function metadata that dominates allocation.
A broader explicit entity-state carrier belongs with the factory redesign, not
as piecemeal lazy fields.

### 2026-08-28: shared memento defaults and lazy formatters — abandoned

`this.memento` is a public, mutable per-entity configuration consumed by the
external mementifier module. Sharing its arrays/maps would allow one entity's
configuration changes to leak to siblings, while date formatter creation lives
inside that dependency rather than Quick. The measured eager-setup removal was
already below the wall-time gate. This item needs a mementifier-level immutable
compiled configuration API before Quick can safely adopt it.

### 2026-08-28: lazy builder containers and cached eager graphs — abandoned

QuickBuilder's arrays/maps are mutable through `with()`, `without()`, clear,
clone, and generated accessors. The normalized eager graph is normally built
once and consumed once when a builder executes, so caching it adds invalidation
to a path with no demonstrated reuse. Builder allocation is dominated by
WireBox/component and underlying qb construction, not the empty arrays. This
item is abandoned until a benchmark demonstrates repeated normalization on an
unchanged builder or builder state is split from immutable query metadata.

### 2026-08-28: relationship capability metadata/lazy relationship builders — abandoned

Relationship methods are arbitrary CFML functions: they can accept arguments,
apply conditional constraints, return custom relationship subclasses, and run
user code. Quick cannot infer the unloaded default or required relationship
class without invoking that method, which is the work this suggestion intended
to avoid. A safe implementation requires new declarative relationship metadata
or generated mapping metadata, which would be an API/architecture project and
cannot be introduced as a transparent optimization on this branch.

### 2026-08-28: state-safe entity factory — abandoned

The measured shallow-duplicate prototype remains fast enough to justify future
architecture work, but it shares mutable relationship-constraint, cast-cache,
and query-option state between instances. That fails the explicit no-state-leak
gate and recreates the correctness class that removed Quick's former shallow
factory. A safe factory needs an immutable entity definition plus a freshly
allocated state carrier, with an engine-specific fallback. No unsafe prototype
is retained or committed here.

## Final disposition

All twelve suggestions were evaluated. Three were accepted and committed:
single-pass attribute assignment, lazy refresh-query cloning, and the lazy deep
runtime-attribute index. Nine were abandoned on this branch because they missed
the performance gate, failed functional behavior, lacked a safe invalidation or
laziness boundary, or require an explicit architecture/API change. “Abandoned”
here means no production code from the experiment remains; the architectural
items can be reconsidered once their stated prerequisites exist.

Final committed-head verification:

- Lucee 6.2.8.20: 617 passed, 0 failed, 0 errors, 3 skipped.
- BoxLang 1.17.0+58 CFML compatibility mode: 618 passed, 0 failed, 0 errors, 2 skipped.
- BoxLang 1.17.0+58 native mode: 618 passed, 0 failed, 0 errors, 2 skipped.
