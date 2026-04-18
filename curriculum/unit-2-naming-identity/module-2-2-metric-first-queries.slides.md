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

# Module 2.2 — Metric-First Queries

**Unit 2: Skip the entity table**

---

# The Question

You ask: *"What's my slowest endpoint right now?"*

Two DQL shapes return the same numbers:

- One is **five lines**, joins the entity table
- One is **two lines**, filters a metric dimension directly

> *Why does the short version exist, and why should you prefer it?*

---

# The Claim

`dt.service.name` and `service.name` are **first-class metric dimensions** in Latest.

You can `filter` and `by` them directly on the timeseries metric.

**No `fetch dt.entity.service` needed.**

The entity table is still there if you want entity metadata (ownership, tags, description). It's just no longer on the critical path for metric questions.

---

# Three Reasons This Matters

1. **Shorter queries** — easier to read, share, and teach.
2. **Fewer table scans** — `Scanned records` in query metadata is often an order of magnitude lower.
3. **Stable identity** — if a service is renamed or re-detected, the metric dimension rides through. Classic entity-ID lookups break when IDs change.

---

# Why This Exists Now

In **Classic**, `dt.entity.service` was the primary key. Metrics carried entity IDs; names lived on the entity. The only way to ask "response time for service X" was *look up X's ID, then query metrics by ID*.

In **Latest**, the pipeline writes `dt.service.name` onto the metric itself, with the value already set by the detection chain (Module 2.1).

Metric-by-name queries work without the detour.

---

# What the Lab Does

Open the companion notebook in your tenant: **Curriculum / Module 2.2**.

Four comparisons, each answering one question two ways:

1. List all endpoints of a service
2. Average response time for one endpoint
3. Failure rate split by HTTP status
4. Workload-level throughput across three metric families

Watch the `Scanned records` counter on each.

---

# What You Should See

The entity-joined version is **4–6 lines longer** and typically scans **one to two orders of magnitude more records**.

For small tenants the wall-clock difference is small. It adds up in:

- **Dashboards** that auto-refresh
- **Alerts** that re-evaluate on a schedule
- **Notebooks** like the ones in this curriculum

Prefer metric-first by default.

---

# Where This Breaks Down (Today)

**Classic-detected services** may not have `dt.service.name` populated consistently.

If your workload is under Classic and you haven't set `service.name`, metric-first queries by name will:

- **Miss it entirely**, or
- **Collapse multiple entities** into a single dimension value

Module 2.3 covers the fix.

---

<!-- _class: screenshot -->

# What to Look For in the UI

![placeholder](assets/placeholder-query-metadata.png)

**SCREENSHOT:** Notebooks app — DQL cell with query metadata panel open
- Show two cells side by side: entity-joined version on top, metric-first below
- Highlight **Scanned records** in the metadata panel — note the order-of-magnitude difference
- Highlight **Execution time** for both
- **Key point:** Cheaper queries mean cheaper dashboards and alerts. The metadata panel is how you see it.

---

<!-- _class: title -->

# Next: Module 2.3

**The `service.name` workaround for Classic services**

If you have ugly Classic services and can't wait for Latest, this is what to do this afternoon.
