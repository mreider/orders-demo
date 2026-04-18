# Module 3.4 — What's coming: SERVICE_DEPLOYMENT for per-environment views

*Forward-looking orientation. No lab.*

## The remaining Classic pattern

Many Classic customers use service splitting rules to produce separate SERVICE entities per environment (`checkout-service` in prod, staging, pre-prod). Per-env views were possible, but at a cost: config ambiguity, broken cross-env traces, duplicated ownership, cardinality explosion.

Latest does not split identity by environment by default. `checkout-service` is one entity regardless of where it runs. Per-env views come from dimensional slicing (`k8s.namespace.name`, `deployment.environment`, `service.version`).

## The direction

**`SERVICE_DEPLOYMENT`** is a new entity type orthogonal to SERVICE, carrying deployment context (namespace, cluster, environment, version, release stage). A single SERVICE has many SERVICE_DEPLOYMENTs, linked by `dt.service.id`.

- One service identity for ownership, naming, alerting.
- Per-deployment slices for env-aware questions (baselines per env, release tracking).
- Primary Tags live on SERVICE_DEPLOYMENT ("staging" tags the deployment, "team_X" tags the service).

This maps directly onto Datadog's unified service tagging (`service` + `env` + `version`).

## Why not today

- Entity extraction must move into OpenPipeline first (see Module 2.4 dependency chain).
- Design is scoped; no committed external timeline. Likely post-June 2026.

## What to do today

- Don't double down on splitting rules — that mechanism is being retired.
- Use namespace/environment as query dimensions on a single entity.
- Tag at the right level: service-level tags on SERVICE; deployment-level tags expect to migrate to SERVICE_DEPLOYMENT.

## End

You've covered: what a service is in Latest, how names propagate, the `service.name` workaround, per-endpoint baselining, the `http.route` gap, downstreams as tabs, and what's next.
