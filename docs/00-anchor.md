---
title: Rung 0 - What default SDv1 shows you
description: Ground truth before anything is configured. Multiple entities per JVM and NON_KEY_REQUESTS inside each.
rung: 0
last_updated: 2026-04-17
---

# Rung 0: What default SDv1 shows you

Before we teach anything, look at what a fresh SDv1 install shows for a
three-controller Spring Boot app with a Kafka consumer. No detection
rules have been written, no key requests nominated, no naming rules
applied. This is what a typical Spring shop carries into every
observability decision.

## Entities produced from one JVM

| Service name | Entity type | Why it exists |
|---|---|---|
| `orders-demo` | WEB_REQUEST_SERVICE | The raw request service at the web front of the JVM |
| `orders-demo - OrderController` | WEB_SERVICE | Default web-request-service splitting on the controller class |
| `orders-demo - InventoryController` | WEB_SERVICE | Same rule, different controller |
| `OrderEventsListener` | MESSAGING_SERVICE | Kafka consumer detected automatically |

Four entities from one deployment. Each has its own ID, dashboards,
alerts, and configuration surface. Deploy the same workload to a
second namespace and the count doubles.

## These are not four independent services

One team owns the whole Spring Boot JAR. Not separate controllers.
What SDv1 exposes as four entities are really four *faux entities*
representing fragments of one deployed workload.

The splitting model comes from an earlier era. J2EE monoliths on
WebSphere and WebLogic genuinely hosted many logically distinct
services in one JVM: EJB session beans, message-driven beans,
servlets and JAX-RS resources from multiple WARs, often owned by
different teams shipping under a single EAR. Splitting by class
surfaced those real separations as observable entities. For that
shape, the model fit.

For a Spring Boot microservice - one runnable JAR, one team, one
deployment unit - the same splits fragment what is already one
service. Teams end up rebuilding dashboards to aggregate the faux
entities back together.

## What endpoint-level visibility looks like

Inside each WEB_SERVICE, individual routes are invisible until
somebody nominates them as key requests. All traffic is collapsed
under a single `NON_KEY_REQUESTS` bucket.

Inside the MESSAGING_SERVICE, the Kafka consumer metrics roll up
under `NON_KEY_REQUESTS` too. No per-destination breakdown.

## Why this is the starting point for teaching

The next two rungs show the two ways to break past this default.
Rung 1 takes SDv1 as far as it can go with *enhanced endpoints* and
the tools SDv1 gives you for per-route visibility. Rung 2 shows how
SDv2 gets there from a completely different direction.

Both are valid. Which you choose depends on which detection model the
workload lives under. The rest of the ladder compares them, rung by
rung, on the same questions a platform team actually asks.

Next: [Rung 1 - Optimally sliced SDv1](01-optimal-sdv1.md).
