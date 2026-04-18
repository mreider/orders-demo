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

# The point

One Kubernetes workload should produce one service name. That's true under SDv2. Under SDv1, the same workload fragments into many names.

- **SDv2**: one `dt.service.name` per workload, backed by a `UNIFIED` entity
- **SDv1**: 4-7 `dt.service.name` values per workload, all backed by one `WEB_REQUEST_SERVICE` entity
- Same spans, same traffic. Only the name layer differs.

---

# Where the SDv1 fragmentation comes from

A Spring Boot app with two REST controllers plus a Kafka consumer emits names like:

- `<workload>` (aggregate)
- `<workload> - OrderController` (per controller class)
- `<workload> - InventoryController` (per controller class)
- `OrderEventsListener` (the Kafka consumer)

All pointing at one `dt.entity.service`. The entity graph consolidated long ago. The `dt.service.name` layer did not.

---

# Why the fragmentation matters

- Queries filtered by `dt.service.name` see each fragment as a separate identity
- Health and alerts scoped to a name end up per-class, not per-workload
- Dashboards and SLOs inherit the split

SDv2 pushes per-class granularity onto first-class dimensions (`endpoint.name`, `messaging.destination.name`) so the name layer stays one-per-workload.

---

# See it in the Services app

- Filter by your workload's name
- **SDv2**: one row, `serviceType = UNIFIED`
- **SDv1**: multiple rows like `orders-demo - OrderController`, even though they share one underlying entity
- Each fragmented row has its own health, baselines, and alerts. That's the cost the SDv2 collapse removes.

**Demo: One workload, one service** (`01-one-workload-one-service.yaml`)
