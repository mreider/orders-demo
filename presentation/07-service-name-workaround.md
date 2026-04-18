# The `service.name` workaround for Classic services

You have SDv1-detected services named `:8080` or `OrderController`. You can fix naming and queryability today, without waiting for a Dynatrace release.

## Set `service.name` on spans. Name and query problems go away.

For any SDv1-detected workload with an ugly name, set `service.name` as a resource attribute on that workload's spans. You get three immediate wins and one deferred:

| Benefit | Today? |
|---|---|
| `service.name` as a queryable metric dimension | Yes |
| Prefixed `dt.service.name` on metrics (`<service.name> (<detected>)`) | Yes, detection-layer fix shipped 2026-Q1 |
| `service.name` on traces and span analysis | Yes |
| Clean entity display name in the Services app | Pending UI update |

Classic's entity fragmentation does **not** go away. The workaround fixes *naming* and *queryability*, not entity consolidation. For one-entity-per-workload you still need Latest (SDv2) on the namespace.

## How to set `service.name`

- **OTel-native or OTel Java agent**: `OTEL_SERVICE_NAME=<name>`, or `OTEL_RESOURCE_ATTRIBUTES=service.name=<name>`.
- **OneAgent**: respects OTel env vars on container-injected auto-instrumentation. Set them on the container.
- **Code-level**: configure the OTel SDK Resource with `service.name`. Overrides env vars.

## The prefix in action

- Baseline: `dt.service.name = orders-demo - OrderController`
- Named: `dt.service.name = orders-api (orders-demo - OrderController)`

The prefix makes the fragments legible as parts of one logical service. SDv1 detection still fragments. The fix just makes the fragments query-friendly.

## See it live

**[Demo: The service.name workaround](./07-service-name-workaround.yaml)**

Two Classic workloads, identical except for one env var (`orders-demo` vs `orders-demo-named`). Four queries show what changes:

- `service.name` on spans: present on named, empty on baseline.
- `service.name` as metric dimension: queryable on named only.
- `dt.service.name` prefixed on named, raw on baseline.
- `dt.service.name` fragmentation: still multiple values on both. The workaround fixes naming and queryability, not fragmentation.

## What it looks like in the UI

- The named workload shows the prefixed name in the service list (`orders-api (...)`) once the UI update reaches your tenant.
- Split any tile by `service.name`: the named workload has a value, the unnamed one is empty. That is the query-ergonomics difference, made visible.

## The customer recommendation

1. Pick a `service.name` per workload. Business name, not ports or paths.
2. Set it as `OTEL_SERVICE_NAME` on the container.
3. Re-deploy. The dimension appears within minutes.
4. Write DQL against the new dimension (metric-first patterns).
5. Wait for the UI to read the prefixed name. That is the last remaining gap.
