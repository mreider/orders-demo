# Dimensions do the slicing

Under SDv2 a service has one identity. The per-endpoint, per-queue, per-database detail you used to navigate by clicking between entities now lives on **metric dimensions** of the one entity. Same questions, fewer joins.

## Three metric families per service

Every service's activity is measured under exactly one of three metric families. Knowing which one tells you where to look and how to split the view.

| Family | Counts | Key dimensions |
|---|---|---|
| `dt.service.request.*` | HTTP / gRPC / RMI entry points | `endpoint.name`, `http.route`, `http.response.status_code` |
| `dt.service.messaging.process.*` | Message consumption (Kafka, SQS, Pub/Sub) | `messaging.destination.name`, `messaging.system`, `messaging.operation` |
| `dt.service.faas_invoke.*` | Serverless function invocations | `faas.trigger` |

The Services app's **Transactions** column is the coalesced sum across all three. On the `orders-demo` SDv2 workload, `request` sees the k6 HTTP traffic and `messaging.process` sees the Kafka consume on `order-events` — all under one `dt.service.name`.

### One legacy overlap worth knowing

Kafka consume activity currently **double-counts**: it shows up in both `dt.service.request.*` and `dt.service.messaging.process.*`. On the SDv1 fragment `OrderEventsListener`, `dt.service.request.count` reports ~240/min with `endpoint.name = NON_KEY_REQUESTS` — a Classic artifact from before dedicated messaging families existed. Same numbers under `dt.service.messaging.process.count` for the same destination.

Don't build alerts on the sum of families until this lands. The overlap goes away when **SDv2 for OneAgent GAs in June 2026** — `dt.service.request.*` will be HTTP-only and messaging activity will live exclusively under `dt.service.messaging.process.*`.

## Downstreams are tabs, not entities

Databases, queues, and third-party HTTP don't get their own Services rows. They surface as tabs on the **caller**:

| Tab | Metric family | Dimensions |
|---|---|---|
| **DB Queries** | `dt.service.database.query.*` | `db.system.name`, `db.operation.name`, `server.address` |
| **Message Processing** | `dt.service.messaging.process.*` (consume + publish) | `messaging.destination.name`, `messaging.system` |
| **Outbound Calls** | `dt.service.thirdparty.*` + client spans | host, endpoint, status |

Database identity lives on the JDBC client span owned by the calling service. The tab UI is a curated view of those dimensions. This applies on both SDv1 and SDv2 — it's a Latest-app feature, not an SDv2-only feature.

If you're coming from Classic, the separate `DATABASE_SERVICE` / `MESSAGING_SERVICE` / `EXTERNAL_SERVICE` entities are gone. *"Where are my queue listeners?"* is now a Message Processing tab on the caller. Relocation, not removal.

## `endpoint.name` and the `GET /*` reality

`endpoint.name` is how the Services app talks about individual HTTP routes. It derives from `http.route` on server spans. If `http.route` isn't set, the endpoint falls back to `<METHOD> /*` — which is exactly what `orders-demo` shows today, on both SDv1 and SDv2, because the underlying Spring MVC spans don't emit `http.route`.

Throughput and latency are still right. The endpoint *labels* are wrong. That's a missing attribute, not a broken pipeline.

**Two fixes work today:** URL path-pattern matching (Settings → Service detection, works on SDv1 and SDv2) and Request Naming Rules (Classic only, deprecated).

**Automatic URL normalization is coming.** When `http.route` is missing, Dynatrace will derive a stable route by truncating paths at the first volatile segment (IDs, hashes, UUIDs, uppercase tokens). The derived value is written back to `http.route` with a marker distinguishing framework-provided from heuristic-derived. Classic-services rollout first (feature-flagged per tenant); SDv2 gets an opt-in checkbox, default-on after field validation. Existing URL-pattern rules and metric extractions continue working unchanged.

## Metric-first DQL

With `dt.service.name`, `service.name`, and `k8s.namespace.name` indexed as first-class metric dimensions, you can filter and split on the timeseries without fetching the entity table.

```
// Classic shape
fetch dt.entity.service
| filter entity.name == "orders-sdv2 -- orders-demo"
| lookup [timeseries count = sum(dt.service.request.count), by: {dt.entity.service}],
    sourceField: id, lookupField: dt.entity.service

// Latest shape
timeseries count = sum(dt.service.request.count),
  filter: dt.service.name == "orders-sdv2 -- orders-demo"
```

Shorter, cheaper, and stable across entity re-detection — dimension values don't change when entities do.

## What's coming

*Direction is firm; timing is not. Treat as road shape, not arrival date.*

- **Automatic URL normalization** (above) closes the `GET /*` gap.
- **Pipeline-side naming in OpenPipeline.** A tenant admin writes a processing rule that sets `dt.service.name` on incoming spans before entity and metric extraction — same central-control UX as Classic naming rules, but operating on resource attributes with pipeline composability. No per-workload env-var edits at scale.
- **`SERVICE_DEPLOYMENT`** is a planned entity type orthogonal to SERVICE, carrying deployment context (namespace, cluster, environment, version, release stage). One SERVICE, many SERVICE_DEPLOYMENTs linked by `dt.service.id`. Lets you answer *"staging error rate, independent of prod"* without splitting identity. Maps directly onto Datadog's `service` + `env` + `version` pattern.
- **Primary Fields as metric dimensions.** `k8s.cluster.name`, `k8s.namespace.name`, and configurable tags become first-class on the service metric families, so you can filter and split without a `lookup`.
- **Services app rewire to timeseries-first.** List and detail pages move from entity-list-plus-chart to query-led: pick metric families, split by dimensions, filter on tags.

## What to do today

- Set `service.name` on workloads you own — both as `OTEL_SERVICE_NAME` and as an `OTEL_RESOURCE_ATTRIBUTES` entry.
- Write DQL metric-first; skip the entity table unless you need ownership or tags.
- Don't invest new effort in Services Classic naming rules or in splitting rules for per-env views — both being superseded.
- Pick names that survive the SDv2 move and the pipeline-naming move. Good `service.name` values are durable; detection-rule workarounds aren't.

## See it live

**[Demo: SDv2 demo](./sdv2-demo.yaml)** — Questions 5-10 cover this section: three families side-by-side, the legacy `request.*`/messaging overlap, split by `endpoint.name`, messaging + DB as dimensions on the caller, metric-first vs entity-first DQL on the same question.
