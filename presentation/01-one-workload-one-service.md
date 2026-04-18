# One workload, one service

A Kubernetes workload should produce **one service** — one identity for naming, alerting, and ownership. Under SDv2 that's what you get. Under SDv1, the same workload fragments into multiple `dt.service.name` values on a single underlying entity.

## The setup

The `orders-demo` application (two REST controllers, a Kafka consumer, a JDBC client) runs in two namespaces on the same cluster under the same OneAgent:

| Namespace | Detection |
|---|---|
| `orders-sdv1` | SDv1 (default, K8s-aware) |
| `orders-sdv2` | SDv2 (opted in per namespace) |

Same image, same replicas, same traffic. Any difference is a detection-model difference.

## What the two models produce

One Kubernetes workload. Enumerate `dt.service.name` and `dt.entity.service` over a representative window:

| Detection | Workload | Distinct `dt.service.name` values | Distinct `dt.entity.service` entities |
|---|---|---|---|
| SDv1 | `orders-demo` | `orders-demo - OrderController`, `orders-demo - InventoryController`, `OrderEventsListener`, `orders-demo` (actuator) | **4** |
| SDv2 | `orders-demo` | `orders-sdv2 -- orders-demo` | **1** (`serviceType = UNIFIED`) |

**SDv1 creates four separate service entities for one workload** — one per REST controller class, one for the Kafka listener, and the actuator handler. Each fragment is its own `dt.entity.service` with its own ID, its own health, its own baselines, its own alerts. They're modeled as four services, even though they all run in the same pod, share the same process, and route through the same OneAgent.

SDv2 collapses all of that to **one `UNIFIED` entity** with one name. The per-class detail isn't gone — it moves onto first-class metric dimensions like `endpoint.name` and `messaging.destination.name`, queried from the single entity (covered in the next section).

This is the core shift: SDv1 multiplies entities for things that don't really exist as separate workloads. SDv2 keeps one entity and uses metric families and dimensions to measure different aspects of its health on the same workload.

## The `service.name` knob works on both

Set `OTEL_SERVICE_NAME` on the container and a 2026-Q1 detection-layer fix applies the value as a **prefix** on every `dt.service.name` that SDv1 emits for that workload:

| Workload | `OTEL_SERVICE_NAME` set? | `dt.service.name` values |
|---|---|---|
| `orders-demo` | no | `orders-demo - OrderController`, `orders-demo - InventoryController`, `OrderEventsListener` |
| `orders-demo-named` | `orders-api` | `orders-api (orders-demo - OrderController)`, `orders-api (orders-demo - InventoryController)`, `orders-api (OrderEventsListener)` |

The prefix makes every fragment query-friendly under a single business name. `service.name` itself also lands as a first-class metric dimension — `filter service.name == "orders-api"` cuts across all four SDv1 entities without an entity-table join.

**Entity fragmentation does not go away** — you still have four separate service entities on SDv1. But the *naming* and *queryability* problems are solved, and the four entities now collapse to one business identity in queries without waiting for a namespace to migrate to SDv2.

Under SDv2 the same env var takes the direct path: `service.name` replaces the default `<namespace> -- <workload>` name outright. No prefix, no fragmentation to prefix.

## The UI caveat

The detection-layer prefix lands in metrics and spans today. **It does not yet appear in `entity.name`** — the Services app still shows the unprefixed detected name for named SDv1 workloads. Metric-first queries, alerts, and dashboards work now; list-view UI naming is pending a Services app update.

## See it live

**[Demo: SDv2 demo](./sdv2-demo.yaml)** — Questions 1-4 cover this section:

1. Count distinct `dt.service.name` per workload (three on SDv1, one on SDv2).
2. Check `serviceType`: `WEB_REQUEST_SERVICE` vs `UNIFIED`.
3. Compare `orders-demo` and `orders-demo-named` — same fragmentation pattern, prefixed on the named side.
4. Split request throughput by `dt.service.name` — SDv1 shows per-class lines; SDv2 shows one line.
