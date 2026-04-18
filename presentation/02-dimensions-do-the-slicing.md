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

Don't build alerts on the sum of families until this lands. The overlap goes away in a future SDv2-for-OneAgent release — `dt.service.request.*` will be HTTP-only and messaging activity will live exclusively under `dt.service.messaging.process.*`.

## Downstreams are tabs on the caller — but the destination is the real entity

On both SDv1 and SDv2, the calling service is the anchor. Databases, queues, and third-party HTTP surface as tabs on the caller:

| Tab | Metric family (target state) | Dimensions |
|---|---|---|
| **DB Queries** | `dt.service.database.*` | `db.system`, `db.operation.name`, `server.address` |
| **Message Processing** | `dt.service.messaging.process.*` | `messaging.destination.name`, `messaging.system` |
| **Outbound Calls** | `dt.service.thirdparty.*` + client spans | host, endpoint, status |

What changes under SDv2 is what the numbers **measure**.

**SDv1 measures the client-side call and labels it the database.** The "database service" in a Classic path is the calling app's JDBC span — its latency is the round-trip as seen *from the caller*. Alerts and baselines fire on the client's view of the DB, not on the DB itself. For a multi-tenant Postgres instance, every caller gets a different DATABASE_SERVICE entity with different latency, and none of them reflect what's happening inside Postgres.

**SDv2 targets the real DB entity as the owner of the measurement.** A Postgres extension running on an ActiveGate produces a real `dt.entity.postgresql_instance` with connection count, WAL, replication lag, and query rate sampled at the database. When the span-to-entity linking for databases ships in a future SDv2-for-OneAgent release, the `dt.service.database.*` metric written on the calling service will also link to that real DB entity — so query latency, error rate, and alert ownership roll up to the database itself, not to whichever caller happened to notice slowness first.

Same shape for messaging: the real broker (Kafka cluster, SQS queue) is the destination, and message processing metrics should eventually point at it rather than live as a dimension on whichever consumer noticed the lag. The messaging side of that linking is less mature than the DB side today — the broker-as-owner story for messaging is further out.

If you're coming from Classic, the separate `DATABASE_SERVICE` / `MESSAGING_SERVICE` / `EXTERNAL_SERVICE` entities are gone as client-side constructs. Their replacement isn't another client-side surrogate — it's the actual infrastructure entity produced by an extension, with the calling service's metric pointing to it.

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
- **`dt.service.database.*` metric family, linked to the real DB entity.** A telemetry-based topology pipeline that matches database client spans to the real DB entity produced by a DB extension, then writes a service-level DB metric split by the usual service dimensions. Landing in a future SDv2-for-OneAgent release. The client spans are already shaped correctly today (`db.system="postgresql"`, `server.address=postgres`, `db.operation.name`) — nothing to change on the instrumentation side.
- **Messaging-to-broker linking** follows a similar vision but is less mature. Today's `dt.service.messaging.process.*` lives on the consuming service dimensioned by destination; the broker-as-owner destination is further out.

## What to do today

- Set `service.name` on workloads you own — both as `OTEL_SERVICE_NAME` and as an `OTEL_RESOURCE_ATTRIBUTES` entry.
- Write DQL metric-first; skip the entity table unless you need ownership or tags.
- Don't invest new effort in Services Classic naming rules or in splitting rules for per-env views — both being superseded.
- Pick names that survive the SDv2 move and the pipeline-naming move. Good `service.name` values are durable; detection-rule workarounds aren't.

## See it live

**[Demo: SDv2 demo](./sdv2-demo.yaml)** — Questions 5-10 cover this section: three families side-by-side, the legacy `request.*`/messaging overlap, split by `endpoint.name`, messaging + DB as dimensions on the caller, metric-first vs entity-first DQL on the same question.
