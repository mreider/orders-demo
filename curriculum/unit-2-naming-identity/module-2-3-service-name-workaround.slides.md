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

# Module 2.3 — The `service.name` Workaround

**Unit 2: Fix Classic services today**

---

# The Question

You have a Classic-detected service. Its name is `:8080`, or `OrderController`, or a Java class path.

You can't query it cleanly by name — there's no `service.name` dimension on its metrics. And the Classic naming-rules overlay is deprecated.

> *What can you do this month, without a Dynatrace release, to make it queryable and readable?*

---

# The Claim

Set `service.name` as a resource attribute on that workload's spans.

**Three immediate wins, one deferred.**

---

# What You Get Today

| Benefit | How |
|---|---|
| `service.name` as a queryable metric dimension | Standard metric extraction propagates resource attributes |
| Prefixed `dt.service.name` on metrics — `<service.name> (<detected>)` | 2026-Q1 detection-layer fix |
| Visible `service.name` on traces and span analysis | Span resource attribute carries through |

The Services app entity display name catching up to the prefixed value is the **deferred** win — it ships with the next UI update.

---

# What It Doesn't Fix

Classic's **entity fragmentation** (multiple entities per workload) does **not** go away.

- Setting `service.name` helps you **query** and **identify** Classic services
- It does **not** collapse them into a single entity
- For consolidation, you need Latest detection enabled on the namespace

The workaround is about naming and queryability — not topology.

---

# How to Set It

Mechanism depends on instrumentation:

- **OTel-native**: `OTEL_SERVICE_NAME=<name>` env var
- **OTel Java agent**: same env var on the agent's container
- **OneAgent deep monitoring**: same env vars; OneAgent's OTel bridge surfaces them as resource attrs
- **Code-level (any language)**: set the OTel SDK Resource directly — overrides env vars

---

# Why This Matters

A huge chunk of Latest's value is in **query ergonomics** (Module 2.2) and **naming** (Module 2.1).

`service.name` delivers most of that benefit for your **Classic-detected services today**, without waiting for Latest to roll out to every namespace.

It's the most useful thing to teach customers blocked on Latest for compatibility reasons. They get metric-first ergonomics this afternoon.

---

# What the Lab Does

Open the companion notebook in your tenant: **Curriculum / Module 2.3**.

Compares two Classic workloads in the demo's `orders-sdv1` namespace:

- `orders-demo` — no `OTEL_SERVICE_NAME`, baseline behavior
- `orders-demo-named` — `OTEL_SERVICE_NAME=orders-api` set

Four queries demonstrate spans, metric dimensions, prefixed `dt.service.name`, and that entity counts stay the same.

---

# What You Should See

For the **named** workload:

- `service.name` is on the spans
- `service.name` is a queryable metric dimension
- `dt.service.name` is **prefixed**: `orders-api (orders-demo - OrderController)`
- Entity count is **unchanged** — still 4 Classic entities

For the **baseline** workload: `service.name` is empty everywhere.

---

# The Customer Recommendation

When asked *"my Classic services have ugly names, what do I do?"*:

1. Decide the right `service.name` per workload (workload, team, or business name — not a port)
2. Set `OTEL_SERVICE_NAME` on the container
3. Re-deploy. Within minutes, spans, metrics, and `dt.service.name` reflect it
4. Write DQL using the new dimension (Module 2.2 patterns)
5. Wait for the Services app UI to start displaying the prefixed name

---

<!-- _class: screenshot -->

# What to Look For in the UI

![placeholder](assets/placeholder-prefixed-service-name.png)

**SCREENSHOT:** Services app — list view filtered to the two demo workloads
- Show `orders-demo` (baseline) and `orders-demo-named` side by side
- Highlight the prefixed name on the named workload: `orders-api (orders-demo - OrderController)`
- Open a Notebook cell, split by `service.name` — show value populated for named, empty for baseline
- **Key point:** Same Classic detection, but the named workload has clean query ergonomics today

---

<!-- _class: title -->

# Next: Module 2.4

**What's coming — pipeline-side name control**

The workaround needs a redeploy. The longer-term fix moves naming into the server-side pipeline, no app changes needed.
