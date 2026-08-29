# Quick performance architecture plan

## Status and scope

- Branch: `codex/quick-performance-audit`
- Production-code head under test: `883f718f4e7c592cebb4ec02a93ed7358f5d47e8`
- Baseline branch: `next` at `fbcf9687d0048f0fc222a4dcb26513720b479fc8`
- Audit date: 2026-08-28
- Runtimes: Lucee 6.2.8.20, Adobe ColdFusion 2021.0.22, and BoxLang
  1.17.0+58
- Scope: architecture analysis, benchmark extensions, and an implementation
  plan; no production optimization is implemented by this document

This is the second performance pass. The first pass accepted three isolated
optimizations and established that the remaining large gains require changes to
Quick's internal architecture. This plan investigates those underpinnings,
especially metadata compilation, metadata caching, entity construction,
hydration, builders, and relationships.

All expected percentages below are targets for the named operation. They are
not additive and are not promises for an entire application request. Retained
heap percentages require profiler confirmation before they can be claimed.

## Executive findings

1. Quick's metadata cache mixes two different lifetimes. Authoritative entity
   definitions, the BaseEntity function index, discriminations, and qualified
   columns derived from runtime overlays and table names all occupy the same
   CacheBox cache. The default limit is 300 objects. Runtime-derived key churn
   can therefore evict a mapping definition and expose part of a 12.37-21.67 ms
   full-cold metadata path.
2. The warmed CacheBox lookup itself is 3.7-4.8 times slower than reading the
   definition already bound to an entity. This is a small operation in absolute
   terms, but it shows that CacheBox is the wrong hot-path abstraction for an
   immutable process-lifetime mapping definition.
3. Quick retains the engines' complete inherited and local metadata graphs in
   every cached definition. The representative 19-attribute `User` definition
   serializes to 208,205-355,563 characters and includes 217-331 inherited
   function descriptions. Quick's hot path needs only a normalized subset.
4. Entity allocation is largely independent of mapping width. Moving from the
   narrow entity to the wide entity adds only 84-119 us, while total
   construction is 290-618 us. CFML component creation, DI, generated methods,
   mementifier setup, and rebinding definition fields dominate the row data.
5. Hydration, not the local database, dominates the measured database path. A
   hydrated row is 62 times the raw-row cost on BoxLang, 82 times on Lucee, and
   129 times on Adobe ColdFusion in this local fixture. Network and production
   database latency will reduce those ratios, but not the allocation pressure.
6. Builder and relationship construction remain high-value redesign targets.
   Builder creation costs 0.70-2.17 ms. A `hasMany` construction costs
   2.89-4.26 ms and allocates about 1.60 MB on Lucee or 4.34 MB on BoxLang.
7. BoxLang magnifies allocation-heavy paths: a clean dirty check allocates
   about 3.05 MB, an attribute snapshot 2.67 MB, and a builder 2.17 MB. The
   architecture should reduce transient structs, arrays, closures, and
   defensive copies rather than add engine-specific shortcuts.

## Measurement method

Each engine ran five complete warmed benchmark passes on the same Apple Silicon
machine and local MySQL database. A pass used 10 warmup iterations, 11 samples,
30 iterations per sample, and 1,000 database rows. The reported value is the
median of the five per-run medians.

The database scenarios use three timed queries per sample after untimed fixture
setup. `metadata.cold_compile` uses one warmup and seven one-operation samples;
it clears Quick's entire metadata cache and constructs an entity through
WireBox inside the measured callback. It therefore represents the full cold
path, including cache clearing, BaseEntity index rebuilding, metadata
compilation, and normal entity construction. It is not an isolated reflection
timer. Allocation is current-thread allocation and is available on Lucee and
BoxLang, but not on this Adobe ColdFusion runtime.

One separate directional retained-heap run per engine held 100 live objects and
used three post-GC samples. Engine object layouts and garbage collectors differ,
so retained figures are suitable for same-engine before/after comparisons only.

### Runtime matrix

| Runtime | Version | JVM | Allocation counter | Errors |
| --- | --- | --- | --- | ---: |
| Lucee | 6.2.8.20 | Eclipse Adoptium 21.0.12.1 | Available | 0 |
| Adobe ColdFusion | 2021.0.22+330451 | Eclipse Adoptium 11.0.32.1 | Unavailable | 0 |
| BoxLang | 1.17.0+58 | Eclipse Adoptium 21.0.12.1 | Available | 0 |

Adobe ColdFusion 2021 is the lowest Adobe version in Quick's current CI matrix.
The installed engine was patch 22 of that product line. BoxLang used its
Jakarta-compatible Runwar runtime; the same benchmark workload and logical
operation counts were preserved on all three engines.

## Cross-engine results

Wall time is microseconds per logical operation. Database values are per row.
Allocation is KiB per operation and is omitted where the runtime cannot expose
the JVM thread-allocation counter.

| Scenario | Lucee 6 wall | ACF 2021 wall | BoxLang wall | Lucee 6 alloc | BoxLang alloc |
| --- | ---: | ---: | ---: | ---: | ---: |
| Entity: instantiate wide | 374.87 us | 618.00 us | 491.08 us | 333.57 KiB | 580.85 KiB |
| Entity: instantiate narrow | 290.39 us | 499.41 us | 373.49 us | 283.58 KiB | 482.87 KiB |
| Entity: narrow shallow boundary | 262.43 us | 397.62 us | 369.21 us | 267.64 KiB | 426.76 KiB |
| Entity: hydrate | 397.47 us | 777.56 us | 672.93 us | 410.06 KiB | 1,026.16 KiB |
| Entity: hydrate batch of 100, per entity | 425.11 us | 759.41 us | 682.45 us | 409.95 KiB | 1,024.29 KiB |
| Attribute: read | 12.30 us | 34.51 us | 25.58 us | 9.82 KiB | 59.80 KiB |
| Attribute: assign | 8.31 us | 24.04 us | 17.83 us | 6.25 KiB | 43.51 KiB |
| Runtime overlay: deep lookup | 2.30 us | 6.15 us | 3.95 us | 2.06 KiB | 10.80 KiB |
| Entity: attribute snapshot | 572.10 us | 1,392.39 us | 1,188.05 us | 458.66 KiB | 2,666.04 KiB |
| Entity: clean dirty check | 594.77 us | 1,493.86 us | 1,358.23 us | 492.48 KiB | 3,054.52 KiB |
| Entity: memento | 161.77 us | 138.88 us | 571.12 us | 110.51 KiB | 622.53 KiB |
| Builder: instantiate | 697.41 us | 2,169.78 us | 1,788.74 us | 617.63 KiB | 2,174.84 KiB |
| Builder: clone | 896.43 us | 2,096.43 us | 1,878.99 us | 758.95 KiB | 2,563.98 KiB |
| Builder: compose common SQL | 1,142.86 us | 2,990.16 us | 3,175.00 us | 870.45 KiB | 3,773.27 KiB |
| Relationship: construct `hasMany` | 2,889.57 us | 4,262.20 us | 4,157.24 us | 1,600.35 KiB | 4,342.53 KiB |
| Metadata: CacheBox definition lookup | 2.14 us | 7.09 us | 4.75 us | 1.42 KiB | 11.34 KiB |
| Metadata: bound definition access | 0.53 us | 1.47 us | 1.30 us | 0.34 KiB | 3.63 KiB |
| Metadata: cached qualified columns | 8.10 us | 14.08 us | 17.88 us | 7.99 KiB | 35.70 KiB |
| Metadata: full cold path | 12,372.54 us | 21,095.13 us | 21,667.88 us | 4,204.91 KiB | 29,111.55 KiB |
| Database: raw result | 4.68 us | 4.75 us | 7.39 us | 1.79 KiB | 6.55 KiB |
| Database: hydrated result | 385.35 us | 611.97 us | 454.64 us | 295.20 KiB | 550.99 KiB |

### Metadata shape diagnostic

The same `User` mapping has 19 attributes, 19 columns, one cast, one declared
virtual attribute, and 16 normalized top-level metadata keys on every engine.
The retained raw engine metadata differs:

| Diagnostic | Lucee 6 | ACF 2021 | BoxLang |
| --- | ---: | ---: | ---: |
| Serialized metadata characters | 355,563 | 208,205 | 316,776 |
| Inherited metadata functions | 330 | 331 | 217 |
| Inherited metadata properties | 58 | 58 | 58 |
| Local metadata functions | 74 | 74 | 36 |
| Local metadata properties | 20 | 20 | 20 |

Serialized character length is a portable shape diagnostic, not a retained-byte
measurement. It nevertheless demonstrates that Quick keeps a large,
engine-specific reflection graph after it has already compiled the normalized
attributes, columns, casts, and relationship names it uses at runtime.

### Directional retained heap

| Live object | Lucee 6 | ACF 2021 | BoxLang |
| --- | ---: | ---: | ---: |
| Unloaded wide entity | 163,071 B | 62,693 B | 56,095 B |
| Normally initialized narrow entity | 134,362 B | 51,645 B | 49,636 B |
| Builder | 173,864 B | 89,736 B | 94,008 B |

These values must not be used to rank engines. Future proposals should compare
candidate and baseline on the same engine and confirm material retained-heap
movement with JFR, a heap dump, or another object-retention profiler.

## Architecture diagnosis

### 1. Cache lifetime and eviction do not match metadata semantics

`ModuleConfig.cfc` creates `quickMeta` with no timeout and `maxObjects=300`.
`BaseEntity.metadataInspection()` stores mapping definitions in it, but the same
cache also stores:

- the BaseEntity method-name index;
- discriminated-child definitions; and
- qualified-column arrays keyed by mapping, runtime attribute overlay, and
  table-name hashes.

Mapping definitions are authoritative process-lifetime data. Qualified columns
are bounded derived views of an entity definition and query/table overlay. They
should not compete for the same eviction budget. Applications using persistent
runtime attributes, tenant table names, aliases, or many mappings can create
more derived keys than the default capacity even though the number of entity
classes is stable.

The likely production symptom is tail latency, not a large change in the
median. The full cold path costs 12-22 ms in this representative model, but the
benchmark also clears shared entries and constructs the entity, so it is an
upper bound rather than the isolated cost of one definition eviction. Phase 0
must add selective-eviction and cache-clear controls before assigning an exact
production spike to eviction. If several mappings are reconstructed together,
the request also creates large temporary metadata graphs and garbage-collection
pressure.

### 2. The cached value is a reflection document, not a runtime definition

Metadata compilation first retains `getInheritedMetadata()` and
`getMetadata()`, then derives the smaller maps and arrays Quick needs. The raw
documents stay attached because a few runtime paths and the public `get_Meta()`
shape still read engine annotations such as datasource, grammar, discriminator,
and inheritance fields.

This couples Quick's hot representation to three different engines' reflection
formats. It also makes an apparently shared definition large and mutable. The
correct boundary is a compact, engine-neutral, immutable `EntityDefinition`,
with an optional compatibility view for callers that inspect legacy metadata.

### 3. Entity instances rebind and copy definition data

`metadataInspection()` binds the shared metadata and then copies or aliases its
table, names, attribute maps, column maps, cast maps, function-name array,
inheritance flags, and grammar into many instance variables. Declared virtual
attributes are copied into a new array for each entity before runtime overlay
attributes are added.

This field layout makes existing code convenient, but prevents a cheap state
carrier and encourages defensive collection copies. A row should ideally own
one immutable definition reference, one shared runtime-services reference, and
only its mutable entity state.

### 4. Hydration repeats decisions that belong to a definition and row shape

Hydration repeatedly resolves row keys against aliases, columns, virtual
attributes, casts, setters, discrimination, and runtime overlays. A correct
plan cannot be keyed by mapping name alone: result shape, overlay version,
child mapping, null behavior, custom casts, and custom setters are observable.

The first-pass hydration-plan experiment was correctly abandoned because the
current metadata has no stable definition/overlay version. A compact immutable
definition is the prerequisite that makes a bounded hydration plan safe.

### 5. Builders and relationships combine immutable configuration with mutable state

Every builder allocates a Quick component plus qb state even though grammar,
formatters, table definition, scopes, and many options are identical for a
mapping. Relationship methods then create related entities/builders and execute
arbitrary user CFML before applying keys and constraints. That flexibility is
part of Quick's API and prevents transparent caching of relationship objects.

The safe approach is to share immutable query seeds and introduce optional
declarative relationship descriptors. Existing arbitrary relationship methods
remain the fallback.

## Proposed architecture

### P0: harden the measurement and compatibility contracts

Keep the four audit scenarios added in this pass:

- `metadata.cache_lookup`;
- `metadata.definition_access`;
- `metadata.qualified_columns_cached`; and
- `metadata.cold_compile`.

Add tests that are intentionally absent from the microbenchmark:

1. Concurrently request one cold mapping from 32 threads and prove it compiles
   exactly once.
2. Fill the derived cache with more than 300 overlay/table variants and prove a
   warmed definition does not recompile.
3. Reinitialize and unload the module, then prove definitions and derived views
   are cleared.
4. Exercise a custom `metadataCache` name/provider to lock down the existing
   configuration contract.
5. Capture same-engine heap/JFR evidence for 10, 100, and 500 mapping
   definitions before changing their representation.
6. Split the full-cold scenario into selective definition eviction, cache-clear
   control, shared BaseEntity-index rebuild, and ordinary entity construction
   so the compile cost is attributable.

Expected improvement: none directly. This establishes the gates needed to make
and attribute the architectural changes safely.

### P1: introduce an `EntityDefinitionRegistry`

Create a Quick-owned singleton registry with single-flight compilation per
mapping. Its core definition map should be process-local and non-evicting until
module reinitialization/unload because the mapping set is bounded by application
code, not requests.

Separate three lifetimes:

1. authoritative mapping definitions;
2. bounded derived views owned by a definition; and
3. request/entity runtime overlays.

Initially, preserve the `metadataCache` setting through a compatibility adapter
and deprecation path rather than silently ignoring custom providers. A provider
may remain useful for legacy/raw metadata or precompiled manifests, but a
remote/distributed cache must not be required for hot definition reads.

Targets:

- 65-80% lower definition-lookup wall time;
- 70-90% lower definition-lookup allocation on Lucee and BoxLang;
- 0-3% lower total warmed request time in normal workloads; and
- prevent definition eviction and the cold-path work it triggers; the exact
  isolated tail reduction will be set by the Phase 0 split benchmark.

Confidence is high for the lookup target because bound access is already
73-79% faster than CacheBox access. End-to-end gain is deliberately small
because `newEntity()` already passes a shared definition to child instances.

### P1: partition and bound derived metadata

Move qualified columns, discriminations, and future hydration plans under the
owning definition. Use a small bounded LRU or explicit shape limit per mapping;
8-16 variants is a reasonable prototype value, not a final default. Keys must
include the immutable definition version, runtime-overlay version, table/alias,
and other behavior-affecting options.

When a limit is reached, evict only a derived view. Never evict the owning
definition. Add counters for definition compile, derived hit/miss/eviction, and
current shapes so application profiling can distinguish useful caching from
cardinality explosions.

Targets:

- no definition recompilation during a 10,000-variant churn test;
- bounded derived-cache memory per mapping;
- under 3% warmed throughput improvement in typical applications; and
- large tail-latency improvement for high-cardinality table/overlay users.

### P1: provide immutable internal views

Keep public methods that promise caller-owned arrays or structs defensive, but
add internal accessors for immutable definition-owned columns, keys, virtual
attributes, and relationship-name sets. `retrieveQualifiedColumns()` currently
allocates a new result array even after the cached calculation is found.

Targets for cached qualified-column access:

- 50-75% lower wall time;
- 60-85% lower allocation; and
- 1-5% lower builder/query setup cost where the view is repeatedly consumed.

### P2: compile a compact immutable `EntityDefinition`

Normalize engine metadata once into an explicitly versioned structure that
contains only runtime inputs:

- mapping, full name, entity name, table, key, and inheritance/discriminator;
- attribute-by-alias and attribute-by-column indexes;
- casts, virtual attributes, and non-persistent properties;
- a case-insensitive relationship/member-name set;
- datasource, grammar, soft-delete, read-only, and query defaults; and
- stable fingerprints for definition and derived-plan invalidation.

Do not retain the complete inherited and local engine reflection documents in
the hot definition. Preserve public `get_Meta()` behavior through a lazily
materialized compatibility sidecar during migration. The sidecar must return
the same keys and preserve current isolation semantics. A later major version
can expose the portable definition directly and deprecate engine-shaped raw
metadata.

Targets:

- 40-70% lower retained heap for warmed metadata definitions;
- 3-8% lower entity setup allocation from fewer aliases/copies; and
- stable behavior and definition fingerprints across all supported engines.

The retained target is an estimate based on the raw document size and must be
validated with heap histograms. Cold compilation allocation will not fall by the
same amount until reflection itself is avoided by the optional manifest phase.

### P2: split entity definition, state, and runtime services

Replace the large set of rebound definition variables with three explicit
references:

1. `EntityDefinition`: immutable mapping behavior;
2. `EntityState`: data, original state, relationships, cast cache, dirty state,
   and other per-row mutation; and
3. `EntityRuntime`: shared WireBox/query/interceptor/string services.

Allocate optional state containers on first use only when the public contract
permits it. This is different from the first pass's piecemeal lazy-container
experiments: the carrier supplies a single ownership boundary and removes
component-variable/map churn together.

Targets:

- 15-30% lower entity construction/hydration wall time;
- 20-40% lower thread allocation;
- 10-25% lower retained heap per live entity; and
- no mutable state shared between entity instances.

This phase is the prerequisite for reconsidering a safe component factory. It
must not reintroduce the state leaks that invalidated shallow duplication.

### P2: cache bounded hydration plans

Compile a plan from `(definition version, row shape, runtime overlay version,
child mapping, null mode)` to ordered write operations. A plan can pre-resolve:

- source column to attribute alias;
- ignored and virtual columns;
- cast and setter dispatch;
- discriminator selection; and
- original-state recording.

Custom casts and setters remain instance calls. Plan creation must fall back to
the existing path for an uncacheable dynamic overlay or shape. A per-definition
bound prevents arbitrary projections from causing unbounded growth.

Targets for full hydration:

- Lucee: 5-10% lower wall, 10-20% lower allocation;
- Adobe ColdFusion: 10-20% lower wall;
- BoxLang: 15-25% lower wall, 25-40% lower allocation; and
- no more than 5% regression on any supported engine/scenario.

These engine-specific targets reflect the measured map/array allocation cost,
but remain hypotheses until a definition-versioned prototype is benchmarked.

### P2: split immutable query seeds from builder state

Compile one `QuerySeed` per definition containing immutable table/grammar,
formatter registry, model defaults, global-scope descriptors, and normalized
options. A new builder allocates only qb's mutable query state plus overrides.
Cloning must retain the current deep isolation of mutable arrays, maps, joins,
unions, eager loads, and callbacks.

Targets:

- 20-35% lower builder construction wall time;
- 25-40% lower builder allocation; and
- 10-20% lower relationship construction time as a downstream effect.

### P3: add opt-in declarative `RelationshipDefinition` values

Quick cannot safely infer or cache arbitrary CFML relationship methods. Add an
annotation/DSL or generated descriptor for the common declarative cases while
retaining legacy method invocation as the fallback. A definition can share the
related mapping, relation type, local/foreign keys, and static options; each
call still owns its parent, query state, and dynamic constraints.

Store relationship names as a case-insensitive set instead of scanning the
function-name array. Do not treat every non-BaseEntity method as a relationship
when a descriptor is available.

Targets for descriptor-backed relationships:

- 20-40% lower relationship construction wall time;
- 20-45% lower allocation; and
- unchanged behavior for legacy relationship methods.

### P3: redesign dirty tracking around canonical state writes

The first pass proved that directly comparing `_data` and original values does
not preserve Quick's missing-key, null, partial-select, save, refresh, and custom
setter semantics. Instead, route canonical state mutations through one writer
that updates a dirty bitset or changed-name set after accessor synchronization.

`isDirty()` can then read the index while snapshots remain available for APIs
that explicitly request them. Reset, save, refresh, replication, custom setters,
and direct generated-accessor mutation all need contract tests.

Targets:

- 70-90% lower clean `isDirty()` wall time;
- 80-95% lower allocation per dirty check; and
- identical missing/null/partial-query semantics on all engines.

### P3: collaborate with mementifier on compiled projections

BoxLang's memento path is 571.12 us and 622.53 KiB per operation, far above the
same path on Lucee and Adobe. Much of this behavior belongs to the mementifier
dependency. Propose an immutable compiled projection/configuration API that
Quick can store on `EntityDefinition`, while retaining per-entity mutable public
memento configuration when applications customize it.

Target on BoxLang: 30-50% lower memento wall time and allocation, with no more
than 5% regression on Lucee or Adobe ColdFusion.

### P4: add optional precompiled entity manifests

Provide a build/startup task that emits engine-neutral definitions for known
entity mappings. At runtime, validate a source/configuration fingerprint and
use the manifest; otherwise fall back to reflection compilation. This must be
optional because applications can create mappings dynamically.

Targets for cold definition creation:

- 60-85% lower wall time;
- 70-90% lower allocation on engines that expose it; and
- deterministic invalidation when source or Quick's definition schema changes.

This primarily improves application startup, first-request latency, reinit, and
cache-recovery tails. Its target must be evaluated with the split compile
benchmark, not the current full-cold total, and it should not be sold as a
warmed per-row optimization.

### P4: reconsider a state-safe entity factory

Once entity definition, state, and runtime services have explicit ownership,
prototype/factory construction can avoid repeating safe component setup while
allocating fresh mutable state. Use a portable factory interface with an
engine-specific optimized implementation only when the engine can prove
isolation; otherwise use normal WireBox construction.

Targets:

- 30-50% lower construction/hydration wall time versus this audit's head;
- 35-55% lower thread allocation; and
- zero shared mutable query, relationship, cast, original-data, or runtime
  overlay state.

The target is supported by the first pass's fast but unsafe shallow-duplicate
prototype. No shallow duplication should ship before all isolation tests pass.

## Lightweight result boundary

Quick will keep `asQuery()` as the lightweight result path. It already returns
aliased row data without allocating full entities, lifecycle state,
relationships, dirty tracking, or mementifier configuration. This architecture
work will not add a second record or DTO result type.

Applying entity casts to `asQuery()` is explicitly deferred. Custom casts can
depend on an entity instance and user-defined caster behavior, so cast-aware raw
results need a separate API and contract rather than being coupled to the
entity-hydration redesign.

## Delivery sequence

### Phase 0: contracts and observability

- Merge the metadata benchmark scenarios and Adobe-compatible selector logic.
- Decompose full hydration into construction, existing-entity row binding,
  post-load lifecycle work, and 10/100/1,000-entity batch behavior.
- Split full-cache cold compilation from selective mapping eviction and trivial
  CacheBox mutation overhead.
- Add concurrent compile, cache churn, reinit, custom provider, and heap tests.
- Capture profiler baselines for 10, 100, and 500 mappings.

Exit gate: reproducible metrics and tests fail against the known shared-cache
eviction behavior.

### Phase 1: registry and cache separation

- Add `EntityDefinitionRegistry` behind existing entity construction.
- Partition derived views and add bounded cardinality/metrics.
- Add immutable internal collection views.

Exit gate: no recompile under churn, compile-once concurrency, clean reinit,
and no engine regression over 5%.

### Phase 2: portable definition and hydration/query plans

- Introduce `EntityDefinition` plus lazy legacy metadata compatibility view.
- Version definitions and overlays.
- Add bounded hydration plans and immutable query seeds.

Exit gate: public metadata/entity behavior is unchanged; at least one primary
engine meets the target and no supported engine regresses over 5%.

### Phase 3: state carrier and declarative extensions

- Move mutable row state into `EntityState`.
- Add descriptor-backed relationships with legacy fallback.
- Introduce canonical dirty-state tracking.
- Prototype mementifier compiled projections with the dependency owner.

Exit gate: isolation, lifecycle, null, partial selection, custom cast/setter,
inheritance, and relationship suites are green across engines.

### Phase 4: startup and factory ceiling

- Add optional entity manifests.
- Prototype the state-safe entity factory behind an opt-in feature flag.
- Run real-application load and heap tests before considering a default change.

Exit gate: measured construction/hydration gain of at least 20%, allocation
gain of at least 25%, no state leak, and no engine regression over 5%.

## Compatibility and acceptance gates

Every retained change must preserve:

- the public `get_Meta()` shape and non-mutation behavior;
- simple and structured custom `metadataCache` configuration;
- module reinit and unload clearing semantics;
- persistent runtime attributes, virtual attributes, table aliases, and query
  overrides;
- inheritance, discrimination, composite keys, and null support modes;
- custom casts, generated and custom setters, lifecycle events, and mementos;
- builder clone isolation and relationship method flexibility; and
- Lucee 5/6, Adobe ColdFusion 2021/2023/2025, BoxLang native, and BoxLang CFML
  compatibility behavior covered by Quick's CI matrix.

Performance acceptance for each candidate:

1. Use five warmed runs and compare the median of medians on the same engine,
   JVM, database, heap, and machine.
2. Require at least 10% wall improvement, or a smaller repeatable wall change
   corroborated by a material allocation reduction.
3. Reject a candidate that regresses any supported engine's affected scenario
   by more than 5% unless the product contract explicitly accepts the tradeoff.
4. Confirm retained-memory claims with a heap profiler.
5. Run the complete functional suite on every supported engine family before a
   production commit is accepted.

## Expected aggregate outcomes

Do not sum the phase targets; several improvements remove the same work.

| Architecture reached | Expected entity-heavy wall reduction | Expected allocation reduction | Main benefit |
| --- | ---: | ---: | --- |
| Registry and cache partition | 0-3% warmed median | 0-5% warmed allocation | Prevents definition eviction, removes associated cold tails, and bounds cache growth |
| Compact definition and immutable views | 3-10% in definition-heavy query setup | 10-25% in affected setup paths; 40-70% metadata retained heap | Smaller, portable metadata model |
| Hydration plan, query seed, relationship descriptors | 15-30% in entity-heavy workloads | 20-40% | Reuses mapping/shape decisions |
| State carrier and state-safe factory | 30-50% construction/hydration | 35-55% | Removes repeated component/state setup |

For an application request, multiply the relevant Quick-path improvement by
the fraction of request time and allocation actually attributable to Quick.
Database-bound requests will see a smaller wall-time percentage; large hydrated
result sets and serialization-heavy endpoints should see a larger allocation
and garbage-collection benefit.

## Recommendation

Start with `EntityDefinitionRegistry` and cache partitioning, not the factory.
It repairs a correctness-of-lifetime problem, removes cold-tail risk, and
creates the versioned immutable boundary required by every higher-value idea.
Then implement the compact definition and prove the lazy legacy metadata view.
Only after that should Quick retry hydration plans, query seeds, dirty-state
indexes, or state-safe construction.

The immediate measurable win will be modest in warmed medians, but it changes
the architecture from “engine reflection cached beside request variants” to
“portable immutable definitions with bounded derived plans.” That is the
foundation needed to pursue the credible 30-50% construction/hydration ceiling
without weakening Quick's public behavior.
