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

# Module 1.4 — Classic vs Latest, side by side

**Same application, two namespaces, two models**

---

# The setup

`orders-demo` application:

- Two REST controllers (`OrderController`, `InventoryController`)
- A Kafka consumer (`OrderEventsListener`)
- A PostgreSQL JDBC client

| Namespace | Detection |
|---|---|
| `orders-sdv1` | Classic |
| `orders-sdv2` | Latest (SDv2 opt-in) |

Identical pods, same OneAgent, same image.

---

# What differs — the claim

Four structural differences between the two sides:

1. **Entity count** — many vs one
2. **Fake entities** — Classic's synthesised `DATABASE_SERVICE`
3. **Activity totals** — identical (it's the same span stream)
4. **Query shape** — lookup vs direct filter

---

# Entity count

- **Classic** (`orders-sdv1`): 4–5 entities
  - `WEB_REQUEST_SERVICE` + per-controller `WEB_SERVICE` + `MESSAGING_SERVICE` + sometimes `DATABASE_SERVICE`
- **Latest** (`orders-sdv2`): 1 entity
  - `UNIFIED`, one per workload

Same pods. Same image. Different number of rows in the Services list.

---

# The fake entity

The `DATABASE_SERVICE` named `orders` or `postgres` on the Classic side is the **JDBC client dressed up as a service**.

- There is no Postgres service being monitored here
- The entity exists only because Classic needed somewhere to attach client-side JDBC metrics
- Latest removes it — DB calls become a tab on the calling service (Module 3.3)

---

# Activity totals match

- Same traffic hitting the same pods
- Same spans emitted with the same transport dimensions
- Two lines on the chart track each other

What changes between the models is the **modelling over the spans**, not the spans themselves.

---

# Query shape

**Classic:**
```
timeseries reqs = sum(dt.service.request.count), by: {dt.entity.service}
| lookup [fetch dt.entity.service | fields id, entity.name, serviceType], ...
| filter contains(svc.entity.name, "orders-demo")
    AND svc.serviceType == "WEB_REQUEST_SERVICE"
```

**Latest:**
```
timeseries reqs = sum(dt.service.request.count),
by: {dt.service.name},
filter: matchesValue(dt.service.name, "orders-sdv2 -- orders-demo")
```

---

# In the Dynatrace UI

- Filter Services app by `k8s.namespace.name = orders-sdv1` → column of Classic entities including a fake `DATABASE_SERVICE`
- Filter by `k8s.namespace.name = orders-sdv2` → one row, `UNIFIED`
- Open UNIFIED entity → **Message Processing** + **DB Queries** are tabs, not separate entities

---

<!-- _class: title -->

# End of Unit 1

**Next: Unit 2 — Naming and identity.**
