---
title: "Migrating from Service Detection v1 to v2: what actually changes, and how to see it in your tenant"
audience: Dynatrace Community / LinkedIn / internal field enablement
---

# Migrating from Service Detection v1 to v2 on OneAgent

If you run Kubernetes workloads monitored by OneAgent on a Latest Dynatrace tenant, Service Detection v2 changes how your services are modeled. It's a bigger shift than a version bump. It changes what a "service" is, how names propagate, and where per-endpoint or per-environment detail lives.

I put together a short presentation plus a set of live demos that run against your own tenant. The repo is here: [github.com/mreider/orders-demo](https://github.com/mreider/orders-demo). Landing page: [sdv2.mreider.com](https://sdv2.mreider.com).

## The shift in one sentence

Under SDv1, one Kubernetes workload typically tags its spans with several distinct `dt.service.name` values (one per controller class, one per Kafka listener, one aggregate). Under SDv2, one workload produces one `dt.service.name`, and the per-endpoint or per-queue detail moves onto first-class query dimensions like `endpoint.name` and `messaging.destination.name`.

The entity graph already consolidated to one WEB_REQUEST_SERVICE per workload on modern Grail tenants. What SDv2 specifically collapses is the `dt.service.name` fragmentation that SDv1 still produces on top of that entity.

## Why it matters

- **One health signal per workload**, not one per controller class. Alerts, baselines, and dashboards scope to the thing you actually deploy.
- **Queries shorten**. Group by `endpoint.name` on one entity instead of joining across a dozen WEB_SERVICE rows.
- **Downstream dependencies move with the caller**. Databases, Kafka queues, third-party HTTP don't appear as separate entities. They're tabs on the calling service, rich with per-downstream dimensions.

## What the presentation covers

Twelve short sections, each with a live demo notebook:

- One workload, one service: counting `dt.service.name` values on a workload.
- The three transport families: HTTP, messaging, FaaS metrics.
- Dimensions, not entities: per-endpoint slicing without entity joins.
- SDv1 vs SDv2, side by side: same app, two namespaces, one detection difference.
- Where names come from: the resource-attribute fallback chain.
- The `service.name` fix: the workaround that works today for Classic services you own.
- Every endpoint baselined: SDv2's endpoint-level SLO guarantee.
- When `http.route` is missing: why you see `GET /*`, and what to do about it.
- Downstreams are tabs, not entities: the caller-side dimensional model.
- What's coming: pipeline-side naming and SERVICE_DEPLOYMENT for per-environment views.

Demo notebooks run on your own Dynatrace data. No sample backend needed (unless you don't have a workload with the right shape, in which case there's a Spring Boot app in the repo that produces the necessary traffic).

## Try it

- Read the walkthrough: [github.com/mreider/orders-demo/tree/main/presentation](https://github.com/mreider/orders-demo/tree/main/presentation)
- Grab the slide deck from the latest release: [github.com/mreider/orders-demo/releases/latest](https://github.com/mreider/orders-demo/releases/latest)
- Load the demo notebooks into your tenant with the script in `scripts/load-demos.sh`. Requires dtctl 0.24 or later.

## A note on the "what's coming" section

Direction is firm: pipeline-side naming, SERVICE_DEPLOYMENT for per-environment views, automatic URL normalization for the `http.route` gap. Timing is less firm, so treat the roadmap section as shape-of-the-road, not an arrival date.

Feedback welcome. The repo accepts issues and PRs.
