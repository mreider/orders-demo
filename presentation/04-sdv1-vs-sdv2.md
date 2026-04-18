# SDv1 vs SDv2, side by side

The same application, deployed twice, one namespace per detection model. Same pods, same OneAgent, same traffic. What actually changes?

## The setup

The `orders-demo` application (two REST controllers, a Kafka consumer, a JDBC client) runs in two namespaces on the same cluster under the same OneAgent:

| Namespace | Detection |
|---|---|
| `orders-sdv1` | SDv1 (default, K8s-aware) |
| `orders-sdv2` | SDv2 (opted in per namespace) |

Identical pods. Any difference is a detection-model difference.

## Three structural differences

1. **`dt.service.name` fragmentation count.** SDv1 produces roughly seven values for this workload: one per controller class, one for the Kafka listener, one aggregate, plus the prefixed forms if `service.name` is set. SDv2 produces one, typically `<namespace> -- <workload>`.
2. **Underlying entity type.** SDv1 backs the fragmented names with one `WEB_REQUEST_SERVICE` per workload (K8s-aware consolidation). SDv2 backs the single name with one `UNIFIED` entity. Both are 1-entity-per-workload. Only the fragmentation *above* the entity differs.
3. **Query shape.** To ask "throughput of this workload" under SDv1, you either group by `dt.service.name` (one row per fragment) or by `dt.entity.service` with a lookup (one row, loses the per-class view). Under SDv2, filter on `dt.service.name`: one value, one row, no lookup.

Activity is identical on both sides. Both namespaces emit the same spans with the same `endpoint.name`, `db.system`, `messaging.destination.name` dimensions. Only the modelling on top differs.

### Historical note: the fake DATABASE_SERVICE

Coming from **Classic Dynatrace** (pre-Latest)? You may remember separate `DATABASE_SERVICE`, `MESSAGING_SERVICE`, and `EXTERNAL_SERVICE` entities for each downstream your service talked to: a separate "Postgres" service entity, a separate "Kafka listener" entity, etc.

On modern Latest Dynatrace tenants those entities are gone. SDv1 itself already adopted the caller-side dimensional model: database identity lives on the JDBC client span as `db.system` / `db.namespace` / `server.address`, owned by the calling service. SDv2 inherits that and goes further by collapsing the per-controller `dt.service.name` fragmentation within each workload.

## See it live

**[Demo: SDv1 vs SDv2 side by side](./04-sdv1-vs-sdv2.yaml)**

Four queries, most running twice (once per namespace):

- Count distinct `dt.service.name` values per namespace.
- Enumerate those values, see where SDv1 fragmentation lives.
- Activity totals, proving the underlying spans are identical.
- Same workload-level question, two DQL shapes.

Expected shape:

- `orders-sdv1`: 4-7 distinct `dt.service.name` values.
- `orders-sdv2`: 1 value.
- Throughput lines track each other.
- SDv1 group-by-name yields many series; SDv2 filter yields one.

## What it looks like in the UI

- Filter by `k8s.namespace.name = orders-sdv1`. Multiple rows show up, named like `orders-demo - OrderController`, `OrderEventsListener`, and `orders-demo`. All point at the same underlying `WEB_REQUEST_SERVICE` entity. That's the `dt.service.name` fragmentation surfaced as separate list entries.
- Filter by `k8s.namespace.name = orders-sdv2`: one row, `serviceType = UNIFIED`.
- Open the UNIFIED row: **Message Processing** and **DB Queries** appear as tabs on the single service, not as separate Services list rows.
