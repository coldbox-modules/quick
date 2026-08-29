# Performance architecture execution results

This document records the disposition of each candidate from
`performance-architecture-plan.md`. Production changes are retained only after
cross-engine functional verification and repeatable benchmark improvement.

## Phase 1: registry and cache separation

Status: accepted.

Quick entity definitions now live in a process-local, non-evicting
`EntityDefinitionRegistry`. Qualified-column and discrimination views use
separate bounded buckets, so request-shaped variants cannot evict authoritative
mapping definitions. Compilation is single-flight and the registry is cleared
with the module lifecycle.

The configured CacheBox cache is still created and cleared for configuration
compatibility, but it is no longer the authoritative entity-definition store.
This deliberately avoids treating a remote cache as a safe cross-deployment
definition cache; entity source and configuration changes have no portable
version contract yet.

Median of seven warmed runs for the affected operations:

| Runtime | Registry lookup vs CacheBox wall | Registry lookup allocation | Cached qualified columns wall | Cached qualified columns allocation |
| --- | ---: | ---: | ---: | ---: |
| Lucee 6 | -51.6% | -52.2% | -4.9% | -1.1% |
| Adobe ColdFusion 2021 | -53.8% | unavailable | -22.5% | unavailable |
| BoxLang | -61.6% | -56.5% | -5.9% | -3.8% |

An initial implementation passed the registry through every `init()` call. It
was abandoned after the performance gate measured hydration regressions of
46.5% on Adobe ColdFusion and 28.4% on BoxLang. The accepted implementation
resolves the registry lazily only for definition and derived-view work. A second
derived-view prototype allocated a closure on every cache hit; it was also
abandoned after Adobe's qualified-column benchmark regressed by 16.5%. The
accepted lookup-first implementation produced the improvements above.

Functional gate:

- Lucee 6: 621 passed, 0 failed, 0 errors.
- Adobe ColdFusion 2021: 620 passed, 0 failed, 0 errors.
- BoxLang: 622 passed, 0 failed, 0 errors.

### Bounded row-shape hydration plans

Status: abandoned.

A prototype cached ordered `[source, alias, column]` operations by mapping and
row shape. It improved existing-entity binding by 14.0-26.7%, but a fresh
entity had to resolve the registry through WireBox before using the plan.
BoxLang full hydration regressed 10.3% for one entity and 10.1% for a batch of
100, with about 2% more allocation. The prototype was reverted.

Revisit this only after entities receive a cheap definition-owned plan reference
without adding constructor arguments. Passing registry state through every
`init()` was already rejected in Phase 1 for larger cross-engine regressions.

### Immutable query seed

Status: abandoned.

A safe first slice let `BaseEntity.newQuery()` consume the shared qualified
column array directly while preserving the public defensive-copy behavior.
Builder construction changed between +1.0% and -3.2%, with less than 1% lower
allocation. Relationship construction regressed 5.5% on BoxLang, so the slice
did not meet the gate and was reverted.

The remaining seed inputs belong largely to qb's mutable `QueryBuilder` state.
Sharing them from Quick without a qb-supported immutable seed/snapshot boundary
would risk clone and query-state isolation for little demonstrated gain.

## Phase 3: state and declarative extensions

### Explicit `EntityState` carrier

Status: abandoned for this compatibility line.

The current mutable fields are observable through generated accessors and are
used across reset, clone, replication, save, relationship, cast, and query
flows. Wrapping the same maps in another struct would add indirection without
removing component allocation. The earlier isolated lazy-container prototype
confirmed this: wide construction regressed 2.6% and allocation was unchanged.
A useful carrier must land together with a compact definition and a prepared
factory in a major internal rewrite; the compact-definition prerequisite was
not met in this pass.

### Declarative relationship definitions

Status: abandoned as a transparent optimization.

Existing relationship methods are arbitrary user CFML: they accept arguments,
run conditional code, return custom subclasses, and mutate constraints. Quick
cannot replace that invocation with a descriptor without introducing a new
opt-in public DSL and maintaining the method path as fallback. That can be a
separate feature proposal, but it is not a behavior-preserving performance
change for this branch.

### Indexed dirty tracking

Status: abandoned.

The earlier direct-state prototype failed ten functional tests covering
partial selections, nulls, excluded attributes, saves, and refreshes. Current
hash comparison preserves missing-key state that a simple changed-name set
does not. The accepted single-pass assignment work already improves clean dirty
checks; a replacement still requires a canonical write model across generated
and custom setters before it can be timed safely.

### Compiled memento projections

Status: abandoned pending a mementifier API.

Mementifier owns its mutable public configuration and date formatters. Removing
eager setup improved wide construction only 3.1% and narrow construction 0.3%,
then broke `getMemento()`. Sharing the mutable configuration would leak changes
between entities. Quick should revisit this only if mementifier exposes an
immutable compiled projection/configuration boundary.

## Phase 4: startup and construction ceiling

### Precompiled entity manifests

Status: abandoned until a portable definition contract exists.

A manifest can safely contain only the normalized definition. The current
public metadata contract also exposes engine-specific inherited/local
reflection graphs, and Phase 2 could not remove them. Emitting those graphs
would make a manifest engine-specific and stale across engine or source
changes; omitting them would change `get_Meta()` and lifecycle payloads. A
manifest tool therefore has no safe value until the compact-definition/public
metadata boundary is versioned.

### State-safe prepared entity factory

Status: abandoned.

The earlier shallow-prototype measurement demonstrated the performance ceiling
but also shared relationship-constraint, cast-cache, and query-option state
between entities. The new registry fixes definition lifetime, not mutable
component ownership. Because the explicit state carrier was not accepted, the
factory still cannot prove isolation and no unsafe factory code is retained.

## Lightweight result boundary

`asQuery()` remains Quick's lightweight fallback and continues applying column
aliases without allocating entities. No DTO/record result type was added.
Applying casts to `asQuery()` remains intentionally deferred because custom
casts can require an entity instance and need a separate public contract.
- Concurrent access compiles a definition once.
- Derived churn remains bounded without evicting its owning definition.
- Clearing CacheBox does not force definition recompilation.

## Phase 2: metadata representation and hydration

### Compact metadata definition

Status: abandoned for this compatibility line.

Quick's public `get_Meta()` contract exposes the raw inherited and local engine
metadata graphs. The same value is included in the public `preLoad` lifecycle
event. Discarding those graphs would either change observable behavior or force
reflection and compatibility reconstruction during ordinary queries, trading
retained memory for unpredictable hot-path latency. A portable compact
definition should therefore be introduced with an explicit public metadata
contract in a future major version, not hidden behind the current accessor.

### Single-pass row binding

Status: accepted.

Row binding previously resolved every source key through `hasAttribute()`,
then repeated alias and column resolution while casting and assigning it. The
accepted path resolves the attribute definition once and reuses its canonical
name and column.

Median of five warmed runs:

| Runtime | Existing-entity bind wall | Existing-entity bind allocation | Single hydrate wall | Batch 10 wall | Batch 100 wall | Batch 1,000 wall |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Lucee 6 | -52.4% | -51.9% | -19.7% | -24.6% | -0.5% | -20.6% |
| Adobe ColdFusion 2021 | -39.1% | unavailable | +4.0% | -8.3% | -2.1% | -20.9% |
| BoxLang | -43.6% | -40.6% | -32.5% | -32.7% | -19.9% | -11.8% |

Lucee hydration allocation fell 9.0% at every measured batch size. BoxLang
hydration allocation fell 16.9%. Adobe's one-entity wall result is within the
5% regression gate and changes to an improvement as soon as the path handles a
batch; its 1,000-row result improves 20.9%.

Functional gate:

- Lucee 6: 621 passed, 0 failed, 0 errors.
- Adobe ColdFusion 2021: 620 passed, 0 failed, 0 errors.
- BoxLang: 622 passed, 0 failed, 0 errors.
