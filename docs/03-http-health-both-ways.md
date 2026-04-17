---
title: Rung 3 - Measuring HTTP health both ways
description: Same question, two idioms. How busy is OrderController - answered via SDv1 entity navigation and SDv2 attribute filtering.
rung: 3
last_updated: 2026-04-17
---

# Rung 3: Measuring HTTP health both ways

The first applied comparison. Same workload, same questions, two
detection models. Watch how the idioms diverge.

## Question 1: How busy is `OrderController`?

**SDv1 idiom (entity navigation):**

Navigate to the `orders-demo - OrderController` WEB_SERVICE entity.
Look at its throughput chart. Endpoints `submit` and `search` appear
inside that entity's view.

```dql
timeseries cnt = sum(dt.service.request.count),
  by: { dt.entity.service, endpoint.name },
  from: now()-30m
| lookup [fetch dt.entity.service | fields id, entity.name],
    sourceField: dt.entity.service, lookupField: id, prefix: "svc."
| filter svc.entity.name == "orders-demo - OrderController"
| fields endpoint.name, cnt
```

**SDv2 idiom (attribute filter on one identity):**

Go to the `orders-sdv2 -- orders-demo` UNIFIED service. Filter
endpoints by the controller prefix.

```dql
timeseries cnt = sum(dt.service.request.count),
  by: { dt.entity.service, endpoint.name },
  from: now()-30m
| lookup [fetch dt.entity.service | fields id, entity.name],
    sourceField: dt.entity.service, lookupField: id, prefix: "svc."
| filter svc.entity.name == "orders-sdv2 -- orders-demo"
    AND startsWith(endpoint.name, "OrderController.")
| fields endpoint.name, cnt
```

Same answer (submit + search traffic), two different paths. SDv1
partitions by entity. SDv2 partitions by attribute.

## Question 2: What is the p95 response time of `/orders/submit`?

**SDv1 idiom**: Inside the OrderController WEB_SERVICE, the `submit`
endpoint has its own p95 baseline once enhanced endpoints is on (or
once a key request is nominated).

```dql
timeseries p95 = percentile(dt.service.request.response_time, 95),
  by: { dt.entity.service, endpoint.name },
  from: now()-30m
| lookup [fetch dt.entity.service | fields id, entity.name],
    sourceField: dt.entity.service, lookupField: id, prefix: "svc."
| filter svc.entity.name == "orders-demo - OrderController"
    AND endpoint.name == "submit"
| fields p95
```

**SDv2 idiom**: Same metric, filtered to the single attribute value.

```dql
timeseries p95 = percentile(dt.service.request.response_time, 95),
  by: { dt.entity.service, endpoint.name },
  from: now()-30m
| lookup [fetch dt.entity.service | fields id, entity.name],
    sourceField: dt.entity.service, lookupField: id, prefix: "svc."
| filter svc.entity.name == "orders-sdv2 -- orders-demo"
    AND endpoint.name == "OrderController.submit"
| fields p95
```

Both answer it. SDv1 reached the answer by narrowing scope
(entity -> key request). SDv2 reached it by filtering one dimension.

## Question 3: Which endpoint is hottest across all of `orders-demo`?

**SDv1 idiom**: Aggregate across entities. Requires joining WEB_SERVICE
services back to the workload somehow - by name prefix, tag, or
host-group. Brittle.

```dql
timeseries cnt = sum(dt.service.request.count),
  by: { dt.entity.service, endpoint.name },
  from: now()-30m
| lookup [fetch dt.entity.service | fields id, entity.name, serviceType],
    sourceField: dt.entity.service, lookupField: id, prefix: "svc."
| filter contains(svc.entity.name, "orders-demo - ")
    AND svc.serviceType == "WEB_SERVICE"
| sort cnt desc
| limit 10
```

**SDv2 idiom**: Top-N the single dimension on the one service.

```dql
timeseries cnt = sum(dt.service.request.count),
  by: { dt.entity.service, endpoint.name },
  from: now()-30m
| lookup [fetch dt.entity.service | fields id, entity.name],
    sourceField: dt.entity.service, lookupField: id, prefix: "svc."
| filter svc.entity.name == "orders-sdv2 -- orders-demo"
| sort cnt desc
| limit 10
```

SDv1 requires knowing the service-naming convention to stitch the
query together. SDv2 does not.

## Observations

- **Query shape is the same.** Both idioms use `timeseries ... by
  endpoint.name`. Only the `filter` clause differs - SDv1 filters on
  `svc.entity.name` (entity equality), SDv2 filters on `endpoint.name`
  (attribute).
- **Scope is different.** SDv1 scopes are entity-bounded: whatever
  lives on that one WEB_SERVICE. SDv2 scopes are attribute-bounded:
  whatever matches the dimension filter on the one identity.
- **Cross-entity aggregation is the SDv1 tax.** Any question that
  spans multiple controllers or transports requires gathering SDv1
  entities together by a naming convention. SDv2 does not have this
  cost because the entities never fragmented in the first place.

## What you now know

> On SDv1, HTTP health is read by navigating to the entity that
> represents the controller. On SDv2, it is read by filtering a
> dimension on the one UNIFIED service. The arithmetic is the same;
> the scope boundary moves from entity to attribute.

Next: [Rung 4 - Measuring messaging health both ways](04-messaging-health-both-ways.md).
