# Module 1.4 — Classic vs Latest, side by side

*The same application, deployed twice, one namespace per detection model. Identify exactly what changed in the entity graph, the naming, and the query shape.*

## The setup

The `orders-demo` application (two REST controllers, a Kafka consumer, a JDBC client) runs in two namespaces on the same cluster under the same OneAgent:

| Namespace | Detection |
|---|---|
| `orders-sdv1` | Classic |
| `orders-sdv2` | Latest (SDv2 opt-in) |

Identical pods. Any difference is a detection-model difference.

## The question

> *Same app, same traffic, two models. What differs in the entity graph, and how does DQL shape shift?*

## The claim

Four structural differences:

1. **Entity count.** Classic produces one `WEB_REQUEST_SERVICE` + per-controller `WEB_SERVICE` + `MESSAGING_SERVICE` + sometimes a `DATABASE_SERVICE`. Latest produces one `UNIFIED` entity.
2. **Fake entities.** Classic's `DATABASE_SERVICE` is often the JDBC client dressed up as a service — nothing external is being monitored. Latest removes it.
3. **Activity is identical.** Both namespaces emit the same spans with the same transport dimensions. Totals match.
4. **Query shape.** Classic needs `lookup dt.entity.service` + filter on `serviceType`. Latest filters on `dt.service.name` directly — no lookup.

## The lab

**[Module 1.4 Lab — Classic vs Latest side by side](./module-1-4-classic-vs-latest.yaml)**

Four queries, most running twice (once per namespace):

- Entity count per namespace.
- Enumerate entity names and types — spot the fake `DATABASE_SERVICE`.
- Activity totals — prove spans are identical.
- Same workload-level question, two query shapes.

## What you should see

- `orders-sdv1`: 4–5 entities.
- `orders-sdv2`: 1 entity.
- Throughput lines track each other.
- Classic query: 6+ lines with `lookup` and `serviceType` filter. Latest: 2 lines with `dt.service.name` filter.

## In the Dynatrace UI

- Filter Services app by `k8s.namespace.name = orders-sdv1` → column of Classic entities including a fake `DATABASE_SERVICE`.
- Filter by `k8s.namespace.name = orders-sdv2` → one row, `UNIFIED`.
- Open the UNIFIED entity → **Message Processing** and **DB Queries** appear as tabs, not separate entities (Module 3.3).

## Next

**[Unit 2, Module 2.1 — Where names come from.](../unit-2-naming-identity/module-2-1-where-names-come-from.md)**
