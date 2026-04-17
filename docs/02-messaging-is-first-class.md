---
title: Rung 2 - Messaging is first-class
description: One new idea built on Rung 1. The @KafkaListener is a peer of HTTP endpoints, with its own baselines via dt.service.messaging.process.*
rung: 2
last_updated: 2026-04-17
---

# Rung 2: Messaging is first-class

Recap of Rung 1: endpoints are the unit of health. You no longer split
services to get per-feature visibility on HTTP endpoints.

## The new idea

> In SDv2, a Kafka consumer is a peer of an HTTP endpoint. It gets its
> own baselines via `dt.service.messaging.process.*`, with
> `messaging.destination.name` as a first-class dimension.

In SDv1, the `@KafkaListener` in this same JVM was invisible or
awkward. In SDv2, look at the same service and you see it sitting
next to the HTTP endpoints.

## Look at the `orders-demo` service in `orders-sdv2`

Open the **Endpoints** panel again. Alongside the three HTTP endpoints
from Rung 1, you should see:

- `order-events` (messaging)

That is the Kafka topic that the `@KafkaListener` consumes. It has:

- Its own throughput.
- Its own duration chart for message processing.
- Its own failure rate. The seeded 2% bad payloads show up here.
- Dimensions: `messaging.system = kafka`,
  `messaging.destination.name = order-events`.

None of this was configured. The listener is instrumented by OneAgent
and the metric family does the rest.

## Compare to `orders-sdv1`

On the SDv1 side, the Kafka consumer is harder to find. If it shows up at
all, it is usually either:

- Lumped into the service's request metrics because SDv1 mirrored
  `messaging.process` into `request.*` in some paths. Failure rates and
  latencies on the consumer are mixed with HTTP traffic.
- Floating as background activity with no baseline.

In SDv1 you would have needed a custom service or a request-attribute
rule to give the listener its own identity. You rarely did, because
the cost outweighed the value.

## The three metric families

In the Services app, pick any endpoint and notice the metric family
prefix in the chart's query. The family is the data model:

| Family | What goes here | Dimensions you can slice by |
|---|---|---|
| `dt.service.request.*` | HTTP, gRPC, RMI, web-tech | `http.route`, `http.response.status_code` |
| `dt.service.messaging.process.*` | Kafka, RabbitMQ, JMS consumers | `messaging.destination.name`, `messaging.system` |
| `dt.service.faas_invoke.*` | Lambda, Azure Functions, Cloud Functions | `faas.trigger` |

The UI coalesces the three under the umbrella term **Transactions** on
the service overview. You get one health number for the service AND
per-family drilldown. SDv1 had no clean way to do both.

This demo uses `request.*` and `messaging.process.*`. If you had a
Lambda running on the side, `faas_invoke.*` would join the picture
without a schema change.

## Failure unification (preview of Rung 4)

Notice `transaction.is_failed` as a span attribute on traces from both
the HTTP endpoints and the Kafka consumer. That is the unified failure
indicator. Rung 4 will return to this when we trace a bad order from
`/orders/submit` through the Kafka hop.

## What you now know

> Kafka consumers are peers of HTTP endpoints in SDv2. They share the
> Transactions umbrella at the service level and have their own metric
> family underneath. Async and event-driven code finally shows up in the
> same health model as HTTP.

Next: [Rung 3 - Namespace is a dimension](03-namespace-is-a-dimension.md).
