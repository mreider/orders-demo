# Three transport families

Every service's activity is measured under exactly one of three metric families. Knowing which one tells you where to look and how to split the view.

## The three families

| Family | Counts | Key dimensions |
|---|---|---|
| `dt.service.request.*` | HTTP/gRPC/RMI entry points | `endpoint.name`, `http.route`, `http.response.status_code` |
| `dt.service.messaging.process.*` | Message consumption (Kafka, SQS, Pub/Sub) | `messaging.destination.name`, `messaging.system`, `messaging.operation` |
| `dt.service.faas_invoke.*` | Serverless function invocations | `faas.trigger` |

The Services app's **Transactions** column is the coalesced sum across all three. Database client calls and outbound HTTP do not get their own family. They attach to the caller and surface as Downstream tabs on the calling service.

## See it live

**[Demo: Three transport families](./02-three-transport-families.yaml)**

- Sum the three families for one workload side by side.
- Split each family by its native dimension (`endpoint.name`, `messaging.destination.name`, `faas.trigger`).
- Coalesce to the one-number Transactions view.

Expected shape:

- Pure HTTP service: only `request.*` has counts.
- Kafka-consuming REST service: `request.*` and `messaging.process.*` both populated.
- Lambda: `faas_invoke.*` populated (plus `request.*` if behind API Gateway).

## What it looks like in the UI

- Overview tab shows **Transactions**, the coalesced total.
- **Message Processing** tab only appears when `messaging.process.*` has data.
- **Functions** tab only appears when `faas_invoke.*` has data.
- The split-by control charts Transactions by `endpoint.name`, `messaging.destination.name`, or `faas.trigger`.
