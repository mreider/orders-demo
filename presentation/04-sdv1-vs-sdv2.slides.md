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

# SDv1 vs SDv2, side by side

**Same app, two namespaces, two detection models**

---

# The point

`orders-demo` runs in two namespaces on the same cluster, same OneAgent. Identical pods. Any difference is a detection-model difference.

| Namespace | Detection |
|---|---|
| `orders-sdv1` | SDv1 (default, K8s-aware) |
| `orders-sdv2` | SDv2 (opted in per namespace) |

Two REST controllers, a Kafka consumer, a PostgreSQL JDBC client. Activity is identical on both sides. Only the modelling on top differs.

---

# Three structural differences

1. **`dt.service.name` fragmentation count**: ~7 (SDv1) vs 1 (SDv2)
2. **Underlying entity type**: `WEB_REQUEST_SERVICE` vs `UNIFIED` (both 1-per-workload)
3. **Query shape**: group-by-name or lookup (SDv1) vs direct filter (SDv2)

Both models are 1-entity-per-workload. Only the names above differ.

---

# Historical note: the fake DATABASE_SERVICE

Coming from **Classic Dynatrace** (pre-Latest)? You may remember separate `DATABASE_SERVICE`, `MESSAGING_SERVICE`, `EXTERNAL_SERVICE` entities for each downstream.

- On Latest Dynatrace tenants those entities are gone
- SDv1 already adopted the caller-side dimensional model: database identity lives on the JDBC client span as `db.system`, `db.namespace`, `server.address`
- SDv2 inherits that and collapses the per-controller `dt.service.name` fragmentation on top

---

# Query shape

**SDv1 side, group by `dt.service.name` to see every fragment:**
```
timeseries reqs = sum(dt.service.request.count),
by: {dt.service.name},
filter: matchesValue(k8s.namespace.name, "orders-sdv1")
    AND matchesValue(k8s.workload.name, "orders-demo")
```

**SDv2 side, filter to the one name:**
```
timeseries reqs = sum(dt.service.request.count),
filter: matchesValue(dt.service.name, "orders-sdv2 -- orders-demo")
```

---

# See it in the Services app

- Filter by `k8s.namespace.name = orders-sdv1`: multiple rows (`orders-demo - OrderController`, `OrderEventsListener`, `orders-demo`), all pointing at the same `WEB_REQUEST_SERVICE` entity
- Filter by `k8s.namespace.name = orders-sdv2`: one row, `serviceType = UNIFIED`
- Open the UNIFIED row: **Message Processing** and **DB Queries** are tabs on the single service, not separate Services list rows

**Demo: SDv1 vs SDv2, side by side** (`04-sdv1-vs-sdv2.yaml`)
