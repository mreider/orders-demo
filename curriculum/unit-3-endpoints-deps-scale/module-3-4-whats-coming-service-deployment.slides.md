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

# Module 3.4 — What's coming

**SERVICE_DEPLOYMENT for per-environment views**

---

# The remaining Classic pattern

Many Classic customers split services by environment via splitting rules:

- `checkout-service` (prod)
- `checkout-service` (staging)
- `checkout-service` (pre-prod)

Costs: config ambiguity, broken cross-env traces, duplicated ownership, cardinality explosion.

---

# Latest's default

`checkout-service` is **one SERVICE entity** regardless of where it runs.

- Per-env views come from dimensional slicing (`k8s.namespace.name`, `deployment.environment`, `service.version`)
- Correct for many questions

But: "what's the staging error rate, independent of prod?" benefits from treating an environment as something with identity.

---

# The direction: SERVICE_DEPLOYMENT

A new entity type **orthogonal to SERVICE**, carrying deployment context:

- `k8s.namespace.name` / `k8s.cluster.name`
- `deployment.environment` (prod/staging/preprod)
- `service.version`
- `deployment.release_stage`

A single SERVICE has many SERVICE_DEPLOYMENTs, linked by `dt.service.id`.

---

# What it gives you

- **One service identity** for ownership, naming, alerting
- **Per-deployment slices** for env-aware questions (baselines per env, release tracking)
- **Primary Tags on SERVICE_DEPLOYMENT** — "staging" tags the deployment; "team_X" tags the service
- **Smartscape consistency** without fragmenting the upstream SERVICE

---

# Datadog mapping

| Datadog | Dynatrace Latest |
|---|---|
| `service` | `dt.service.name` + `service.name` |
| `env` | `deployment.environment` / `k8s.namespace.name` on SERVICE_DEPLOYMENT |
| `version` | `service.version` on SERVICE_DEPLOYMENT |

Customers coming from Datadog will find this familiar.

---

# Why not today

- Entity extraction must move into OpenPipeline first (see Module 2.4 dependency chain)
- Design exists; problem statement is open and scoped
- No committed external timeline. Likely post-June 2026.

---

# What to do today

- Don't double down on splitting rules — that mechanism is being retired
- Use namespace/environment as **query dimensions** on a single entity
- Tag at the right level:
  - Service-level tags (team, cost center) → stay on SERVICE
  - Deployment-level tags (env, version) → expect to migrate to SERVICE_DEPLOYMENT

---

<!-- _class: title -->

# End of curriculum

**Thanks. Go back to your tenant and build.**
