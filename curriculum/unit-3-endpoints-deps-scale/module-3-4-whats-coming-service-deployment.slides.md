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

# Module 3.4 — What's Coming

**SERVICE_DEPLOYMENT for per-environment views**

---

# Forward-Looking Module

**No lab.** This is the curriculum's final orientation.

It covers one remaining Classic-era pattern — fragmenting services by environment — and the additive entity that replaces it without breaking identity.

---

# The Remaining Classic Pattern

In Classic, many customers used **service splitting rules** to produce separate SERVICE entities per environment:

- `checkout-service` (production) — one entity, one set of baselines
- `checkout-service` (staging) — another entity, another set
- `checkout-service` (pre-prod) — yet another

This made per-environment views possible — click the staging entity, see only staging traffic.

---

# The Costs of That Pattern

- **Configuration ambiguity** — "is this alert on prod or all envs?"
- **Broken traces** — cross-environment calls didn't link cleanly between entities
- **Ownership duplication** — same team, three entities, three tag sets
- **Cardinality explosion** — multiplied by every environment

---

# What Latest Does Instead (For Now)

Latest **does not split identity by environment by default**.

`checkout-service` is one SERVICE entity regardless of where it runs. Per-environment views come from **dimensional slicing**:

- `k8s.namespace.name`
- `deployment.environment`
- `service.version`

Right for many questions. But some questions — *"baseline staging on its own"* — benefit from treating an environment as something with **identity**.

---

# The Answer: SERVICE_DEPLOYMENT

A new entity type, **orthogonal to SERVICE**. It carries deployment context:

- `k8s.namespace.name` / `k8s.cluster.name`
- `deployment.environment` (prod/staging/preprod)
- `service.version`
- `deployment.release_stage`

A single SERVICE has many SERVICE_DEPLOYMENTs, linked via `dt.service.id` and `dt.service.name`.

---

# What This Gives You

- **One service identity** for code ownership, naming, alerting (env-agnostic)
- **Per-deployment slices** for environment-aware questions (baselines, health, release tracking)
- **Primary Tags** live on SERVICE_DEPLOYMENT — because "staging" tags the deployment, "team_X" tags the service
- **Smartscape consistency** — deployments show up in topology without fragmenting the upstream SERVICE

---

# The Competitive Framing

Maps directly onto Datadog's unified service tagging:

| Datadog | Dynatrace Latest |
|---|---|
| `service` | `dt.service.name` + `service.name` |
| `env` | `deployment.environment` or `k8s.namespace.name` (on SERVICE_DEPLOYMENT) |
| `version` | `service.version` (on SERVICE_DEPLOYMENT) |

Familiar to Datadog migrants. Relief for Classic customers with aggressive splitting rules.

---

# Rollout Status

- The problem statement is open and scoped; the design exists
- **Entity extraction must move into OpenPipeline first** — the dependency from Module 2.4
- No committed external timeline. Likely **post-June 2026**

---

# What This Means for You Today

Two practical recommendations:

- **Don't double down on splitting rules.** If you're evaluating new env-split SERVICE entities via Classic splitting rules — don't. That mechanism is being retired.
- **Tag at the right level.** Service-level tags (team, cost center, data classification) stay on SERVICE. Deployment-level tags (env, region, release version) will migrate to SERVICE_DEPLOYMENT. Plan accordingly.

---

# Curriculum Close

You've reached the end of the structured material:

- **Unit 1**: what a service is, three metric families, attribute-first slicing
- **Unit 2**: where names come from, metric-first queries, the `service.name` workaround, pipeline-side naming
- **Unit 3**: per-endpoint baselining, the `http.route` gap, downstreams as tabs, SERVICE_DEPLOYMENT

---

<!-- _class: title -->

# Next: Capstone

**Your workload, end-to-end**

One notebook walks the full curriculum on a workload you choose. No new concepts — integration practice and a portable artifact for your team.
