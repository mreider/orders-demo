# Module 1.2 — The three transport families

*Any service's activity belongs to exactly one of three metric families. Write one DQL that shows all three on a workload side by side.*

## The question

Pick the service from Module 1.1.

> *What kind of activity does it do, and in which metric family is it counted?*

## The claim

Every service's activity is measured under one of three families:

| Family | Counts | Key dimensions |
|---|---|---|
| `dt.service.request.*` | HTTP/gRPC/RMI entry points | `endpoint.name`, `http.route`, `http.response.status_code` |
| `dt.service.messaging.process.*` | Message consumption (Kafka, SQS, Pub/Sub) | `messaging.destination.name`, `messaging.system`, `messaging.operation` |
| `dt.service.faas_invoke.*` | Serverless function invocations | `faas.trigger` |

The Services app's **Transactions** column is the coalesced sum across all three. Database client calls and outbound HTTP do not get their own family — they attach to the caller and surface via Downstream tabs (Module 3.3).

## The lab

**[Module 1.2 Lab — The three transport families](./module-1-2-three-transport-families.yaml)**

- Sum the three families for one workload side by side.
- Split each family by its native dimension (`endpoint.name`, `messaging.destination.name`).
- Coalesce to the one-number Transactions view.

## What you should see

- Pure HTTP service: only `request.*` has counts.
- Kafka-consuming REST service: `request.*` and `messaging.process.*` both populated.
- Lambda: `faas_invoke.*` populated (plus `request.*` if behind API Gateway).

## In the Dynatrace UI

- Overview tab shows **Transactions** — coalesced total.
- **Message Processing** tab only appears when `messaging.process.*` has data.
- **Functions** tab only appears when `faas_invoke.*` has data.
- Split-by control charts Transactions by `endpoint.name`, `messaging.destination.name`, or `faas.trigger`.

## Next

**[Module 1.3 — Dimensions, not entities, split the view.](./module-1-3-dimensions-not-entities.md)**
