---
marp: true
theme: uncover
class: invert
paginate: true
style: |
  section { background: linear-gradient(180deg, #0a0a14 0%, #0d0d1a 100%); font-family: 'Segoe UI', 'Arial', sans-serif; padding: 50px 70px 40px 70px; color: #ffffff; text-align: left; overflow: hidden; }
  section.title { text-align: center; display: flex; flex-direction: column; justify-content: center; align-items: center; }
  section.title h1 { text-align: center; border-bottom: 4px solid; border-image: linear-gradient(90deg, #00a1e0, #b455b6) 1; padding-bottom: 16px; margin-bottom: 0; font-size: 1.8em; }
  h1 { color: #ffffff; font-size: 1.6em; font-weight: 700; text-align: left; border-bottom: 3px solid; border-image: linear-gradient(90deg, #00a1e0, #b455b6) 1; padding-bottom: 10px; margin-bottom: 20px; margin-top: 0; }
  p { font-size: 0.78em; line-height: 1.5; margin: 10px 0; }
  ul, ol { font-size: 0.78em; line-height: 1.5; margin: 8px 0; padding-left: 24px; }
  li { margin-bottom: 6px; }
  strong { color: #00a1e0; }
  code { font-size: 0.75em; background: rgba(255,255,255,0.1); padding: 2px 6px; border-radius: 3px; }
  pre { font-size: 0.6em; margin: 12px 0; background: rgba(0,0,0,0.3); padding: 15px; border-radius: 5px; }
  table { font-size: 0.68em; margin: 12px 0; border-collapse: collapse; width: 100%; }
  th { background: rgba(0,161,224,0.25); padding: 6px 10px; text-align: left; border-bottom: 2px solid #00a1e0; }
  td { padding: 6px 10px; border-bottom: 1px solid rgba(255,255,255,0.15); }
  img { max-width: 90%; max-height: 280px; border-radius: 6px; }
---

<!-- _class: title -->

# One workload, one service

**How many `dt.service.name` values does one Kubernetes workload produce?**

---

# The setup

Same app, two namespaces, one cluster, one OneAgent.

| Namespace | Detection |
|---|---|
| `orders-sdv1` | SDv1 (default, K8s-aware) |
| `orders-sdv2` | SDv2 (opted in per namespace) |

Identical pods, identical traffic. Any difference is a detection-model difference.

---

# What the two models produce

One Kubernetes workload →

| Detection | Distinct names | Distinct entities |
|---|---|---|
| **SDv1** | 4: `orders-demo - OrderController`, `orders-demo - InventoryController`, `OrderEventsListener`, `orders-demo` | **4 separate `dt.entity.service`** |
| **SDv2** | 1: `orders-sdv2 -- orders-demo` | **1 `UNIFIED` entity** |

SDv1 creates **separate service entities** for each controller class and the Kafka listener — four services for one workload, one pod, one process.

---

# The core shift

- SDv1: multiplies entities for things that don't really exist as separate workloads
- SDv2: one entity; metric families and dimensions measure different aspects of its health on the same workload
- Per-class detail doesn't disappear — moves onto `endpoint.name`, `messaging.destination.name` (next section)

---

# Why the fragmentation matters

- Each SDv1 fragment has its own health, baselines, and alerts — four services to monitor per workload
- Queries filtered by `dt.service.name` or by `dt.entity.service` see each fragment as a separate identity
- Dashboards, SLOs, and alerting rules inherit the split — maintained four times for one workload

---

# Detour: service naming rules are being deprecated

This is a **separate story** from the SDv1→SDv2 collapse above. Both happen to show up on the demo tenant, but they're independent.

- Dynatrace's `builtin:naming.services` rules are going away — the Services app is moving off them
- SDv1 services that relied on naming rules to mask ugly detected names (`:8080`, `/`) lose their friendly labels
- For customers staying on SDv1, that's a real regression

**Shipped 2026-Q1 as the bridge:** the detection layer prefixes every SDv1 fragment with `service.name` when it's set.

---

# What the prefix fix looks like

| Workload | `OTEL_SERVICE_NAME` | `dt.service.name` values |
|---|---|---|
| `orders-demo` | unset | `orders-demo - OrderController` + 2 siblings |
| `orders-demo-named` | `orders-api` | `orders-api (orders-demo - OrderController)` + 2 siblings |

- `service.name` is now a first-class metric dimension — `filter service.name == "orders-api"` cuts across all fragments with no entity lookup
- **Entity fragmentation is still there** — this fixes naming and queryability, not consolidation; that's what SDv2 does

Long-term replacement for naming rules: **pipeline-side naming in OpenPipeline** (Part 2's "What's coming"). The prefix fix is the bridge until that ships.

---

# The prefix has a UI gap today

- Lands in **metrics and spans today** — DQL, alerts, dashboards see the prefix
- `entity.name` in the Services app **does not yet** carry the prefix — list-view UI update is pending
- Under SDv2 the same `service.name` env var just becomes the outright name — no prefix because nothing to prefix

---

# See it live

**Demo: SDv2 demo** (`sdv2-demo.yaml`) — Questions 1-4

Core story (SDv2 collapse):
1. Count distinct `dt.service.name` per workload — SDv1 four, SDv2 one
2. Check `serviceType`: `WEB_REQUEST_SERVICE` vs `UNIFIED`
4. Split request throughput by `dt.service.name` — SDv1 many lines, SDv2 one

Detour (SDv1 naming-rules bridge):
3. Compare `orders-demo` and `orders-demo-named` — same fragmentation, prefixed on the named side
