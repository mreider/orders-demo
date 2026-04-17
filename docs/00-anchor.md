---
title: Anchor - What SDv1 asks of you
description: Ground truth before any new ideas. What the viewer already knows and the hidden cost of that knowledge.
rung: 0
last_updated: 2026-04-17
---

# Anchor: What SDv1 asks of you

This is the starting rung. Before we introduce anything new, look at the
SDv1 side of the demo and notice what you had to build to get it useful.

## Open the `orders-sdv1` namespace in Dynatrace

Under **Services**, filter to the `orders-sdv1` namespace. You should see
something like this, straight out of the default detection:

- **One service**, named after the Tomcat process plus port. Something like
  `orders-demo:8080` or `orders-demo (orders-sdv1)`.
- Its response-time chart averages everything that hits the Spring app:
  `/orders/submit`, `/orders/search`, `/inventory/check`, all lumped together.
- No visible per-endpoint baselines. No visible Kafka consumer.
- Failure rate is a single number across the whole app.

## What you would have built to make this useful

If this were your production Spring monolith, the defaults above are not
what you want. The Spring team wants to see `/orders/submit` separately
from `/inventory/check`, because those endpoints have different SLOs and
different failure profiles. To get there in SDv1, you would have:

1. **Written service-detection rules** to split the JVM into multiple
   services. Classic pattern: one rule per controller or per URL prefix.
   Output: `OrderService`, `InventoryService`, maybe `PaymentService`,
   each a separate entity.

2. **Configured naming rules** so the split services had readable names
   instead of `orders-demo:8080 /orders`. That means at least one naming
   rule per split service, often more.

3. **Nominated key requests** on each split service so the endpoints that
   matter got per-request baselines. Nominated manually, one at a time.

4. **Accepted entity churn.** Whenever the rules changed, service IDs
   changed. Dashboards, alerts, and Davis comments broke. You learned to
   change rules rarely.

5. **Lost the Kafka consumer.** The `@KafkaListener` in the same JVM did
   not show up as a first-class citizen. It either appeared as
   "background activity" on whichever split service happened to own the
   thread, or was invisible.

## Count the configuration

For a three-controller Spring app with two Kafka listeners:

| Config surface | Count |
|---|---|
| Service-detection rules | 3 |
| Naming rules | 3 to 5 |
| Key requests | 5 to 10 (the endpoints that matter) |
| Custom service entities (for anything not on a controller) | 0 or 1 |
| Host-group splits if you run in multiple environments | x2, x3 |

Real customers carry more than this. A single team's Spring estate can
accumulate dozens of splitting rules, hundreds of naming rules, and
thousands of key requests across many services. All of it load-bearing.
None of it visible from the app code.

## What you now know

> In SDv1, the **service** is the only entity with baselines and dashboards
> attached. Every time you want per-feature health, you have to manufacture
> a service. That manufacture is what the configuration above is for.

This is the anchor. The SDv2 side of the demo teaches a sequence of
ideas that make most of this configuration unnecessary. Four rungs, one
new idea per rung.

Next: [Rung 1 - Endpoints are the unit of health](01-endpoints-are-the-unit.md).
