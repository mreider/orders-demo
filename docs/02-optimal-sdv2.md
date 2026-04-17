---
title: Rung 2 - Optimally sliced SDv2 - attribute is the unit
description: SDv2 done right. One UNIFIED identity per workload. Every endpoint auto-detected. Health is measured per attribute on one service.
rung: 2
last_updated: 2026-04-17
---

# Rung 2: Optimally sliced SDv2 - attribute is the unit

Same Spring Boot app, deployed to the `orders-sdv2` namespace with SDv2
enabled. No configuration. No key-request nominations. No naming rules.
No enhanced-endpoints opt-in (SDv2 has no such concept; endpoints are
native).

## Right-sizing identity

SDv2 aligns service identity with the modern deployment unit. In
Kubernetes that is the workload (Deployment, StatefulSet). In Lambda
it is the function. In ECS it is the task. One runnable unit, one
team, one service. Controllers and listeners inside that unit are
*internal organization* of one service, not separate services - and
SDv2 expresses that structurally: one entity per workload, with
controllers and destinations as dimension values.

This is the structural correction for the faux-entity problem Rung 0
described. Under SDv1, splits produce multiple entities from a
workload that is conceptually one service. Under SDv2, the entity is
the workload; the former split axes become dimensions.

## What the entity surface looks like

One row:

| Entity name | Type | Detection attributes |
|---|---|---|
| `orders-sdv2 -- orders-demo` | UNIFIED | `k8s.namespace.name`, `k8s.workload.name`, `k8s.cluster.uid` |

Identity is derived from k8s resource attributes, not from process
group fingerprint. The four SDv1 entities for this workload
(WEB_REQUEST_SERVICE + two WEB_SERVICE + MESSAGING_SERVICE) collapse
into one UNIFIED entity.

## Endpoints, without configuration

Inside the one UNIFIED service, endpoints are detected from span
attributes. For this workload:

| Endpoint | Source attribute | Traffic share |
|---|---|---|
| `OrderController.submit` | OneAgent Java sensor, assembled from `code.namespace` + `code.function` on the servlet-filter span | ~300/min |
| `OrderController.search` | OneAgent Java sensor, same path | ~1.5k/min |
| `InventoryController.check` | OneAgent Java sensor, same path | ~4.3k/min |
| `order-events process` | Kafka consumer span (messaging.destination.name + messaging.operation) | ~370/min |
| `GET /*` | HTTP catch-all (unmatched routes like `/actuator/health`) | ~36/min |

Kafka peer endpoint is visible today. Roadmap direction (Rung 6) is
to move it to a dedicated messaging tab.

**Why class-method names and not `{HTTP-Method} /route`?** `http.route`
is present on every server span in this demo (`/orders/submit`,
`/orders/search`, `/inventory/check`). SDv2 also ships a unified
endpoint-detection ruleset (`builtin:unified-request-name-ruleset`)
whose `http.route` rule would name endpoints `GET /orders/search` etc.
But OneAgent's Java sensor captures two server spans per request - an
outer servlet-filter span and an inner controller span - and assembles
the `{class}.{method}` endpoint name from the inner span's
`code.namespace` + `code.function`, writing it onto the outer span as
`endpoint.name` *at capture time*. The ruleset only applies to spans
that arrive without a pre-set `endpoint.name` (raw OTel-SDK path). So
on OneAgent-monitored Java workloads, class-method naming is
effectively the SDv2 default.

## How health is measured

Per attribute on one identity. To answer "how healthy is
OrderController," you filter the UNIFIED service by
`startsWith(endpoint.name, "OrderController.")`. To answer "how
healthy is the Kafka consumer," you filter by
`messaging.destination.name == "order-events"` against the
`dt.service.messaging.process.*` family.

There is one baseline per endpoint, one failure rate per
`http.response.status_code`, one throughput per dimension slice you
pick. Because identity is one, you compose dimensions to answer
questions, instead of navigating between entities.

## The three metric families

SDv2 uses three dedicated metric families. Each carries dimensions fit
for its workload type. All attach to the one UNIFIED service.

| Family | Covers | Key dimensions |
|---|---|---|
| `dt.service.request.*` | HTTP, gRPC, RMI entry points | `endpoint.name`, `http.response.status_code`, `http.route` |
| `dt.service.messaging.process.*` | Message consumption | `messaging.destination.name`, `messaging.system`, `messaging.operation` |
| `dt.service.faas_invoke.*` | FaaS triggers | `faas.trigger` (not used in this demo) |

The Services app overview coalesces these under **Transactions** - one
number for service-level health, drilldowns for per-family detail.

## What disappears from the workflow

| SDv1 | SDv2 |
|---|---|
| Nominate key requests on each split service | Endpoints baselined by default |
| Build dashboards per split service | One service, filter by dimension |
| Maintain naming rules to get readable charts | Endpoint names come from span attributes |
| Rebuild when a new controller is added | New endpoint appears automatically |
| Manage a separate MESSAGING_SERVICE for every `@KafkaListener` | One service, messaging endpoints alongside HTTP |

## What you now know

> Optimally sliced SDv2 is one UNIFIED service identity per workload,
> with endpoints and messaging destinations surfacing as dimensions
> of that single identity. Health is measured by filtering on
> attributes, not by navigating between entities. The unit of slicing
> is the attribute.

Next: [Rung 3 - Measuring HTTP health both ways](03-http-health-both-ways.md).
