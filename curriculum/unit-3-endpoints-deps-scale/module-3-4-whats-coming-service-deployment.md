# Module 3.4 — What's coming: SERVICE_DEPLOYMENT for per-environment views

> **No lab for this module.** This is the curriculum's final
> forward-looking orientation. It covers one remaining Classic-era
> pattern — fragmenting services by environment — and the additive
> entity that replaces it without breaking identity.

## The remaining Classic pattern

In Classic, many customers used service *splitting rules* to produce
separate SERVICE entities per environment:

- `checkout-service` (production) — one entity, one set of baselines.
- `checkout-service` (staging) — another entity, another set.
- `checkout-service` (pre-prod) — yet another.

This made per-environment views possible (click the staging entity,
see only staging traffic) but had significant costs:

- Configuration ambiguity ("is this alert on prod or all envs?").
- Broken traces (cross-environment calls showed between entities that
  didn't link cleanly).
- Ownership duplication (same team, three entities, three tag sets).
- Cardinality explosion for customers with many environments.

The Latest model explicitly **does not split identity by environment
by default**. The `checkout-service` is one SERVICE entity regardless
of where it runs. Per-environment views come from dimensional slicing
(`k8s.namespace.name`, `deployment.environment`, `service.version`)
rather than from separate entities.

That's correct for many questions. But some questions — "what's the
staging error rate, independent of prod?" or "baseline this
environment's throughput on its own" — benefit from treating an
environment as *something* with identity.

## The answer: SERVICE_DEPLOYMENT as an additive entity

`SERVICE_DEPLOYMENT` is a new entity type, orthogonal to SERVICE. It
carries deployment context:

- `k8s.namespace.name` / `k8s.cluster.name`
- `deployment.environment` (prod/staging/preprod)
- `service.version`
- `deployment.release_stage`

A single SERVICE has many SERVICE_DEPLOYMENTs. Each SERVICE_DEPLOYMENT
is linked to the SERVICE via `dt.service.id` and `dt.service.name`.

This gives you:

- **One service identity** for code ownership, naming, and alerting
  that doesn't care about env.
- **Per-deployment slices** for environment-aware questions (baselines,
  health, release tracking).
- **Primary Tags** live on `SERVICE_DEPLOYMENT`, not on SERVICE —
  because "team_X" tags the service, while "staging" tags the
  deployment.
- **Smartscape consistency**: deployments show up in topology views,
  segments, and Backstage without fragmenting the upstream SERVICE
  entity.

## The competitive framing

This maps directly onto Datadog's unified service tagging:

| Datadog | Dynatrace Latest |
|---|---|
| `service` | `dt.service.name` + `service.name` |
| `env` | `deployment.environment` or `k8s.namespace.name` (on SERVICE_DEPLOYMENT) |
| `version` | `service.version` (on SERVICE_DEPLOYMENT) |

Customers coming from Datadog will find this familiar. Customers on
Classic Dynatrace with aggressive splitting rules will find it a
relief — less configuration, fewer entities, same per-env insight.

## Rollout status

- The problem statement is open and scoped; the design exists.
- Entity extraction must move into OpenPipeline first (see Module 2.4
  for the dependency chain).
- No committed external timeline. Likely post-June 2026.

## What this means for you today

Two practical recommendations:

- **Don't double down on splitting rules.** If you're evaluating
  whether to create new env-split SERVICE entities via Classic
  splitting rules, don't. That mechanism is being retired. Use
  namespace/environment as query dimensions on a single entity.
- **Tag at the right level.** If you've got tags that describe the
  *service* (team, cost center, data classification), keep them on
  the SERVICE. If you've got tags that describe the *deployment*
  (env, region, release version), expect those to migrate to
  SERVICE_DEPLOYMENT. Plan your tag scheme accordingly.

## Curriculum close

You've reached the end.

Across three units, you've learned:

- **Unit 1**: what a service is in Latest Dynatrace (one workload, one
  entity), how its activity is measured (three metric families), and
  how it differs from Classic (attribute-first slicing, not
  entity-first).
- **Unit 2**: where names come from (resource-attribute fallback
  chain), why metric-first queries are cheaper, how to fix Classic
  services today (`service.name` workaround), and what pipeline-side
  naming will unlock later.
- **Unit 3**: per-endpoint baselining by default, the `http.route`
  gap and its automatic fix, downstreams as tabs instead of separate
  entities, and SERVICE_DEPLOYMENT as the next additive layer.

**[Capstone lab — your workload, end-to-end.](../capstone/capstone.md)**
One final notebook that walks the full narrative on a workload you
pick. No new concepts; it's integration practice and a portable
artifact you can show your team.
