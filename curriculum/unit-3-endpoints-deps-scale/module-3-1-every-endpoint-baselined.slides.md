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

# Module 3.1 — Every Endpoint Is Baselined

**Unit 3: Endpoints, downstreams, and scale**

---

# The Question

In **Classic**, you picked a handful of endpoints per service and marked them as **key requests**.

Those got individual baselines, individual alerts, prominent UI placement. Everything else rolled up into `NON_KEY_REQUESTS` — measured, but without per-endpoint insight.

> *What happens in Latest when you don't configure key requests?*

---

# The Claim

**Every endpoint gets what used to be reserved for key requests.**

- Individual baselines
- Individual latency percentiles
- Individual failure rates
- **No configuration required**

The dimensions that define an endpoint (`endpoint.name`, `http.route`, `messaging.destination.name`) are the same ones the baselining system reads from.

---

# Why "Key" vs "Non-Key" Is Gone

The cost structure of baselining has improved enough that the carve-out isn't needed.

There's no "key" and "non-key" split anymore — every endpoint is important enough to baseline, full stop.

Classic's split existed because compute was expensive. Latest doesn't have that constraint.

---

# Why This Matters

- **Less manual config.** "Pick my important endpoints, mark them key" doesn't apply.
- **Anomaly detection extends to long-tail endpoints.** The endpoint called ten times a day still gets a baseline.
- **Baselines move with dimensions.** A new route or new queue gets baselined as soon as data arrives — no warm-up gate.

---

# What Existing Customers Should Know

Key requests are gone in Latest; **enhanced endpoints** replaces them. While your tenant transitions:

- Existing key requests are **preserved as named endpoints**
- Custom request naming rules survive the transition
- Custom baselines tuned on key requests transfer onto the equivalent dimension values
- The "mark this a key request" button is replaced by enhanced-endpoints config

You don't lose what you configured. You gain insight into everything else.

---

# What the Lab Does

Open the companion notebook in your tenant: **Curriculum / Module 3.1**.

Two queries on a real service:

1. **Endpoint inventory.** Every endpoint Dynatrace sees over the last 24 hours.
2. **Per-endpoint latency percentiles.** p50/p95/p99 per endpoint over the same window.

Every endpoint — not just the ones you'd have marked key — has distinct, queryable latency.

---

# What You Should See

A service with a handful of endpoints in Classic becomes a service with **dozens** in Latest.

If your service has real long-tail traffic — admin endpoints, health checks, rarely-hit paths — they all show up now.

The surprise is usually how *many* endpoints there are. That's the visibility you didn't have before.

---

<!-- _class: screenshot -->

# What to Look For in the UI

![placeholder](assets/placeholder-endpoints-section.png)

**SCREENSHOT:** Services app — service detail page, Endpoints section
- Show every endpoint as its own row with throughput, latency, failure rate columns
- Sort by throughput **ascending** to surface the long tail (admin paths, health probes, rare routes)
- If the customer had key requests configured, show them mixed in alongside auto-named endpoints
- **Key point:** Each row's metrics are backed by a live baseline on the underlying dimension value — zero manual config

---

<!-- _class: title -->

# Next: Module 3.2

**When `http.route` is missing**

The clean per-endpoint story assumes every endpoint has a clean name. When the framework doesn't provide one, you'll see `GET /*` everywhere.
