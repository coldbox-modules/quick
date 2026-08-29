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
- Concurrent access compiles a definition once.
- Derived churn remains bounded without evicting its owning definition.
- Clearing CacheBox does not force definition recompilation.
