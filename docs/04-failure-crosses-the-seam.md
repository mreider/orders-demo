---
title: Rung 4 - Failure crosses the seam
description: One new idea built on Rungs 1-3. Failure analysis follows a transaction from HTTP through the Kafka hop to the consumer, as one continuous signal, via unified transaction.is_failed semantics.
rung: 4
last_updated: 2026-04-17
---

# Rung 4: Failure crosses the seam

Recap of Rungs 1-3: endpoints carry baselines, messaging is a peer of
HTTP, namespace is a dimension. Each rung was about a single service
identity in steady state.

This rung is about what happens when things break across the HTTP /
Kafka boundary.

## The new idea

> In SDv2, failure analysis follows a transaction across the
> HTTP-to-messaging seam. The unified `transaction.is_failed` attribute
> collapses HTTP failure, messaging failure, and downstream exception
> into one signal you can chart, alert on, and trace.

## Set up the observation

The load generator sends a small fraction of orders with a seeded
`bad: true` flag. The HTTP call to `POST /orders/submit` succeeds:
the order is persisted, a Kafka message is produced, and the caller
gets a 201. The **consumer** then reads the message, sees the bad
flag, and throws. The database rollback leaves the order in
`PENDING`. That is the seam.

## What you should see

In the **Services** app, under `orders-demo` in `orders-sdv2`:

1. Open the endpoint `POST /orders/submit`. Failure rate chart: likely
   flat at zero or near zero. The HTTP call itself succeeded.
2. Open the endpoint `order-events` (messaging). Failure rate chart:
   ~2%. The consumer rejected the bad payloads.
3. Click into a failed consumer invocation. In the trace view you
   should see:
   - The HTTP span on `POST /orders/submit` (from replica A).
   - The Kafka producer span on the same service.
   - The Kafka consumer span (possibly on replica B).
   - The Hibernate/JDBC spans against Postgres.
   - An exception span with the seeded `IllegalStateException`.

All in one trace. One continuous signal. No SDv1-era "two disconnected
services stitched with some correlation luck".

## Why this works

Three mechanisms stack:

- **One service identity.** Both the HTTP producer and the Kafka
  consumer are the same `orders-demo` service. The trace does not
  cross a service boundary; it crosses a transport (HTTP to Kafka to
  JDBC). Identity stays stable.
- **Unified `transaction.*` span attributes.** `transaction.is_failed`
  is the same attribute whether the failure is an HTTP 5xx, a Kafka
  consumer exception, or a database error. Charts, segments, and alerts
  that reference it are portable across families.
- **Context propagation through Kafka headers.** The producer writes
  W3C `traceparent` to the message headers. The consumer reads it and
  continues the trace. This is OneAgent / OpenTelemetry default
  behavior; no app code needed.

## Compare to `orders-sdv1`

On the SDv1 side, the comparable trace usually breaks. Typical failure
modes:

- The Kafka consumer appears on a different service (host-group split,
  or process-group variance) and the trace is not stitched.
- Failure analysis on the HTTP endpoint reports success (it was a 201)
  and the consumer exception shows up separately, with no obvious link
  back to the originating request.
- `request.is_failed` vs `messaging.is_failed` vs exception spans use
  different attributes. Alerts need to OR them together. Charts do
  not coalesce.

The viewer should literally see the SDv1 side show success on
`/orders/submit` while the SDv2 side surfaces the consumer failure in
the same trace. That contrast is the whole rung.

## Practical consequences

- **One alert can cover the seam.** Alert on
  `transaction.is_failed = true` filtered to
  `service.name = orders-demo` and you catch HTTP, messaging, and
  downstream failures in one rule.
- **Failure Analysis is not misled by the seam.** The response-time /
  failure-count correlations find the true root span because the trace
  is unbroken.
- **Refactors do not break this.** If you swap Kafka for RabbitMQ
  tomorrow, `transaction.is_failed` still works. The messaging family
  changes underneath.

## What you now know

> The HTTP-to-Kafka seam is no longer an observability boundary in
> SDv2. Failure is one unified signal across transports, because the
> service identity and the transaction semantics are stable across
> them.

## Where to go from here

You have walked the ladder:

1. Endpoints carry baselines.
2. Messaging is a peer of HTTP.
3. Namespace is a dimension.
4. Failure crosses the seam.

None of these required splitting rules, naming rules, key requests,
or custom services. That is the point.

Appendix topics we deliberately did not teach here (parked for when a
customer asks):

- `@Scheduled` and `@Async`: how SDv2 treats background Spring work.
- `faas_invoke.*` family: Lambda triggers, the third metric family.
- Webhook endpoints: distinct baselining for inbound third-party calls.
- `service.version` and release-stage as additional dimensions.
- Enhanced endpoints vs classic key requests in Phase 3 migration.
