# Downstreams are tabs, not entities

Databases, queues, and third-party APIs don't get their own service rows anymore. They're tabs on the calling service.

## Where your downstreams went

Your service calls Postgres. You open the Services app and there's no Postgres row, no Kafka-listener row, no external-service row for the third-party APIs you call. Yet you can still see per-database, per-queue, per-host detail for the calling service.

Downstream dependencies - database, messaging, third-party HTTP - are tabs on the caller:

| Tab | Metric family | Dimensions |
|---|---|---|
| **DB Queries** | `dt.service.database.query.*` | `db.system.name`, `db.operation`, `db.sql.table` |
| **Message Processing** | `dt.service.messaging.process.*` (consume + publish) | `messaging.destination.name`, `messaging.system` |
| **Outbound Calls** | `dt.service.thirdparty.*` + client spans | host, endpoint, status |

Database identity lives on the JDBC client span itself: `db.system` + `db.namespace` + `server.address`, owned by the calling service. Same pattern for messaging and external HTTP. The dimensions are on the caller's client spans; there's no separate entity. The tabs in the Services app are a curated view of those dimensions.

## This is a Latest-app feature, not an SDv2-only feature

The tabs work equally on modern SDv1 and SDv2 tenants. Both detection models already route downstreams through the caller. The Services app adds the tab UI on top of that data; you get it regardless of which detection model you're on.

## Historical note for Classic refugees

If you're coming from Classic Dynatrace (pre-Latest), you may remember:

- A separate `DATABASE_SERVICE` entity for each database your service talked to.
- A `MESSAGING_SERVICE` for each Kafka listener.
- `EXTERNAL_SERVICE` rows for third-party hosts.

On modern Latest Dynatrace tenants those entities are gone. SDv1 has already moved to the caller-side dimensional model. The Services app's tabs replace the entity-per-downstream pattern without losing any drill-down.

Upgrading customers sometimes mistake this for a bug. *"Where are my queue listeners?"* is now a Message Processing tab on the caller. *"My external service entity is gone"* is now Outbound Calls. It's relocation, not removal.

## See it live

**[Demo: Downstreams are tabs](./10-downstreams-are-tabs.yaml)**

- Database queries from a service: `dt.service.database.query.*` by `db.system.name`, `db.operation`.
- Message processing by `messaging.destination.name`, `messaging.system`, `messaging.operation`.
- Outbound HTTP calls via `span.kind == "client"` by host and method.

Same DQL shape across all three: filter to the caller, group by downstream dimension.

## What it looks like in the UI

- Service detail page, tab strip: **DB Queries**, **Message Processing**, **Outbound Calls** appear depending on what the service does.
- Each tab is a facet of this service. Recognized third parties get richer drill-down.
- No separate DATABASE, MESSAGING, or EXTERNAL rows in the Services list.
