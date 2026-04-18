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

# Module 1.4 — Classic vs Latest, Side by Side

**Unit 1: What is a service?**

---

# The Setup

The companion `orders-demo` is one Spring Boot app with:

- Two REST controllers (`OrderController`, `InventoryController`)
- A Kafka consumer (`OrderEventsListener`)
- A PostgreSQL JDBC client

Deployed into two namespaces, same cluster, same OneAgent, same image.

---

# Two Namespaces, Two Models

| Namespace | Detection |
|---|---|
| `orders-sdv1` | Classic |
| `orders-sdv2` | Latest |

Identical pods. Whatever differs in the Services app or in DQL is **detection-model only** — never an app difference.

---

# What the Lab Asks

Four structural questions, each answered against both namespaces:

1. **How many SERVICE entities exist for each workload?**
2. **Are any of those entities "fake"?**
3. **Is the underlying activity the same?**
4. **How does DQL shape differ?**

---

# Question 1 — Entity Counts

- **Classic** produces multiple entities: one WEB_REQUEST_SERVICE, one WEB_SERVICE per controller class, one MESSAGING_SERVICE for the Kafka listener, sometimes a DATABASE_SERVICE for the JDBC client.

- **Latest** produces one: a UNIFIED entity per workload.

This is Module 1.1 made visible.

---

# Question 2 — Fake Entities

The `orders-sdv1` side often shows a DATABASE_SERVICE named after the JDBC connection.

**There is no Postgres service being monitored here.** It's the Spring app's *client-side* JDBC calls dressed up as a service entity.

That's what "fake" means — an entity invented to hold metrics for something that isn't really a service you run. Module 3.3 expands on this.

---

# Question 3 — Same Underlying Activity

Both namespaces emit:

- The same spans
- The same transport dimensions
- The same activity totals (transactions per minute)

Only the **modelling over those spans** differs. The underlying observability data is identical.

---

# Question 4 — DQL Shape Diverges

| Approach | What you write |
|---|---|
| **Classic** | `lookup` against the entity table, filter by `serviceType`, then aggregate |
| **Latest** | Filter directly on `dt.service.name`, then aggregate |

Module 2.2 makes this explicit. For now: same answer, fewer lines, fewer scanned records.

---

# Why This Is Unit 1's Payoff

The earlier modules each established one piece:

- **1.1**: one workload → one entity (in Latest)
- **1.2**: three metric families
- **1.3**: splits live in dimensions, not entities

Module 1.4 is the composite — same app, same traffic, two models. The architectural claim becomes tangible.

---

<!-- _class: screenshot -->

# What to Look For in the UI

![placeholder](assets/placeholder-side-by-side-namespaces.png)

**SCREENSHOT:** Services app — list filtered by namespace, showing both
- Filter to `k8s.namespace.name = orders-sdv1`: column of Classic entities (`orders-demo`, `orders-demo - OrderController`, `OrderEventsListener`, possibly a `postgres` DATABASE_SERVICE)
- Filter to `k8s.namespace.name = orders-sdv2`: one row, `orders-sdv2 -- orders-demo`, serviceType UNIFIED
- Open the UNIFIED entity — show **Message Processing** and **DB Queries** tabs in place of separate entities
- **Key point:** Same app, two filters, two completely different topology pictures

---

<!-- _class: title -->

# Next: Unit 2

**Naming and identity**

You know *what* a service is. Unit 2 covers how it's named and how to query it efficiently.
