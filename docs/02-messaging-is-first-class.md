---
title: Rung 2 - Endpoints are the unit of health
description: Now that the service collapsed, look inside. Endpoints are where per-feature health lives, and they are all baselined automatically.
rung: 2
last_updated: 2026-04-17
---

# Rung 2: Endpoints are the unit of health

Recap of Rung 1: the SDv1 fragmentation collapsed into one UNIFIED
service named `orders-sdv2 -- orders-demo`. No more per-controller
service entities.

The natural next question is: if I do not have separate services for
`OrderController` and `InventoryController` anymore, how do I measure
them separately? The answer is what this rung teaches.

## The new idea

> In SDv2, **endpoints** are the unit of per-feature health. Every
> endpoint the UNIFIED service exposes is detected and baselined
> automatically, with no key-request nomination required.

## Open the SDv2 service and click into Endpoints

Open `orders-sdv2 -- orders-demo`. The Endpoints panel should show,
over ~15 minutes of traffic:

- `POST /orders/submit`
- `GET /orders/search`
- `GET /inventory/check`
- `order-events` (Kafka consumer - covered in depth in Rung 3)

Each endpoint has:

- Its own response-time chart and baseline.
- Its own failure rate.
- Its own throughput.
- Its own dimensions (HTTP: `http.route`, `http.response.status_code`;
  messaging: `messaging.destination.name`, `messaging.system`).

None of this required a key-request nomination. You did not configure
any splitting rule. The endpoints are discovered from span attributes.

## Compare to the SDv1 side

Go back to `orders-demo - OrderController` in the `orders-sdv1`
namespace. The service-level chart averages every endpoint on that
controller. `POST /orders/submit` (strict envelope) and
`GET /orders/search` (loose envelope with a long tail) are mashed
together in one number. To tighten that, the customer would have
manually nominated each as a key request.

On the SDv2 side, those two endpoints have independent baselines
*and* the service-level chart coalesces them as **Transactions** for
the overview. You get both levels without choosing between them.

## The three metric families behind the scenes

Each endpoint's metrics live in one of three families:

| Family | Used by | Key dimensions |
|---|---|---|
| `dt.service.request.*` | `POST /orders/submit`, `GET /orders/search`, `GET /inventory/check` | `http.route`, `http.response.status_code` |
| `dt.service.messaging.process.*` | `order-events` Kafka consumer | `messaging.destination.name`, `messaging.system` |
| `dt.service.faas_invoke.*` | (not used here - Lambda triggers, etc.) | `faas.trigger` |

The Services app coalesces these under the umbrella term
**Transactions** on the service overview. So the UNIFIED service gets
one "how's it going" number and per-family drilldown simultaneously.

## What disappeared from the workflow

| SDv1 | SDv2 |
|---|---|
| Nominate key requests on each split service | Nothing. Endpoints are baselined. |
| Build dashboards per split service | Build one dashboard, filter by endpoint. |
| Maintain naming rules so charts read right | Endpoint names come from spans (HTTP route, messaging destination). |
| Rebuild when a controller is added | Endpoint appears, nothing to rebuild. |

The configuration did not move somewhere else. It is gone, because the
axis of health moved from "service" to "endpoint".

## What you now know

> Endpoints, not services, are the unit of per-feature health in SDv2.
> Every endpoint gets a baseline automatically, so the key-request
> mechanism of SDv1 is no longer necessary. The service stays one
> entity; the endpoints underneath are where feature-level signal
> lives.

Next: [Rung 3 - Kafka is a peer endpoint](03-namespace-is-a-dimension.md).
