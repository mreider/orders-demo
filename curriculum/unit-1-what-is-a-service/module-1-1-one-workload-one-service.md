# Module 1.1 — One workload, one service

*Given a Kubernetes workload, say how many Dynatrace service entities represent it and which detection model decided.*

## The question

Pick one of your Kubernetes-deployed services in the Services app.

> *How many service entities does Dynatrace show for this one workload?*

## The claim

In **Latest Dynatrace**, one Kubernetes workload = one service entity. One Deployment, one SERVICE row, regardless of how many controllers, listeners, or client libraries live in the pod.

In **Classic**, the same workload fragments. A Spring Boot app with two REST controllers and a Kafka listener becomes four SERVICE entities:

- one `WEB_REQUEST_SERVICE` for the workload aggregate
- two `WEB_SERVICE` entities, one per controller class
- one `MESSAGING_SERVICE` for the Kafka consumer

Health, naming, and alerting are measured per entity. A cross-controller incident means following four timelines instead of one.

## The lab

**[Module 1.1 Lab — One workload, one service](./module-1-1-one-workload-one-service.yaml)**

- Count distinct `dt.entity.service` IDs for your workload.
- Pull each entity's `serviceType` — is it `UNIFIED` (Latest) or Classic types?
- Compare recent activity per entity to see the fragments.

## What you should see

- **Latest**: one row, `serviceType = UNIFIED`.
- **Classic**: 4–10 rows per non-trivial app.
- **Mixed**: transitioning namespaces carry both for a window.

## In the Dynatrace UI

- Services app → filter by your workload. One row = Latest, many rows = Classic.
- Each Classic row has its own health, baselines, and alerts — that's the fragmentation cost.

## Next

**[Module 1.2 — The three transport families.](./module-1-2-three-transport-families.md)**
