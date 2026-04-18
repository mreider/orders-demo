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

# Module 1.2 — The Three Transport Families

**Unit 1: What is a service?**

---

# The Question

Pick the service you worked with in Module 1.1.

> *What kind of activity does this service do?*

You probably said *"it handles HTTP requests."* Often true — but the same service might also consume Kafka, process Lambda invocations, or do all three.

Each kind of activity lives under a **different metric family**.

---

# The Claim

Every service's activity in Dynatrace is measured under exactly one of three metric families.

| Family | Counts |
|---|---|
| `dt.service.request.*` | HTTP, gRPC, RMI entry points |
| `dt.service.messaging.process.*` | Kafka, SQS, Pub/Sub message consumption |
| `dt.service.faas_invoke.*` | Serverless function invocations |

There is no fourth family. Database calls and outbound HTTP attach to the **caller**, not their own family.

---

# Each Family Has Native Dimensions

The dimensions are the levers you split the chart by:

| Family | Key dimensions |
|---|---|
| `request.*` | `endpoint.name`, `http.route`, `http.response.status_code` |
| `messaging.process.*` | `messaging.destination.name`, `messaging.system`, `messaging.operation` |
| `faas_invoke.*` | `faas.trigger` |

Module 1.3 covers the dimensions in detail.

---

# Why "Transactions" Now Means Three Things

The Services app calls the umbrella of all three **"Transactions"**.

It used to say *"Requests,"* which made people think HTTP-only. The rename matters because:

- A REST + Kafka service has transactions of **two kinds**
- The Transactions column is the **coalesced total**
- Old dashboards that filtered to `request.*` only show part of the picture

---

# Why This Matters

- **Per-endpoint baselines, failure rates, and latency** all live on one of the three families
- **Mixed-transport services** (REST + Kafka, Lambda + API Gateway) need coalesced views
- The UI surfaces **Message Processing** and **Functions** tabs only when those families have data — that's why a pure HTTP service doesn't see them

---

# What the Lab Does

Open the companion notebook in your tenant: **Curriculum / Module 1.2**.

Three queries on a workload you pick:

1. **Which families does this service emit?** — counts side by side.
2. **Same workload, split by endpoint dimension.** — zooms into the dimensions per family.
3. **Coalesce.** — the workload-total query that matches the UI's "Transactions."

---

# What You Should See

- **Pure HTTP service**: only `request.*` has counts.
- **REST + Kafka** (the demo's `orders-demo`): both `request.*` and `messaging.process.*`.
- **Lambda**: `faas_invoke.*` populated; if behind API Gateway, `request.*` too.

The "Transactions" number in the UI is the sum across all three.

---

<!-- _class: screenshot -->

# What to Look For in the UI

![placeholder](assets/placeholder-transactions-and-tabs.png)

**SCREENSHOT:** Services app — service detail page Overview tab
- Show the **Transactions** metric prominently on Overview
- Show the **Message Processing** tab (and Functions tab if applicable) in the tab strip
- Highlight the **split-by** control offering `endpoint.name`, `messaging.destination.name`, `faas.trigger`
- **Key point:** One Transactions metric, three families behind it, one split-by control to slice them

---

<!-- _class: title -->

# Next: Module 1.3

**Dimensions, not entities, split the view**

Now that you know what's being counted, see how Latest splits those counts without creating new entities.
