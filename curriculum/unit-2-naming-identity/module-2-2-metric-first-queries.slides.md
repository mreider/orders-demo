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

# Module 2.2 — Metric-first queries

**Skip the entity table**

---

# The question

> *What's my slowest endpoint right now?*

Two DQL shapes answer it. Both return the same numbers.

- One is five lines, reads from the entity graph, and joins it in
- One is two lines and filters on a metric dimension directly

---

# The claim

`dt.service.name` and `service.name` are **first-class metric dimensions** in Latest.

- `filter` and `by` them directly on the metric
- No `fetch dt.entity.service` needed
- Entity table is still available for entity metadata (ownership, tags) — just not on the critical path

---

# Why prefer metric-first

- **Shorter queries** — easier to read and share
- **Fewer scanned records** — often an order of magnitude less
- **Stable identity** — dimension values ride through entity re-detection

---

# Entity-joined DQL

```
timeseries cnt = sum(dt.service.request.count),
by: {dt.entity.service, endpoint.name},
from: now()-30m
| lookup [fetch dt.entity.service | fields id, entity.name],
    sourceField: dt.entity.service, lookupField: id, prefix: "svc."
| filter svc.entity.name == "<YOUR_SERVICE_NAME>"
| fields endpoint.name, cnt
```

---

# Metric-first DQL

```
timeseries cnt = sum(dt.service.request.count),
by: {endpoint.name},
filter: matchesValue(dt.service.name, "<YOUR_SERVICE_NAME>"),
from: now()-30m
```

Same result. One filter, no `lookup`.

---

# The lab

Four comparisons, each answered two ways:

- List endpoints of a service
- Average response time for one endpoint
- Failure rate by HTTP status
- Workload total across three families

---

# In the Dynatrace UI

Nothing changes in the Services app — it already runs the right queries internally.

Where this matters: DQL you write yourself in **Notebooks**, **Dashboards**, **alerts**.

Watch **Scanned records** and **Execution time** in the cell metadata panel. Cheaper queries mean cheaper dashboards.

---

# Where it breaks

**Classic-detected services** may not have `dt.service.name` populated consistently.

If your workload is Classic and you haven't set `service.name`, metric-first queries by name will miss it.

Module 2.3 fixes that.

---

<!-- _class: title -->

# Next: Module 2.3

**The service.name workaround.**
