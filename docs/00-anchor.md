---
title: Anchor - What SDv1 actually shows you
description: Ground truth before any new ideas. What the tenant shows for orders-sdv1 and why it is the way it is.
rung: 0
last_updated: 2026-04-17
---

# Anchor: What SDv1 actually shows you

Before we introduce anything new, look at what the Dynatrace tenant shows
for the `orders-sdv1` namespace. This is what a typical Spring shop sees
on default SDv1 detection, before any custom rules have been added.

## Open `Services` and filter to the `orders-sdv1` namespace

You will see **multiple services**, not one. Something like:

| Service name | Entity type | Why it exists |
|---|---|---|
| `orders-demo` | WEB_REQUEST_SERVICE | The "raw" request service sitting at the web front of the JVM |
| `orders-demo - OrderController` | WEB_SERVICE | Produced by default web-request-service splitting on `@Controller` class name |
| `orders-demo - InventoryController` | WEB_SERVICE | Same rule, different controller |
| `OrderEventsListener` | MESSAGING_SERVICE | Kafka consumer detected automatically |

This is SDv1's default behavior on OneAgent. No custom rules were
written. The built-in detection shipped multi-service splitting out of
the box.

## Why this looks busy

Each `WEB_SERVICE` is a separate entity. Each has:

- Its own response-time chart, baseline, and failure rate.
- Its own key-request settings, alerts, and dashboards.
- Its own service ID, which changes if the detection rules change.

The `MESSAGING_SERVICE` for the Kafka consumer lives next to the
HTTP services but uses different metric attributes
(`messaging.destination.name`, etc.) and follows a different metric
family. HTTP endpoints and Kafka endpoints do not share a common
"transaction" view at the service level.

## What a typical Spring team does on top of this

Customers rarely stop at the default behavior. Typical additions:

1. **Service-naming rules** to rename `orders-demo - OrderController`
   into something the team agrees on (e.g., `orders-api`).
2. **Custom splitting rules** when the defaults coalesce controllers
   the team wants separate, or keep separate what they want coalesced.
3. **Key requests** on each split service so important endpoints get
   per-request baselines instead of service-averaged ones.
4. **Tagging rules** so downstream SLOs and Davis can target the right
   subset of services per team.

For a three-controller Spring app with two Kafka listeners, a full
SDv1 ruleset commonly adds:

| Config surface | Typical count |
|---|---|
| Service-naming rules | 3 to 5 |
| Custom splitting rules | 0 to 3 |
| Key requests | 5 to 10 |
| Tagging rules | 1 to 3 per team |
| Host-group splits if multi-env | x the number of environments |

All of this is load-bearing. None of it is visible from the app code.

## Count what SDv1 already does for you, even without rules

The default behavior is already split-happy:

- Every class annotated `@Controller` or `@RestController` produces a
  separate `WEB_SERVICE` entity.
- Every `@KafkaListener` produces a separate `MESSAGING_SERVICE` entity.
- Each deployment namespace creates its own copies of those services
  (you see `orders-demo - InventoryController` independently in
  `orders-sdv1` and `orders-sdv2`, tied to different
  `CLOUD_APPLICATION_NAMESPACE` entities).

So the JVM you deployed as a single Deployment shows up as **several
service entities**. That is the baseline customers carry into every
observability decision.

## What you now know

> Default SDv1 detection fragments a single JVM into multiple service
> entities. Each controller is a separate service, each Kafka listener
> is a separate service, and deployment to a second namespace
> multiplies everything. Custom rules extend this model, they do not
> replace it.

The SDv2 side of the demo teaches a sequence of ideas about how that
fragmentation collapses under the new detection model. Four rungs,
one new idea each.

Next: [Rung 1 - One unified service identity](01-one-unified-service.md).
