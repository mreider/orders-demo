# One workload, one service

A Kubernetes workload should produce **one service** — one identity for naming, alerting, and ownership. Under SDv2 that's what you get. Under SDv1, the same workload fragments into multiple `dt.service.name` values on a single underlying entity.

This section's core story is the SDv1 → SDv2 entity collapse. Toward the end there's a detour about a parallel (unrelated) change: Dynatrace service **naming rules** are being deprecated, and SDv1 detection has shipped a compensating `service.name`-based prefix fix to cover the gap. Two independent threads; the demo covers both because both show up on the same live tenant.

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

## Detour: service naming rules are being deprecated — here's the SDv1 bridge

This next bit is a separate story from the SDv2 collapse above. It's here because the demo tenant shows both at once.

**The problem** (parallel to, but independent of, SDv2): the Dynatrace Services app is moving off the classic `builtin:naming.services` rules. When the Services app switches fully to Smartscape 2.0, those overlay names disappear. SDv1 services that relied on naming rules to show readable names (instead of `:8080` or `/`) lose their friendly labels. For customers still on SDv1 and not yet migrating to SDv2, this is a real regression.

**The compensating fix** (shipped 2026-Q1 in the detection layer): if `service.name` is set as a resource attribute, SDv1 detection prefixes it on every detected name:

| Workload | `OTEL_SERVICE_NAME` | `dt.service.name` values |
|---|---|---|
| `orders-demo` | unset | `orders-demo - OrderController`, `orders-demo - InventoryController`, `OrderEventsListener` |
| `orders-demo-named` | `orders-api` | `orders-api (orders-demo - OrderController)`, `orders-api (orders-demo - InventoryController)`, `orders-api (OrderEventsListener)` |

The prefix makes every SDv1 fragment query-friendly under a single business name. `service.name` itself also lands as a first-class metric dimension — `filter service.name == "orders-api"` cuts across all fragments without an entity-table join.

**Entity fragmentation does NOT go away** — you still have four separate SDv1 service entities per workload. This fix is purely about naming and queryability, not consolidation. That's what SDv2 does (above).

**UI caveat for the prefix.** The detection layer writes the prefixed name to metrics and spans today. **The Services app does not yet render it** in `entity.name` — list views still show the unprefixed detected name for named SDv1 workloads. DQL queries, alerts, and dashboards that key off `dt.service.name` or `service.name` work now; list-view UI naming is pending a Services app update.

**Long-term replacement for naming rules** (covered in Part 2's "What's coming"): move the entity upsert from the detection layer into OpenPipeline, where tenant admins can write processing rules that set `dt.service.name` centrally from any span attribute. That's the actual replacement for `builtin:naming.services`; the SDv1 prefix is the bridge until it ships.

## How it interacts with SDv2

On the SDv2 side the story is simpler: `service.name`, when set, becomes the service's outright name instead of `<namespace> -- <workload>`. No prefix because there's nothing to prefix — SDv2's detected names are already clean, and there are no fragment siblings to reconcile.

## See it live

**[Demo: SDv2 demo](./sdv2-demo.yaml)** — Questions 1-4 cover this section:

Core story (SDv2 entity collapse):
1. Count distinct `dt.service.name` per workload (four on SDv1, one on SDv2).
2. Check `serviceType`: `WEB_REQUEST_SERVICE` vs `UNIFIED`.
4. Split request throughput by `dt.service.name` — SDv1 shows per-class lines; SDv2 shows one line.

Detour (SDv1 naming-rules bridge):
3. Compare `orders-demo` and `orders-demo-named` — same SDv1 fragmentation, prefixed with `orders-api` on the named side.
