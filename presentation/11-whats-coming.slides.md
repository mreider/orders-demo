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

# What's coming

**Direction is firm. Timing is not.**

*Snapshot: May 1, 2026*

---

# Pipeline-side naming

Today's `service.name` fix is per-workload. Touching thousands of workloads is slow.

The direction: naming moves into **OpenPipeline**.

- Tenant admin writes a processing rule
- Rule sets `dt.service.name` on incoming spans before entity extraction
- Same central-control UX as Classic naming rules, composable with other pipeline processing

Waits on: pipeline modifying `dt.*`, entity creation after processing, batched topology updates.

---

# SERVICE_DEPLOYMENT

A planned entity type **orthogonal to SERVICE**, carrying deployment context.

- `k8s.namespace.name`, `k8s.cluster.name`
- `deployment.environment`, `service.version`, release stage
- One SERVICE has many SERVICE_DEPLOYMENTs, linked by `dt.service.id`

What it gives you: env-aware baselines, release tracking, and Primary Tags at the right level — without splitting the upstream SERVICE identity.

---

# Datadog mapping

| Datadog | Dynatrace |
|---|---|
| `service` | `dt.service.name` / `service.name` |
| `env` | `deployment.environment` on SERVICE_DEPLOYMENT |
| `version` | `service.version` on SERVICE_DEPLOYMENT |

Customers coming from Datadog will find this familiar.

---

# Also in motion

- **Services app rewire** to timeseries-first + filters
- **Primary Fields as metric dimensions** — `k8s.namespace.name`, cluster, tags queryable without `lookup`
- **Automatic URL normalization** (covered earlier) rolls out broadly

---

# What to do today

- Use the `service.name` fix for Classic services you own
- Don't invest in Services Classic naming rules — being retired
- Don't double down on splitting rules — use dimensional slicing, expect SERVICE_DEPLOYMENT for cases it can't cover
- Pick names that survive both the SDv2 move and the pipeline-naming move

---

<!-- _class: title -->

# That's the deck

**Questions? Try the demos. See the repo.**
