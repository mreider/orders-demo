---
title: Rung 4 - Measuring messaging health both ways
description: Same question applied to Kafka. SDv1 treats the consumer as its own entity. SDv2 treats the consumer as a peer endpoint on the same service - with a roadmap to move it to a dedicated messaging tab.
rung: 4
last_updated: 2026-04-17
---

# Rung 4: Measuring messaging health both ways

Rung 3 compared HTTP health. Now apply the same comparison to the
Kafka consumer side of the application.

## Question 1: What is the throughput of the `order-events` Kafka consumer?

**SDv1 idiom (separate entity):**

On SDv1 the `@KafkaListener` is detected as its own
MESSAGING_SERVICE, named after the listener class. To read its
health, navigate to that entity.

```dql
timeseries cnt = sum(dt.service.messaging.process.count),
  by: { dt.entity.service, messaging.destination.name },
  from: now()-30m
| lookup [fetch dt.entity.service | fields id, entity.name, serviceType],
    sourceField: dt.entity.service, lookupField: id, prefix: "svc."
| filter svc.entity.name == "OrderEventsListener"
    AND svc.serviceType == "MESSAGING_SERVICE"
| fields messaging.destination.name, cnt
```

Different entity, different view, different baseline, different
alerts from the HTTP side.

**SDv2 idiom (peer endpoint on the same service):**

On the UNIFIED service, messaging consumption shows up alongside HTTP
in two places: as an endpoint in `dt.service.request.*`-style queries
(named `{destination} process`), and as its own first-class metric
family `dt.service.messaging.process.*` with richer dimensions.

```dql
timeseries cnt = sum(dt.service.messaging.process.count),
  by: { dt.entity.service, messaging.destination.name, messaging.system },
  from: now()-30m
| lookup [fetch dt.entity.service | fields id, entity.name],
    sourceField: dt.entity.service, lookupField: id, prefix: "svc."
| filter svc.entity.name == "orders-sdv2 -- orders-demo"
| fields messaging.destination.name, messaging.system, cnt
```

One identity, filter on the destination dimension.

## Question 2: What is the failure rate on `order-events`?

**SDv1 idiom:**

```dql
timeseries {
  cnt = sum(dt.service.messaging.process.count),
  failed = sum(dt.service.messaging.process.failure_count)
},
  by: { dt.entity.service, messaging.destination.name },
  from: now()-30m
| lookup [fetch dt.entity.service | fields id, entity.name],
    sourceField: dt.entity.service, lookupField: id, prefix: "svc."
| filter svc.entity.name == "OrderEventsListener"
| fieldsAdd failure_rate = failed[] / cnt[]
| fields messaging.destination.name, cnt, failed, failure_rate
```

**SDv2 idiom:**

```dql
timeseries {
  cnt = sum(dt.service.messaging.process.count),
  failed = sum(dt.service.messaging.process.failure_count)
},
  by: { dt.entity.service, messaging.destination.name },
  from: now()-30m
| lookup [fetch dt.entity.service | fields id, entity.name],
    sourceField: dt.entity.service, lookupField: id, prefix: "svc."
| filter svc.entity.name == "orders-sdv2 -- orders-demo"
| fieldsAdd failure_rate = failed[] / cnt[]
| fields messaging.destination.name, cnt, failed, failure_rate
```

Same metric family, same dimension, same arithmetic. The filter
clause shifts from "entity name equals OrderEventsListener" to "entity
name equals the one UNIFIED service."

## Question 3: Is the system's overall messaging load balanced across destinations?

Imagine the app grows and adds a second `@KafkaListener` for a
`notifications` topic.

**SDv1 idiom**: Adding a second listener produces a second
MESSAGING_SERVICE entity (say, `NotificationListener`). Dashboards
and alerts that were scoped to `OrderEventsListener` do not
automatically cover the new entity. Manual wire-up per entity.

**SDv2 idiom**: The new listener adds one more endpoint to the
UNIFIED service. The same query above now returns two rows, one per
destination. No dashboard or alert rewire required.

```dql
timeseries cnt = sum(dt.service.messaging.process.count),
  by: { dt.entity.service, messaging.destination.name },
  from: now()-30m
| lookup [fetch dt.entity.service | fields id, entity.name],
    sourceField: dt.entity.service, lookupField: id, prefix: "svc."
| filter svc.entity.name == "orders-sdv2 -- orders-demo"
| sort cnt desc
```

## Roadmap note: consumer spans leaving the endpoint surface

Today, SDv2 exposes the Kafka consumer as a peer endpoint of the
UNIFIED service. That is what the `endpoint.name` "order-events
process" reflects. The product direction is to **remove consumer-span
endpoint detection for SDv2** (new tenants first). Rationale: message
consumption metrics already live in their own family
(`dt.service.messaging.process.*`) with richer dimensions, and
surfacing them as endpoints mixes messaging data into HTTP
response-time baselines. Removing consumer spans from endpoint
detection gives cleaner, more meaningful endpoint data.

After that change ships, the messaging health queries above will
still work unchanged, because they already use the messaging metric
family. Only the `dt.service.request.*` endpoint-named view goes
away.

See [Rung 6 - Where this is going](06-roadmap.md) for the full
direction.

## What you now know

> On SDv1, messaging health lives on a separate MESSAGING_SERVICE
> entity per `@KafkaListener`. On SDv2, it lives on the same UNIFIED
> service as HTTP, sliced by the `messaging.destination.name`
> dimension. The arithmetic is the same; the scope boundary moves
> from entity to attribute - just like the HTTP case in Rung 3.

Next: [Rung 5 - Measuring end-to-end failure](05-end-to-end-failure.md).
