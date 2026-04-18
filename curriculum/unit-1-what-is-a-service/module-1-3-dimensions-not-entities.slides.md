---
marp: true
theme: uncover
class: invert
paginate: true
style: |
  section {
    background: linear-gradient(180deg, #0a0a14 0%, #0d0d1a 100%);
    font-family: 'Segoe UI', 'Arial', sans-serif;
    padding: 50px 70px 40px 70px;
    color: #ffffff;
    text-align: left;
    overflow: hidden;
  }
  section.title {
    text-align: center;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
  }
  section.title h1 {
    text-align: center;
    border-bottom: 4px solid;
    border-image: linear-gradient(90deg, #00a1e0, #b455b6) 1;
    padding-bottom: 16px;
    margin-bottom: 0;
    font-size: 1.8em;
  }
  h1 {
    color: #ffffff;
    font-size: 1.6em;
    font-weight: 700;
    text-align: left;
    border-bottom: 3px solid;
    border-image: linear-gradient(90deg, #00a1e0, #b455b6) 1;
    padding-bottom: 10px;
    margin-bottom: 20px;
    margin-top: 0;
  }
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
  .avail { font-size: 0.7em; margin-top: 16px; padding: 8px 12px; background: rgba(255,255,255,0.05); border-radius: 4px; }
---

<!-- _class: title -->

# Module 1.3 — Dimensions, Not Entities

**Unit 1: What is a service?**

---

# The Question

You're looking at one service in the Services app. You want to answer:

> *"Which of my endpoints is the slowest?"*

In **Classic**, the answer lived in a *different service*. OrderController was its own WEB_SERVICE entity; comparing it with InventoryController meant opening two tabs.

In **Latest**, both live on one entity. You split the view at **query time**.

---

# The Claim

The thing that became a separate entity in Classic — a controller, a Kafka listener, a database client — becomes a **dimension value** in Latest.

You group or filter by the dimension to get the slice you want.

**Nothing new is created in the entity graph.**

---

# Dimensions on the HTTP Family

For HTTP services, you split by:

- **`endpoint.name`** — the UI's "endpoint" concept (clean values from `http.route` when set)
- **`http.route`** — the raw route attribute from the framework
- **`http.request.method`** — split GETs from POSTs
- **`http.response.status_code`** — split 200s from 5xxs

Module 3.2 covers what happens when `http.route` is missing.

---

# Dimensions on the Messaging Family

For message-consuming services:

- **`messaging.destination.name`** — split per queue or topic
- **`messaging.operation`** — split `publish` (sender side) from `process` (receiver side)
- **`messaging.system`** — Kafka vs SQS vs Pub/Sub

Same mechanism as HTTP. Different family, different dimensions, same query shape.

---

# Why This Matters

| Concern | Classic pattern | Latest pattern |
|---|---|---|
| **Ownership** | Per-controller metadata | One entity, one owner |
| **Alerting** | One alert per entity | One alert covers all activity |
| **Baselining** | Per-entity baselines | Per-dimension-value baselines |
| **Cardinality** | Adding entities is expensive | Adding dimensions is cheap |

---

# What the Lab Does

Open the companion notebook in your tenant: **Curriculum / Module 1.3**.

Three queries that answer the same question three ways:

1. **Classic style** — entity-graph query, one row per WEB_SERVICE.
2. **Latest style** — split a single entity's metrics by `endpoint.name`.
3. **Same shape, messaging** — proves the mechanism generalizes across families.

---

# What You Should See

- **Classic**: one row per controller/listener entity, with a `lookup` against the entity table just to name them.
- **Latest**: one row per dimension value — same data, computed by group-by alone, no lookup.

That difference in DQL structure is the **query tax** of entity-first modelling. Module 2.2 lands on it explicitly.

---

<!-- _class: screenshot -->

# What to Look For in the UI

![placeholder](assets/placeholder-split-by-dimension.png)

**SCREENSHOT:** Services app — Latest service detail page, Explorer tab
- Show the **split-by** selector with `endpoint.name`, `messaging.destination.name`, `http.response.status_code`
- One service entity, multiple dimension rows in the chart
- For contrast, second screenshot: Classic service list with one row per controller class
- **Key point:** In Latest, you switch slices with a dropdown. In Classic, you switch slices by clicking between separate entities.

---

<!-- _class: title -->

# Next: Module 1.4

**Classic vs Latest, side by side**

Same app, deployed twice — one namespace under each model. Watch entity counts and query shapes diverge from the same source data.
