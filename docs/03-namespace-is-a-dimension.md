---
title: Rung 3 - Namespace is a dimension, not a service split
description: One new idea built on Rungs 1-2. Deployment context (namespace, cluster, version) is a metric dimension on one service identity, not a reason to split into multiple services.
rung: 3
last_updated: 2026-04-17
---

# Rung 3: Namespace is a dimension, not a service split

Recap of Rungs 1-2: endpoints are the unit of health, and Kafka
consumers are peers of HTTP endpoints.

## The new idea

> In SDv2, **deployment context** (namespace, cluster, version) is a
> metric dimension on **one** service identity. You slice charts by
> namespace, you do not split into new services.

To see this, deploy the same app into a second SDv2 namespace.

## Apply the staging namespace

This rung adds `orders-sdv2-staging`: same image, same Deployment, same
traffic (at lower rate to represent a staging environment). Same
`service.name`. Different `k8s.namespace.name`.

```bash
kubectl apply -f k8s/50-sdv2-staging.yaml
```

Wait a few minutes for traffic to flow and the ActiveGate to pick it up.

## What you should see

Go back to **Services** and find `orders-demo`:

- Still **one** service entity. Not two. The `service.name` is the same
  across both namespaces, so SDv2 treats them as one logical service.
- Two **SERVICE_DEPLOYMENT** entities hanging off it: one for
  `orders-sdv2` (namespace = `orders-sdv2`) and one for
  `orders-sdv2-staging` (namespace = `orders-sdv2-staging`).
- Endpoints still have one row each, but the charts can be **split by
  `k8s.namespace.name`**. Open the response-time chart on `POST /orders/submit`,
  click the split-by control, pick `k8s.namespace.name`. Two series. Same
  endpoint. Different deployment contexts.

This is the Datadog unified-service-tagging shape (`service`, `env`,
`version`) expressed in Dynatrace's entity model:

| Datadog tag | Dynatrace equivalent here |
|---|---|
| `service` | `service.name` = `orders-demo` |
| `env` | `k8s.namespace.name` (we use namespace as env proxy) |
| `version` | `service.version` (not demonstrated here - would be a pod annotation) |

## Compare to `orders-sdv1`

On the SDv1 side, if we had deployed this app to a second namespace
under SDv1 detection, we would have seen a second service entity, with
its own baselines, its own dashboards, its own key requests. Two
services, same code, different infra. That is the fragmentation that
pushed teams to manual unified-service-tagging hacks.

SDv2's SERVICE_DEPLOYMENT avoids the fragmentation without losing
per-environment visibility. One identity. Dimensional slicing for views.

## Why this matters for splitting rules

In the anchor, one of the SDv1 configuration burdens was host-group
splits: the same binary in dev and prod became two services, sometimes
three. Teams lived with it because they needed per-environment health.

With SERVICE_DEPLOYMENT, you get per-environment health through a
dimension, not through splitting. The splitting rules are not
necessary anymore. Mike's stated direction is to reduce reliance on
splitting in favor of this dimensional slicing.

## What you now know

> One service identity, many deployment contexts. Per-environment
> health is a chart split, not an entity split. The instinct to make a
> new service for every infra boundary is the SDv1 instinct; you do not
> need it here.

Next: [Rung 4 - Failure crosses the seam](04-failure-crosses-the-seam.md).
