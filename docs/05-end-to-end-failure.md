---
title: Rung 5 - Measuring end-to-end failure
description: Failure analysis across the HTTP-to-Kafka seam. SDv1 correlates across two entities. SDv2 uses one unified failure indicator. Trace continuity is the shared foundation.
rung: 5
last_updated: 2026-04-17
---

# Rung 5: Measuring end-to-end failure

The load generator seeds 2% of `POST /orders/submit` requests with
`bad: true`. The HTTP handler succeeds (it persists the order and
returns 201). The Kafka consumer reads the message, sees the flag,
throws `IllegalStateException`, and the `@Transactional` rollback
leaves the order `PENDING`.

HTTP succeeded. Messaging failed. Same transaction. This is the seam.

## Shared foundation: trace continuity works on both

Before the comparison: trace continuity is independent of detection
model. OneAgent writes W3C `traceparent` to Kafka message headers on
produce, and the consumer reads it on receive. The trace is
unbroken on both SDv1 and SDv2 - HTTP span, Kafka producer span,
Kafka consumer span, JDBC spans, exception span, all in one trace.

Trace view works equivalently on both sides. What differs is
**service-identity continuity** and therefore how failure is
aggregated into metrics and alerts.

## Question 1: Is the HTTP entry point failing?

**SDv1 idiom:**

```dql
timeseries {
  cnt = sum(dt.service.request.count),
  failed = sum(dt.service.request.failure_count)
},
  by: { dt.entity.service, endpoint.name },
  from: now()-30m
| lookup [fetch dt.entity.service | fields id, entity.name],
    sourceField: dt.entity.service, lookupField: id, prefix: "svc."
| filter svc.entity.name == "orders-demo - OrderController"
    AND endpoint.name == "submit"
| fields endpoint.name, cnt, failed
```

Expected: `submit` shows near-zero failure rate. The HTTP call
succeeded - it persisted the order and returned 201.

**SDv2 idiom:** same arithmetic on `OrderController.submit` of the
UNIFIED service. Same answer.

## Question 2: Is the Kafka consumer failing?

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
| fields messaging.destination.name, cnt, failed
```

Expected: `order-events` shows the failure pulse from the seeded bad
messages.

**SDv2 idiom:** same metric family filtered to the UNIFIED service.
Same pulse, surfaced against the same service identity as the HTTP
side.

## Question 3: Is the system's transaction flow healthy end-to-end?

This is where the detection models diverge sharply.

**SDv1 idiom: correlate across entities.**

To answer "is the HTTP->Kafka flow failing," a platform team reads
failure counts from two separate entities (`orders-demo -
OrderController` and `OrderEventsListener`) and joins them
conceptually. An alert that fires "when the HTTP-to-Kafka flow has
trouble" needs two alert rules, one per entity, and a correlation
scheme between them.

```dql
// Two queries, merged in user's head:
timeseries http_failed = sum(dt.service.request.failure_count),
  by: { dt.entity.service }, from: now()-30m
| lookup [fetch dt.entity.service | fields id, entity.name],
    sourceField: dt.entity.service, lookupField: id, prefix: "svc."
| filter svc.entity.name == "orders-demo - OrderController"
| fields svc.entity.name, http_failed
```
```dql
timeseries msg_failed = sum(dt.service.messaging.process.failure_count),
  by: { dt.entity.service }, from: now()-30m
| lookup [fetch dt.entity.service | fields id, entity.name],
    sourceField: dt.entity.service, lookupField: id, prefix: "svc."
| filter svc.entity.name == "OrderEventsListener"
| fields svc.entity.name, msg_failed
```

**SDv2 idiom: one alert on one identity.**

One service owns both the HTTP side and the messaging side. Summing
failures across families on the UNIFIED service gives the
transaction-level failure count directly.

```dql
timeseries {
  http_failed = sum(dt.service.request.failure_count),
  msg_failed = sum(dt.service.messaging.process.failure_count)
},
  by: { dt.entity.service },
  from: now()-30m
| lookup [fetch dt.entity.service | fields id, entity.name],
    sourceField: dt.entity.service, lookupField: id, prefix: "svc."
| filter svc.entity.name == "orders-sdv2 -- orders-demo"
| fieldsAdd total_failed = http_failed[] + msg_failed[]
| fields total_failed, http_failed, msg_failed
```

Alert on `total_failed > 0`. One rule. Covers HTTP, messaging, and
anything else that produces a failure count on this service.

## The unifying span attribute

At the span level, SDv2 also provides `transaction.is_failed` as a
unified indicator across all transaction types - HTTP, messaging,
FaaS. This span attribute deprecates the older per-transport flags
(`request.is_failed`, `messaging.is_failed`). Dashboards and Davis
correlations that key off `transaction.is_failed` work identically
for any transport.

```dql
fetch spans, from: now()-30m
| filter isSet(transaction.is_failed) AND transaction.is_failed == true
| filter k8s.namespace.name == "orders-sdv2"
| summarize cnt = count(), by: { endpoint.name }
| sort cnt desc
```

## What you now know

> Trace continuity is a shared foundation - W3C headers carry context
> across Kafka on both SDv1 and SDv2. Where the models diverge is
> entity boundary. SDv1 puts the HTTP and messaging sides of the same
> flow in different entities, so end-to-end failure analysis means
> correlating across entities. SDv2 keeps one identity across the
> seam, so end-to-end failure is a sum of failure counts on one
> service - or a single filter on the unified `transaction.is_failed`
> span attribute.

Next: [Rung 6 - Where this is going](06-roadmap.md).
