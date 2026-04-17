---
title: Rung 3 - Kafka is a peer endpoint
description: The @KafkaListener is an endpoint of the UNIFIED service, not a separate entity. Messaging gets its own metric family but shares identity and transaction semantics.
rung: 3
last_updated: 2026-04-17
---

# Rung 3: Kafka is a peer endpoint

Recap of Rungs 1-2: one UNIFIED service per workload, and endpoints
carry baselines directly. So far we have mostly talked about HTTP.

## The new idea

> The `@KafkaListener` is an **endpoint** on the same UNIFIED service
> as the HTTP controllers. Not a separate service entity. Different
> metric family underneath, shared identity above.

## Compare the two sides

Under `orders-sdv1`, the Kafka consumer shows up as a **separate
service entity**: `OrderEventsListener` (type `MESSAGING_SERVICE`).
That entity has its own ID, its own entry in dashboards, its own
alerts. If you want to ask "how healthy is the Spring app overall",
you join it with the HTTP services yourself.

Under `orders-sdv2`, open `orders-sdv2 -- orders-demo` and scroll to
the Endpoints panel. `order-events` sits there alongside the HTTP
endpoints. One service. Two transports.

## What Kafka-as-endpoint gives you

Metric-family-wise, the consumer uses `dt.service.messaging.process.*`
with these dimensions:

- `messaging.system = kafka`
- `messaging.destination.name = order-events`
- `messaging.operation = process`

You can chart consumer health by topic without owning a service
entity per topic. Add a second `@KafkaListener` tomorrow and it
becomes another endpoint on the same UNIFIED service, not another
service entity to wire into every dashboard.

On the overview, the consumer throughput and failure rate are
**coalesced into the service's Transactions number** alongside the
HTTP endpoints. One service health view. Per-transport drilldown
underneath.

## The unified failure indicator (preview of Rung 4)

Notice `transaction.is_failed` as a span attribute on both HTTP
and messaging spans. SDv1 had separate indicators:
`request.is_failed` for HTTP, implicit for messaging. SDv2 unifies
them. Rung 4 uses this when we trace a bad order end to end.

## Counter-example from SDv1

Start at `OrderEventsListener` in the SDv1 side. Click around. You
will find:

- Its response-time and failure-rate charts are in the standalone
  service view, not in the `orders-demo` overview.
- Alerts filed on its failures do not share configuration with
  alerts on HTTP endpoints. A team that cares about end-to-end
  health maintains two sets.
- Failure analysis from an HTTP entry does not follow cleanly into
  it, because the service identity changes at the Kafka hop.

SDv2 removes the boundary. Same service. Different transport.
Consistent modeling.

## What you now know

> In SDv2 the `@KafkaListener` is an endpoint of the same service as
> the HTTP controllers. Messaging gets a dedicated metric family,
> but identity and transaction semantics are shared across
> transports. You stop managing the Kafka consumer as a separate
> thing to observe.

Next: [Rung 4 - Failure crosses the seam](04-failure-crosses-the-seam.md).
