---
title: Epilogue - Where SDv2 is headed
description: What the preview you just walked does not yet do, and where the product is going.
rung: epilogue
last_updated: 2026-04-17
---

# Where SDv2 is headed

The four rungs you walked are real today on the `orders-sdv2`
namespace: one UNIFIED service, endpoint-level baselines, Kafka as
peer endpoint, unified failure analysis. That is the public-preview
state of SDv2 as of April 2026.

Two limitations of the preview are worth being honest about.

## The namespace is still in the service name

The built-in detection rule `{k8s.namespace.name} -- {k8s.workload.name}`
means deploying the same `orders-demo` workload to `orders-sdv2-staging`
produces a second service entity called
`orders-sdv2-staging -- orders-demo`. Today, per-environment views
come from entity splitting, not from a metric dimension on one
identity.

Stated direction (PM-led, not yet shipped):

- Remove `{k8s.namespace.name}` from the built-in naming rule.
- Remove the `[Built-in] Split services by k8s cluster and namespace`
  rule or make it opt-in.
- Add **`SERVICE_DEPLOYMENT`** as an additive entity that carries the
  deployment context (namespace, cluster, release version, stage)
  and links back to a single SERVICE entity.
- Surface per-environment views as a **split-by** on charts against
  the `k8s.namespace.name` dimension of the one service, not as a
  separate service entity.

If that ships, the ladder's "one identity" story becomes literal:
one `orders-demo` service across all namespaces, sliced by namespace
when you want an environmental view.

## Splitting rules vs. dimensional slicing

SDv1's whole configuration burden is a symptom of entity splitting
being the only way to get per-feature or per-environment health.
SDv2 removes it for per-feature (endpoints are the unit) but not yet
for per-environment (splitting is still on by default).

The product direction is consistent with how Datadog handles this:
`service`, `env`, `version` as unified tags on one identity. The
Dynatrace-equivalent mapping is documented in
[`context/architecture/service-metrics-framework`](../../../context/architecture/service-metrics-framework.md).

## What to tell customers asking about this today

- "One UNIFIED service entity per namespace-workload. HTTP and
  messaging endpoints collapse into it. This is the preview today."
- "Future direction is one identity across environments, with
  `SERVICE_DEPLOYMENT` providing deployment context. We will keep
  you posted on when the built-in splitting rule is removed."
- "If you want the future shape today, you can disable the built-in
  splitting rule and create a custom detection rule that drops
  `{k8s.namespace.name}` from the service name. Not recommended for
  production until we ship SERVICE_DEPLOYMENT."

## Appendix: things we deliberately did not teach in the ladder

Parked for depth sessions:

- `@Scheduled` and `@Async`: how SDv2 treats background Spring work
  and whether it shows up as endpoints on the same UNIFIED service.
- `faas_invoke.*` family: Lambda triggers and the third metric family.
- Webhook endpoints: distinct baselining for inbound third-party
  calls to custom routes.
- `service.version` and `deployment.release_stage` as additional
  dimensions when SERVICE_DEPLOYMENT lands.
- Enhanced endpoints vs. classic key requests in the Phase 3
  migration story.
- Custom services in SDv2: producing spans on the parent service
  instead of separate entities.
