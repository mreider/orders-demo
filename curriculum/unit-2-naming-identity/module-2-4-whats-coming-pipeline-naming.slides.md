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

# Module 2.4 — What's Coming

**Pipeline-side name control**

---

# Forward-Looking Module

**No lab.** This module orients you on what changes later in 2026 — so you can plan around it.

---

# The Question You'll Ask Next

You've seen the `service.name` workaround. It works.

Now imagine you're the Dynatrace admin at a large enterprise — a thousand workloads, a dozen teams, some containers you can't touch.

> *"Does every team really have to redeploy every workload to get a good service name?"*

That friction is what the next wave of platform work removes.

---

# Why Touching Every Workload Isn't Enough

The Module 2.3 workaround works at a team's scale — not at a platform's:

- Hundreds or thousands of workloads
- Not every team has authority over every deployment
- Some workloads are third-party or immutable
- Every rename means another deploy

The old Classic naming-rules UI solved this server-side. That UI is deprecated. What replaces it?

---

# The Answer: Pipeline-Side Naming

Move naming decisions into **OpenPipeline** — the server-side processing layer your spans and logs already flow through.

A tenant admin writes a processing rule that modifies `dt.service.name` on incoming spans **before** entity extraction.

Same central-control UX as the old naming rules, but:

- Operates on **resource attributes**, not entity fingerprints
- Applied **once in the pipeline**, reflected everywhere downstream
- **Composable** with other pipeline processing

---

# Why It's Not Here Yet

Three platform-side prerequisites need to land first:

1. **Path for pipeline rules to modify `dt.*` attributes** — today the namespace is read-only at the processing layer
2. **Entity creation moved into the pipeline** — currently happens before the processing step
3. **Batched topology updates** — without batching, a tenant-wide rename floods the topology layer

Timelines aren't externally committed. Watch the community for 2026 milestones.

---

# What It Means for You Today

- **Use the `service.name` workaround** (Module 2.3) for Classic services you own — production-ready right now.
- **Don't reinvest** in Classic naming-rules being deprecated.
- **Plan around the shift.** Whatever `service.name` you choose now will survive the move to Latest *and* the move to pipeline-side naming.

---

# What It Means for the Services App

The short-term UI update that displays the prefixed `dt.service.name` is a **stopgap**.

Once pipeline-side naming ships, the entity name equals the pipeline-computed value directly — no prefixing.

Customers who set `service.name` today see cleaner names at that point, not prefixed composites.

---

# The Bigger Shift

Pipeline-side naming is part of a broader **"move processing to the pipeline"** initiative that also touches:

- **Endpoint detection** — Module 3.2's `http.route` heuristic is the near-term piece
- **Entity extraction** — including SERVICE_DEPLOYMENT for per-environment views (Module 3.4)
- **Metric extraction** with Primary Fields and Tags as first-class dimensions

Each step makes "everything is a dimension on a span" more complete.

---

<!-- _class: title -->

# Next: Unit 3

**Endpoints, downstreams, and scale**

Unit 3 moves from identity to the things *inside* a service — endpoints, their health, and downstream dependencies.
