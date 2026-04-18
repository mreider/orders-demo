# Module 2.3 — The `service.name` workaround for Classic services

*For any Classic-detected workload with an ugly name, explain what setting `service.name` on spans gets you today, what it doesn't, and when the remaining gaps close.*

## The question

You have a Classic-detected service named `:8080`, `OrderController`, or a Java class path. You can't query it cleanly by name, and the old naming-rules overlay is deprecated.

> *What can you do this month, without waiting for a Dynatrace release, to make it queryable and readable?*

## The claim

Set `service.name` as a resource attribute on that workload's spans. You get three immediate wins and one deferred:

| Benefit | Today? |
|---|---|
| `service.name` as a queryable metric dimension | Yes |
| Prefixed `dt.service.name` on metrics (`<service.name> (<detected>)`) | Yes — detection-layer fix shipped 2026-Q1 |
| `service.name` on traces / span analysis | Yes |
| Clean entity display name in the Services app | Pending UI update |

Classic's entity fragmentation does **not** go away. The workaround fixes *naming* and *queryability*, not entity consolidation. For one-entity-per-workload you still need Latest (SDv2) on the namespace.

## How to set `service.name`

- **OTel-native / OTel Java agent**: `OTEL_SERVICE_NAME=<name>` or `OTEL_RESOURCE_ATTRIBUTES=service.name=<name>`.
- **OneAgent**: respects OTel env vars on container-injected auto-instrumentation. Set them on the container.
- **Code-level**: configure the OTel SDK Resource with `service.name`. Overrides env vars.

## The lab

**[Module 2.3 Lab — The `service.name` workaround](./module-2-3-service-name-workaround.yaml)**

Four queries comparing two Classic workloads identical except for one env var (`orders-demo` vs `orders-demo-named`):

- `service.name` on spans — present on named, empty on baseline.
- `service.name` as metric dimension — queryable on named only.
- `dt.service.name` prefixed on named (`orders-api (orders-demo - OrderController)`), raw on baseline.
- Entity counts — still 4 on both. Fragmentation did not collapse.

## What you should see

- Set env var → span `service.name` populated within minutes.
- Metric dimension queryable.
- `dt.service.name` gets the prefix.
- Entity count unchanged.

## In the Dynatrace UI

- Named workload shows prefixed name in service list (`orders-api (...)`) once the UI update reaches your tenant.
- Split any tile by `service.name`: named workload has a value, unnamed one is empty.

## Customer recommendation

1. Pick a `service.name` per workload (business name, not ports/paths).
2. Set as `OTEL_SERVICE_NAME` on the container.
3. Re-deploy. Dimension appears within minutes.
4. Write DQL against the new dimension.
5. Wait for UI to read the prefixed name — the last remaining gap.

## Next

**[Module 2.4 — What's coming: pipeline-side naming.](./module-2-4-whats-coming-pipeline-naming.md)**
