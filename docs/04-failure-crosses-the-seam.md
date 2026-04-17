---
title: Rung 4 - Failure crosses the seam
description: Failure analysis follows a transaction across the HTTP-to-Kafka boundary as one continuous signal, because both sides share identity under SDv2.
rung: 4
last_updated: 2026-04-17
---

# Rung 4: Failure crosses the seam

Recap of Rungs 1-3: one UNIFIED service per workload, endpoints are
the unit of health, and Kafka is a peer endpoint alongside HTTP.

Each rung so far described a single service in steady state. This
rung is about what happens when things break across the
HTTP-to-Kafka boundary.

## The new idea

> In SDv2, failure analysis follows a transaction across the
> HTTP-to-messaging seam. The unified `transaction.is_failed`
> attribute collapses HTTP failure, messaging failure, and
> downstream exceptions into one signal, chartable and alertable.

## How the demo exercises this

The load generator sends 2% of `POST /orders/submit` requests with a
seeded `bad: true` flag. The HTTP handler:

1. Persists the order with status `PENDING`.
2. Produces a Kafka message to `order-events` with the bad flag
   passed through.
3. Returns 201 to the caller.

The `@KafkaListener` then:

1. Consumes the message.
2. Sees `bad: true` and throws `IllegalStateException`.
3. The `@Transactional` rollback leaves the order in `PENDING`.

The HTTP call succeeded. The Kafka consumption failed. That is the
seam.

## What you should see in the SDv2 side

On `orders-sdv2 -- orders-demo`:

1. **Endpoint `POST /orders/submit`** - failure rate flat at or near
   zero. The HTTP calls all succeeded.
2. **Endpoint `order-events`** - failure rate ~2%. The consumer
   rejected the seeded bad payloads.
3. **Click into a failed consumer invocation** in the trace view.
   You should see a single trace with:
   - HTTP span on `POST /orders/submit` (from pod A).
   - Kafka producer span on the same service.
   - Kafka consumer span (possibly on pod B).
   - Hibernate / JDBC spans on Postgres.
   - Exception span carrying the seeded `IllegalStateException`.

All attached to one service identity. `transaction.is_failed = true`
on the consumer span and the exception span; `false` on the HTTP
span. One unified trace, three different truths about success.

## Why this works

Three mechanisms stack:

- **Shared identity.** Producer and consumer are the same
  UNIFIED service. The trace crosses transports (HTTP to Kafka to
  JDBC) but does not cross a service boundary.
- **Unified `transaction.*` span attributes.**
  `transaction.is_failed`, `transaction.is_root_span`, and the
  workload-type discriminators
  (`transaction.is_endpoint_request`, `transaction.is_message_processing`,
  etc.) are the same attribute family for HTTP, messaging, and FaaS.
  Alerts and charts that reference them are portable across
  transports.
- **Kafka header context propagation.** The producer writes W3C
  `traceparent` to Kafka headers. The consumer reads it and
  continues the trace. OneAgent does this automatically; no app
  code needed.

## Compare to `orders-sdv1`

On the SDv1 side, the same load pattern breaks observability at the
Kafka hop:

- `orders-demo - OrderController` reports success on `POST /orders/submit`.
  (Correct.)
- `OrderEventsListener` reports ~2% failure rate. (Also correct.)
- **But the two are different service entities.** Failure analysis
  from the HTTP entry does not reach the consumer automatically.
  The trace may be stitched through W3C context, but the *service*
  narrative splits.
- Alerting needs two rules. Dashboards show two charts.
- Davis correlates less well because the entities on both sides of
  the seam do not share identity.

SDv2 removes the seam. Identity is shared. Failure analysis runs
end-to-end.

## Practical consequences

- **One alert covers the full transaction.** Alert on
  `transaction.is_failed = true` filtered to
  `service.name = orders-sdv2 -- orders-demo` and you catch HTTP,
  messaging, and downstream failures in one rule.
- **Failure Analysis identifies the true root.** Because the trace
  is unbroken and identity is stable, the root span identified is
  the actual failure (the consumer exception), not the last span
  before a service boundary.
- **Transport swaps are cheap.** Swap Kafka for RabbitMQ and
  `transaction.is_failed` still works. The metric family changes
  underneath; the failure model does not.

## What you now know

> The HTTP-to-Kafka seam is no longer an observability boundary in
> SDv2. Service identity is shared across transports, the
> `transaction.*` attributes unify failure semantics, and OneAgent
> propagates context through Kafka headers automatically. You
> observe the whole flow as one.

## Where to go from here

You have walked the ladder:

1. One UNIFIED service identity per workload.
2. Endpoints carry baselines.
3. Kafka is a peer endpoint.
4. Failure crosses the seam.

None of this required splitting rules, naming rules, key requests,
or custom service entities for the messaging side. That is the
point.

See [05-roadmap.md](05-roadmap.md) for where SDv2 is headed after
preview (splitting-rule deprecation, SERVICE_DEPLOYMENT,
dimensional slicing).
