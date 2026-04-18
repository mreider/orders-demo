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

# Module 3.3 — Downstreams Are Tabs, Not Entities

**Unit 3: Endpoints, downstreams, and scale**

---

# The Question

Your service calls Postgres.

In **Classic**, Postgres showed up as a DATABASE_SERVICE entity in the Services list. Its own row, its own failure rate, its own baselines.

In **Latest**, that DATABASE_SERVICE row often *doesn't exist* — or it's being phased out.

> *Where do DB calls live in the Latest Services app, and why did the model change?*

---

# The Claim

Downstream dependencies — database, messaging, third-party HTTP — are now **tabs on the calling service**, not separate entities.

The information hasn't disappeared. It's been **relocated** from "pretend there's a downstream service entity" to "show the calling service's view of what it talks to."

---

# The Three Tabs

| Tab | Metric family | What it shows |
|---|---|---|
| **DB Queries** | `dt.service.database.query.*` | Every SQL/NoSQL op with `db.system.name`, `db.operation`, `db.sql.table` |
| **Message Processing** | `dt.service.messaging.process.*` + publish side | Consume + publish per `messaging.destination.name`, `messaging.system` |
| **Outbound Calls** | `dt.service.thirdparty.*` + spans | Every client-side HTTP call with host, endpoint, status |

---

# Why This Matters: No More Fake Entities

In Classic, a `postgres:orders-db` DATABASE_SERVICE entity existed not because Postgres was being monitored — but because Dynatrace needed somewhere to attach client-side JDBC metrics.

That entity was **always a fiction**. Latest removes it.

You saw this in Module 1.4's Question 2 — the "fake" entity in `orders-sdv1` is exactly this case.

---

# Why This Matters: Trace-Based RCA

When the DB is slow and your service is slow, you follow the **trace** — from the service's HTTP handler into its JDBC span, out to the query.

You don't hop entity graphs.

This is faster, more precise, and matches how distributed systems actually fail.

---

# Why This Matters: Ownership

The team that owns the service owns its DB-client side too.

No separate *"who owns this DATABASE_SERVICE?"* question. No orphan entities. No ambiguous tags.

One entity, one owner, one accountability surface.

---

# Existing-Customer Concerns

Two things customers notice and sometimes mistake for bugs:

- **"Where are my queue listeners?"** Each Classic `MESSAGING_SERVICE` became a Message Processing tab. No top-level row anymore.
- **"My external service entity is gone."** Third-party HTTP shows up in Outbound Calls. Recognized third parties get richer drill-down; everything else is in the trace side-pane.

Some customers spend days debugging IAM thinking these are permission bugs. **The services aren't gone. They're tabbed.**

---

# What the Lab Does

Open the companion notebook in your tenant: **Curriculum / Module 3.3**.

Three queries on the underlying tab data:

1. **Database queries from a service** — `dt.service.database.query.*` filtered to your service.
2. **Messaging publish side** — outbound publishes (which weren't their own MESSAGING_SERVICE in Classic).
3. **Outbound HTTP** — third-party and internal traffic, rolled up per host.

---

<!-- _class: screenshot -->

# What to Look For in the UI

![placeholder](assets/placeholder-service-detail-tabs.png)

**SCREENSHOT:** Services app — service detail page, tab strip at the top
- Show **DB Queries**, **Message Processing**, **Outbound Calls** tabs visible
- Click into DB Queries — show one row per (database-system, operation) pair
- Compare with the Services list — confirm no separate rows for the database, queue, or third-party hosts
- **Key point:** The topology simplified. Every downstream is a facet of the calling service, not its own row.

---

<!-- _class: title -->

# Next: Module 3.4

**What's coming — SERVICE_DEPLOYMENT for per-environment views**

The final forward-looking module. One additive entity for env/version slices, without fragmenting service identity.
