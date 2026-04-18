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

# Capstone — Your Workload, End-to-End

**One notebook, the full curriculum walk**

---

# Why a Capstone

The three units covered a lot of ground in small pieces.

A single end-to-end pass on a real workload — **yours, not the demo's** — helps the framework stick.

A one-notebook walk-through is also the **most shareable artifact**. Point a teammate at it, they run through it in 30 minutes, they understand.

---

# What You'll Need

- A workload in your tenant, ideally one you own and know well
- Its `k8s.namespace.name` and `k8s.workload.name`
- Its `dt.service.name` — find it with this query:

```
timeseries cnt = sum(dt.service.request.count),
by: {dt.service.name, k8s.workload.name},
filter: matchesValue(k8s.workload.name, "<YOUR_WORKLOAD>"),
from: now()-30m
```

If you have both Classic and Latest workloads, pick a Latest one for the main walk. Use a Classic one for the optional side-by-side at the end.

---

# Capstone Structure

| Section | Asks | From |
|---|---|---|
| 1. **Identity** | How many entities is this workload? | Unit 1.1 |
| 2. **Activity** | What metric families does it emit? | Unit 1.2 |
| 3. **Slices** | Split by endpoint, destination, etc. | Unit 1.3 |
| 4. **Naming** | Where does its name come from? | Unit 2.1 |

---

# Capstone Structure (cont'd)

| Section | Asks | From |
|---|---|---|
| 5. **Query shape** | Rewrite a dashboard query metric-first | Unit 2.2 |
| 6. **Endpoints** | Which are baselined? Any `METHOD /*`? | Units 3.1 + 3.2 |
| 7. **Downstreams** | DB, messaging, outbound HTTP tabs | Unit 3.3 |
| 8. **Side-by-side** *(optional)* | Compare with a Classic workload | Unit 1.4 |

---

# How to Run It

Open the companion notebook in your tenant: **Curriculum / Capstone**.

Each section runs the same query pattern as its source unit, but **on your workload's identifiers**.

The notebook is environment-shared by default when loaded with `dtctl apply --share-environment`. Pass the URL to a colleague — they re-run every cell, substitute their own workload, and the notebook becomes a personal onboarding guide.

---

# What's Next After This

This curriculum focuses on **service detection** and the query/naming patterns that follow. Adjacent topics worth learning next, in priority order:

- **Segments and Primary Tags** — replaces Management Zones
- **Failure Analysis** — unified failure detection across the three families
- **Baselining and anomaly detection** — how per-endpoint baselines are computed
- **Kubernetes app topology** — how the K8s app relates to the Services app
- **Pipeline processing rules** — OpenPipeline transformations

---

# Feedback

This curriculum lives in the **orders-demo** GitHub repo alongside the companion app.

PRs welcome — especially for:

- Sections that don't land
- Queries that need fixing for a specific Dynatrace version
- Lab steps that assume too much

Ask your Dynatrace representative if a learning path exists yet for any of the adjacent topics.

---

<!-- _class: title -->

# You're Done

**Run the notebook on your workload. Send it to a colleague.**
