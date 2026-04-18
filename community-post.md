---
title: "Migrating from Service Detection v1 to v2: what actually changes, and how to see it in your tenant"
audience: Dynatrace Community / LinkedIn / internal field enablement
---

# Migrating from Service Detection v1 to v2 on OneAgent

If you run Kubernetes workloads monitored by OneAgent on a Latest Dynatrace tenant, Service Detection v2 changes how your services are modeled. It's a bigger shift than a version bump. It changes what a "service" is, how names propagate, and where per-endpoint or per-environment detail lives.

I put together a short presentation plus a set of live demos that run against your own tenant. The repo is here: [github.com/mreider/orders-demo](https://github.com/mreider/orders-demo). Landing page: [sdv2.mreider.com](https://sdv2.mreider.com).

## The shift in one sentence

Under SDv1, one Kubernetes workload fragments into multiple service entities — one per controller class, one per Kafka listener, plus an actuator entity — each with its own name, its own health, its own baselines. Under SDv2, one workload is one `UNIFIED` service entity with one `dt.service.name`, and the per-endpoint or per-queue detail moves onto first-class metric dimensions like `endpoint.name` and `messaging.destination.name`.

The bigger point: SDv1 multiplies entities for things that don't really exist as separate workloads. SDv2 keeps one entity and uses **metric families** and **transactions** to measure different aspects of its health on the same workload.

## Why it matters

- **One health signal per workload**, not four. Alerts, baselines, and dashboards scope to the thing you actually deploy.
- **Queries shorten**. Group by `endpoint.name` on one entity instead of joining across a handful of fragment entities.
- **Downstream dependencies move with the caller**. Databases, Kafka queues, third-party HTTP don't appear as separate entities. They're tabs on the calling service, rich with per-downstream dimensions.

## What the presentation covers

Two short sections, one unified demo notebook with ten DQL questions:

- **One workload, one service** — count `dt.service.name` and `dt.entity.service` values per workload, see SDv1's entity fragmentation and SDv2's `UNIFIED` collapse, watch `OTEL_SERVICE_NAME` act as a prefix on every SDv1 fragment.
- **Dimensions do the slicing** — the three metric families (`request`, `messaging.process`, `faas_invoke`) that roll up as the **Transactions** column, the legacy `request.*`-for-messaging double-count that disappears when SDv2 for OneAgent GAs in June 2026, `endpoint.name` with the `http.route` gap, downstreams as dimensions on the caller, and the metric-first DQL shift Christian flagged in review.

Demo notebook runs on your own Dynatrace data. No sample backend needed (unless you don't have a workload with the right shape, in which case there's a Spring Boot app in the repo that produces the necessary traffic).

## Try it

- Read the walkthrough: [github.com/mreider/orders-demo/tree/main/presentation](https://github.com/mreider/orders-demo/tree/main/presentation)
- Grab the slide deck from the latest release: [github.com/mreider/orders-demo/releases/latest](https://github.com/mreider/orders-demo/releases/latest)
- Load the demo notebooks into your tenant with the script in `scripts/load-demos.sh`. Requires dtctl 0.24 or later.

## A note on the "what's coming" section

Direction is firm: pipeline-side naming, SERVICE_DEPLOYMENT for per-environment views, automatic URL normalization for the `http.route` gap. Timing is less firm, so treat the roadmap section as shape-of-the-road, not an arrival date.

Feedback welcome. The repo accepts issues and PRs.
