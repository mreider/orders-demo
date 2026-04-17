---
title: Rung 1 - Optimally sliced SDv1 - entity is the unit
description: SDv1 done right. Enhanced endpoints on, per-controller entities stay, per-method endpoints surface. The unit of slicing is the entity.
rung: 1
last_updated: 2026-04-17
---

# Rung 1: Optimally sliced SDv1 - entity is the unit

SDv1 is not frozen. Turning on *enhanced endpoints for SDv1* takes the
default NON_KEY_REQUESTS collapse and replaces it with per-method
endpoint visibility. Existing key-request nominations are preserved as
named endpoints; new per-route detection comes for free for services
where the framework provides route information.

Enabled on this demo via the `builtin:enhanced-endpoints-for-sdv1`
settings schema, scoped to the `orders-sdv1`
CLOUD_APPLICATION_NAMESPACE.

## Historical fit

The entity-per-class model was designed for J2EE monoliths: one JVM
hosting many logically distinct services (EJB session beans, MDBs,
servlets, JAX-RS resources from multiple WARs), often owned by
different teams shipping under one EAR. For that shape, a
WEB_SERVICE per `@Controller` and a MESSAGING_SERVICE per
`@KafkaListener` surfaced genuinely separate services and earned
their own dashboards.

For a Spring Boot microservice - one JAR, one team, one deployment
unit - the same splits produce **faux entities** that fragment what
is already one service. Rung 1 walks SDv1 *optimally configured* -
the best version of the entity-per-class model. Whether that
configuration actually fits a Spring Boot workload is what Rung 2
takes up.

## What the entity surface looks like after

The entities themselves do not change. SDv1's controller-splitting
behavior still produces one WEB_SERVICE per `@Controller`. What
changes is the endpoint detail inside each entity.

| Entity | Serves | Endpoint detail |
|---|---|---|
| `orders-demo` (WEB_REQUEST_SERVICE) | Raw front of JVM | `GET /*` catch-all (for routes with no handler match) |
| `orders-demo - OrderController` (WEB_SERVICE) | Order API | `submit`, `search` - one endpoint per controller method |
| `orders-demo - InventoryController` (WEB_SERVICE) | Inventory API | `check` - one endpoint per controller method |
| `OrderEventsListener` (MESSAGING_SERVICE) | Kafka consumer | `NON_KEY_REQUESTS` still (enhanced endpoints applies to web-request services only) |

## How health is measured

Per-entity. Each WEB_SERVICE has its own response-time baseline,
failure rate, throughput, and alert rules. To answer "how healthy is
OrderController," you navigate to the OrderController entity and
read its charts.

Per-endpoint (inside each entity) too. Response time, failure rate,
throughput chart for each detected endpoint separately. Baselines
apply automatically once enhanced endpoints is on - no key-request
nomination needed.

## Naming note

Endpoint names on this tenant come through as controller-method
names (`submit`, `search`, `check`), not as `{HTTP-Method} {route}`.
This is because the Spring Boot app is not emitting `http.route` on
its server spans. On tenants where `http.route` is available,
enhanced endpoints produces `{POST} /orders/submit`-style names
instead. See the Rung 6 roadmap for URL normalization that closes
this gap.

## What a platform team configures on top

With enhanced endpoints on, the config burden shrinks but does not
disappear. Typical additions on a mature SDv1 install:

| Config surface | Still typical? |
|---|---|
| Service-naming rules | Yes - to rename `orders-demo - OrderController` to team-friendly names |
| Custom splitting rules | Sometimes - when default controller splitting is wrong |
| Key requests | Only for critical endpoints needing explicit baseline (deprecated in Phase 3) |
| Request naming rules | Yes - to bucket URL paths that lack `http.route` |
| Tagging rules | Yes - per team for SLO scoping |
| Host-group splits | Yes, multiplied by the number of environments |

## What you now know

> Optimally sliced SDv1 puts each controller in its own WEB_SERVICE
> entity and uses enhanced endpoints to get per-method detail inside
> each. The Kafka consumer stays its own MESSAGING_SERVICE entity.
> Health is measured per-entity first, then per-endpoint. The unit of
> slicing is the entity.

Next: [Rung 2 - Optimally sliced SDv2](02-optimal-sdv2.md).
