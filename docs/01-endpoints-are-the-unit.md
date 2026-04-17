---
title: Rung 1 - One unified service identity
description: The first thing SDv2 changes - several SDv1 service entities collapse into one UNIFIED service per (namespace, workload). Anchored on stable k8s resource attributes.
rung: 1
last_updated: 2026-04-17
---

# Rung 1: One unified service identity

Recap of the anchor: in SDv1, the `orders-sdv1` namespace shows several
service entities (a WEB_REQUEST_SERVICE, one WEB_SERVICE per controller,
a separate MESSAGING_SERVICE for the Kafka listener). All from one JVM.

## The new idea

> In SDv2, those fragments collapse into **one UNIFIED service** per
> (namespace, workload). The service identity is derived from k8s
> resource attributes, not from process-group fingerprint.

## Open the `orders-sdv2` namespace in Dynatrace

Filter **Services** to the `orders-sdv2` namespace. You should see
one service:

- **Name:** `orders-sdv2 -- orders-demo`
- **Type:** `UNIFIED` (new entity type introduced with SDv2)
- **Detection:** OneAgent + SDv2

The name is produced by the built-in SDv2 detection rule
`{k8s.namespace.name} -- {k8s.workload.name}`, and identity is tied to
`k8s.cluster.uid`, `k8s.namespace.name`, and `k8s.workload.name`.

Because the built-in rule `[Built-in] Split services by k8s cluster and
namespace` is still enabled in the preview, deploying the same
workload to a second namespace produces a **second** UNIFIED service
(that is what Rung 3 is about). A single namespace still produces a
single service.

## Count what collapsed

| SDv1 side in `orders-sdv1` | SDv2 side in `orders-sdv2` |
|---|---|
| `orders-demo` (WEB_REQUEST_SERVICE) | `orders-sdv2 -- orders-demo` (UNIFIED) |
| `orders-demo - OrderController` (WEB_SERVICE) | (folded in) |
| `orders-demo - InventoryController` (WEB_SERVICE) | (folded in) |
| `OrderEventsListener` (MESSAGING_SERVICE) | (folded in) |

Four entities became one. The HTTP controllers are no longer separate
services. The Kafka consumer is no longer a separate service. All of
them now sit under the single UNIFIED entity and are surfaced as
**endpoints** of that service (the subject of Rung 2).

## Why this changes how you think

The anchor chapter listed five to ten key-request nominations per split
service. On the SDv2 side there are no split services to nominate key
requests on. The service is the deployment; per-feature health lives
elsewhere.

Two practical consequences visible immediately:

- **Service count goes down.** A Spring monolith that produced six
  SDv1 services produces one SDv2 service per namespace. Multiply by
  the number of Spring workloads in a cluster and the reduction in
  entity count is often 5-10x.
- **Identity stays stable across refactors.** Adding a new
  `@RestController` adds a new endpoint on the same service. Under
  SDv1, it added a new WEB_SERVICE entity and possibly invalidated
  existing dashboards.

## What you do not see yet

Do not read too much into service-level charts on the SDv2 side until
at least 15 minutes of traffic has accumulated. Baselines need time
to form, and the endpoint surface (Rung 2) is worth a separate look.

## What you now know

> Under SDv2, a single Spring JVM deployed to a namespace is
> represented as one UNIFIED service. Controllers and Kafka listeners
> that used to be separate services are now folded in as endpoints
> of that service. Identity is k8s-native and stable.

Next: [Rung 2 - Endpoints are the unit of health](02-messaging-is-first-class.md).
