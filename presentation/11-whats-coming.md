# What's coming

> **Snapshot as of May 1, 2026.** Direction is firm; timing is not. Treat the items below as the shape of the road, not the arrival date.

Two things on the near road worth knowing about before you plan long-lived Classic detection changes.

## Pipeline-side name control

Today's `service.name` fix (covered earlier) works, but it's per-workload. At enterprise scale, touching thousands of workloads and their owning teams is slow.

The direction: naming moves into **OpenPipeline**, the server-side processing layer spans already flow through. A tenant admin writes a processing rule that sets `dt.service.name` on incoming spans before entity and metric extraction. Same central-control UX as the old Classic naming-rules overlay, but operating on resource attributes with pipeline composability.

Prerequisites being worked on: pipeline rules can modify `dt.*` attributes, entity creation moves after processing, batched topology updates. No committed external timeline; watch the Dynatrace community for milestones.

## SERVICE_DEPLOYMENT for per-environment views

Many Classic customers use service splitting rules to produce separate SERVICE entities per environment (`checkout-service` in prod, staging, pre-prod). Per-env views were possible, but at a cost: config ambiguity, broken cross-env traces, duplicated ownership, cardinality explosion.

SDv2 doesn't split identity by environment by default. `checkout-service` is one entity regardless of where it runs. Per-env views come from dimensional slicing (`k8s.namespace.name`, `deployment.environment`, `service.version`).

That's right for most questions. But *"what's the staging error rate, independent of prod?"* benefits from treating an environment as something with identity of its own.

**`SERVICE_DEPLOYMENT`** is a planned entity type orthogonal to SERVICE, carrying deployment context (namespace, cluster, environment, version, release stage). A single SERVICE has many SERVICE_DEPLOYMENTs, linked by `dt.service.id`:

- One service identity for ownership, naming, alerting.
- Per-deployment slices for env-aware questions (baselines per env, release tracking).
- Primary Tags live on SERVICE_DEPLOYMENT (`env=staging` tags the deployment; `team=X` tags the service).

This maps directly onto Datadog's unified service tagging (`service` + `env` + `version`).

## What else is in motion

- **Services app rewire to timeseries-first.** The list and detail pages move from entity-list-plus-chart to a query-led model: pick metric families, split by dimensions, filter on tags.
- **Primary Fields as metric dimensions.** `k8s.cluster.name`, `k8s.namespace.name`, and configurable tags become first-class dimensions on the service metric families, so you can filter and split without a `lookup` to the entity table.
- **Automatic URL normalization** (covered earlier) rolls out to more customers.

## What to do today

- Use the `service.name` fix for Classic services you own.
- Don't invest new effort in Services Classic naming rules — being retired.
- Don't double down on splitting rules for per-env views — use dimensional slicing now, and expect SERVICE_DEPLOYMENT for the cases where it's not enough.
- Pick names that survive both the SDv2 move and the pipeline-naming move. Good `service.name` values are durable; cute detection-rule workarounds are not.
