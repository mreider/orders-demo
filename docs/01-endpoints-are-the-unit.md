---
title: Rung 1 - Endpoints are the unit of health
description: One new idea built on the anchor. Endpoints carry baselines directly; you no longer manufacture services to get per-feature health.
rung: 1
last_updated: 2026-04-17
---

# Rung 1: Endpoints are the unit of health

Recap of the anchor: in SDv1 you manufactured services to get per-feature
health, because services were the only entity with baselines. That is the
cost you accepted.

## The new idea

> In SDv2, **endpoints** carry baselines directly. You no longer need a
> separate service entity per controller or per URL prefix.

Same Spring app, same image. Different namespace. Same traffic.

## Open the `orders-sdv2` namespace in Dynatrace

Under **Services**, filter to `orders-sdv2`. You should see:

- **One service**, named `orders-demo`. Not `orders-demo:8080`, not
  `orders-demo /orders`. Just `orders-demo`. The name comes from
  `k8s.workload.name`, which is the Deployment name.
- Two replicas. Those replicas do not fragment the service. The service is
  the deployment, not the process.
- An **Endpoints** panel with three entries:
  - `POST /orders/submit`
  - `GET /orders/search`
  - `GET /inventory/check`
- Click any of them. Each has its own baseline: response time, failure rate,
  throughput. No configuration. No key requests.

## Compare to `orders-sdv1`

Go back to the SDv1 namespace and look at `/orders/search`. You cannot
see its response-time baseline directly. The service-level baseline is an
average of `/orders/search` (often slow, with a long tail), `/orders/submit`
(tight envelope), and `/inventory/check` (very fast, very high volume).
The three latencies wash each other out. An SLO burn on `/orders/submit`
is invisible at the service level because `/inventory/check` dominates
the throughput.

On the SDv2 side, those three endpoints each have their own chart. The
`/orders/submit` baseline tightens. The `/orders/search` long tail shows
up as an independent signal, not smeared into the service average. The
`/inventory/check` volume no longer drowns anything out.

## The configuration you did not write

Count back to the anchor:

| Config you wrote in SDv1 | What SDv2 did instead |
|---|---|
| 3 service-detection rules to split the JVM | None. The JVM stays one service. |
| 3 to 5 naming rules | None. The workload name is the service name. |
| 5 to 10 key requests | None. All endpoints are baselined. |
| Ongoing maintenance when controllers are added | None. New endpoints show up automatically. |

The configuration is gone because the axis of health moved. Services are
not where health lives anymore. Endpoints are.

## What this unlocks

- A Spring team can now file alerts on `POST /orders/submit` latency
  without inventing a service for it.
- Adding a new controller adds new endpoints. No splitting rule to update.
- The service entity stays stable across refactors. Endpoints churn,
  service identity does not.

## What you now know

> Endpoints are the unit of per-feature health. Services are a higher-level
> identity that stays stable across endpoint churn. This inverts the SDv1
> relationship.

Next: [Rung 2 - Messaging is first-class](02-messaging-is-first-class.md).
