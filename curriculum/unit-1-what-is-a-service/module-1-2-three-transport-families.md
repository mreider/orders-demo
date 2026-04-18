# Module 1.2 — The three transport families

> **What you'll know by the end:** any service's activity in Dynatrace
> belongs to exactly one of three metric families — and you can write a
> single DQL query that shows all three on one workload side by side.

## The question

Pick the service you worked with in Module 1.1. Now answer:

> *What kind of activity does this service do?*

Your answer is probably *"it handles HTTP requests."* That's true for many
services. But the same service might also consume Kafka messages, process
Lambda invocations, or do something else. Dynatrace counts each of those
kinds of activity under a different **metric family**. Knowing which family
the UI is pulling from — and when two families carry the same request — is
the foundation for every latency, throughput, and failure chart you'll
look at.

## The claim

Every service's activity in Dynatrace is measured under one of three
metric families:

| Family | What it counts | Key dimensions |
|---|---|---|
| `dt.service.request.*` | HTTP/gRPC/RMI entry points | `endpoint.name`, `http.route`, `http.response.status_code` |
| `dt.service.messaging.process.*` | Message consumption (Kafka, SQS, Pub/Sub, etc.) | `messaging.destination.name`, `messaging.system`, `messaging.operation` |
| `dt.service.faas_invoke.*` | Serverless function invocations | `faas.trigger` |

The Services app calls the umbrella of these three **"Transactions"** — it
used to say "Requests," which made people think HTTP-only. A service that
handles both HTTP and Kafka has transactions of two kinds; the Transactions
column is the coalesced total.

There is no fourth family for "internal" activity. Database client calls,
outbound HTTP to third parties, and internal method invocations do not get
their own family — they're measured by their *caller* and attach to that
service's picture via spans and the Downstream tabs (Module 3.3).

## Why this matters

- Per-endpoint baselines, failure rates, and latency percentiles all live
  on one of the three families. When you drill into endpoint health, you
  are reading from whichever family produced the entry-point span.
- Dashboards that mix transaction types (e.g. "workload total throughput")
  coalesce the three. DQL lets you do that explicitly.
- The terminology in the UI follows the family: you'll see **Message
  Processing** as a tab when `messaging.process.*` is populated, and
  **Functions** when `faas_invoke.*` is populated.

## The lab

**[Module 1.2 Lab — The three transport families](./module-1-2-three-transport-families.yaml)**

Three queries:

1. **Which families does this service emit?** — a single DQL that shows
   `request.*`, `messaging.process.*`, and `faas_invoke.*` counts side by
   side for your chosen workload.
2. **Same question, same workload, split by endpoint dimension.** — zooms
   into the dimensions that make each family queryable.
3. **Coalesce.** — the one-query workload-total that treats all three
   families as a single "Transactions" count, matching the UI.

## What you should see

For a simple HTTP service: only `request.*` has counts. Messaging and FaaS
are zero.

For a Kafka-consuming REST service (like the demo's `orders-demo`
workload): `request.*` **and** `messaging.process.*` both have counts.
The messaging count is the Kafka listener's work; the request count is the
HTTP controllers.

For a Lambda: `faas_invoke.*` has counts. If the function is behind API
Gateway, `request.*` may also be populated on the HTTP side.

The *"Transactions"* number in the UI is the sum across all three.

### What to look for in the Dynatrace UI

Open your service in the **Services app**. Look for:

- A **"Transactions"** metric prominently on the Overview tab. That's
  the coalesced count across all three families. The label used to say
  "Requests"; if yours still does, your tenant has a UI version from
  before the rename.
- If your service handles messages, a **Message Processing** tab
  appears in the service's detail view. If your service is a Lambda,
  a **Functions** tab appears. Both tabs only show up when the
  corresponding metric family has data — that's why a pure HTTP
  service doesn't see them.
- On the Overview tab, the **split-by** control lets you chart
  Transactions by `endpoint.name`, `messaging.destination.name`, or
  `faas.trigger` — one control, three families, matching Question 2
  from the lab.

## Next

**[Module 1.3 — Dimensions, not entities, split the view.](./module-1-3-dimensions-not-entities.md)**
Now that you know *what* is being counted, Module 1.3 shows how the Latest
model lets you split those counts — by endpoint, by controller, by
destination — without creating new entities. That's the core of the
attribute-first shift.
