# Module 3.3 — Downstreams are tabs, not entities

*For any service that talks to a database, queue, or third-party API, locate the relevant tab on the service detail page and query the same data in DQL.*

## The question

Your service calls Postgres. Under SDv1, Postgres showed up as a `DATABASE_SERVICE` entity with its own row, failure rate, and baselines. Under SDv2 that row is gone.

> *Where do DB calls live with SDv2, and why did the model change?*

## The claim

Downstream dependencies — database, messaging, third-party HTTP — are **tabs on the calling service**, not separate entities:

| Tab | Metric family | Dimensions |
|---|---|---|
| **DB Queries** | `dt.service.database.query.*` | `db.system.name`, `db.operation`, `db.sql.table` |
| **Message Processing** | `dt.service.messaging.process.*` (consume + publish) | `messaging.destination.name`, `messaging.system` |
| **Outbound Calls** | `dt.service.thirdparty.*` + client spans | host, endpoint, status |

The data didn't disappear. It moved from "pretend downstream is its own entity" to "show the caller's view of what it talks to." No more fake DATABASE_SERVICE entities for JDBC clients. Ownership stays with the caller.

Customers sometimes mistake this for a bug: "where are my queue listeners?" (now a Message Processing tab on the caller), "my external service entity is gone" (now Outbound Calls). It's relocation, not removal.

## The lab

**[Module 3.3 Lab — Downstreams are tabs](./module-3-3-downstreams-are-tabs.yaml)**

- Database queries from a service — `dt.service.database.query.*` by `db.system.name`, `db.operation`.
- Message processing by `messaging.destination.name`, `messaging.system`, `messaging.operation`.
- Outbound HTTP calls via `span.kind == "client"` by host and method.

## What you should see

- Each query returns the per-service breakdown for one downstream type.
- No rows in the Services list for those databases/queues/third parties.
- Same DQL shape: filter to service, group by downstream dimension.

## In the Dynatrace UI

- Service detail → tab strip includes **DB Queries**, **Message Processing**, **Outbound Calls** depending on what the service does.
- Each tab is a facet of this service. Recognized third parties get richer drill-down.
- No separate DATABASE/MESSAGING/EXTERNAL rows in the Services list.

## Next

**[Module 3.4 — What's coming: SERVICE_DEPLOYMENT.](./module-3-4-whats-coming-service-deployment.md)**
