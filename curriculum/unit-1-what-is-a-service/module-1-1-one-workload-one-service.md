# Module 1.1 — One workload, one service

> **What you'll know by the end:** given a Kubernetes workload in your tenant,
> you can say how many Dynatrace service entities represent it, and which
> detection model decided the answer.

## The question

Open the Services app in your tenant. Pick one of your Kubernetes-deployed
services. Now answer:

> *How many service entities does Dynatrace show for this one workload?*

Most people's gut answer is *one*. That's true under the Latest Dynatrace
detection model. It's not true under Classic. Which one your workload is on
depends on a per-namespace setting most teams inherited without ever choosing.

## The claim

In Latest Dynatrace, **one Kubernetes workload = one service entity**. One
Deployment, one StatefulSet — one SERVICE row in the Services app, no matter
how many controllers, listeners, or client libraries live in the pod.

In Classic, that same workload fragments. A Spring Boot app with two REST
controllers and a Kafka listener becomes four separate SERVICE entities:

- a `WEB_REQUEST_SERVICE` for the workload aggregate
- two `WEB_SERVICE` entities, one per controller class
- a `MESSAGING_SERVICE` for the Kafka consumer

Health is measured per entity. So is ownership, naming, and alerting. If a
production incident crosses controllers, you're following four entity
timelines instead of one.

The shift from Classic to Latest isn't a rename. It's a change in the **unit
of slicing** — from *entity* to *attribute*. Every other module in this
curriculum builds on that.

## The lab

Open the companion notebook in your tenant:

**[Module 1.1 Lab — One workload, one service](./module-1-1-one-workload-one-service.yaml)**

It walks you through three queries, each on a workload you pick:

1. **Count.** How many SERVICE entities does this workload produce today?
2. **Classify.** Which detection model is this namespace on?
3. **Compare.** What are the entity names, and what does each represent?

The lab uses your own tenant. If you don't yet have a workload where both
detection modes have been observed, the lab falls back to the companion
`orders-demo` project.

## What you should see

If your workload is under **Latest**: one row. One entity. The name comes
from `k8s.workload.name`, or from `service.name` if your app sets it as a
resource attribute.

If your workload is under **Classic**: 4–10 rows for a non-trivial app. Names
like `my-app - UserController`, `my-app`, `OrderEventsListener`. Each row is
a separate entity that baselines, alerts, and reports independently.

If both: keep that picture. Unit 1.4 uses the contrast directly.

## Why this matters before anything else

Nothing else in the Latest Services app makes sense without this shift.
Baselines attach to dimension values, not to entities. Endpoint health rolls
up into the workload, not into a separate WEB_SERVICE. Ownership is
assigned to the workload, not to each controller. When you read a dashboard
in the Latest UI and expect familiar Classic behavior, the mismatch starts
here.

## Next

**[Module 1.2 — The three transport families.](../module-1-2-three-transport-families.md)**
Whether your workload produces one service entity or ten, its activity is
measured as one of three things: requests, message processing, or function
invocations. Before you can compare models, you need to know what a service's
activity is even being *counted* as.
