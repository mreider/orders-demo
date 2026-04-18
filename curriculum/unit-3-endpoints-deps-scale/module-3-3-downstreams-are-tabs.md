# Module 3.3 — Downstreams are tabs, not entities

> **What you'll know by the end:** for any service that talks to a
> database, queue, or third-party API, you can locate the relevant tab
> on the service detail page, explain why it's a tab and not a separate
> service entity, and query the same data directly in DQL.

## The question

Your service calls Postgres. In Classic, Postgres showed up as a
DATABASE_SERVICE entity in the Services list. It had its own row, its
own failure rate, its own baselines. If you wanted to know "is my
service's database slow?" you clicked into the DATABASE_SERVICE row.

In Latest Dynatrace, that DATABASE_SERVICE row often *doesn't exist* —
or if it does, it's being phased out. You open your service's detail
page and… where's the database?

> *Where do DB calls live in the Latest Services app, and why did the
> model change?*

## The claim

Downstream dependencies (database, messaging, third-party HTTP) are
**tabs on the calling service**, not separate entities. The tabs are:

| Tab | Metric family | What it shows |
|---|---|---|
| **DB Queries** | `dt.service.database.query.*` + span attrs | Every SQL/NoSQL operation the service makes, with `db.system.name`, `db.operation`, `db.sql.table` as dimensions |
| **Message Processing** | `dt.service.messaging.process.*` + publish side | Consume and publish activity per `messaging.destination.name` + `messaging.system` |
| **Outbound Calls** | `dt.service.thirdparty.*` for recognized third parties; spans for everything else | Every client-side HTTP call to another service, with host/endpoint/status dimensions |

The information hasn't disappeared. It's been **relocated** from
"pretend there's a downstream service entity" to "show the calling
service's view of what it talks to."

## Why this matters

1. **No more fake entities.** In Classic, a `postgres:orders-db`
   DATABASE_SERVICE entity existed not because Postgres was being
   monitored, but because Dynatrace needed somewhere to attach
   client-side JDBC metrics. That entity was always a fiction. Latest
   removes it.
2. **Trace-based RCA replaces entity-based RCA.** When the DB is slow
   and your service is slow, you follow the *trace* — from the
   service's HTTP handler into its JDBC span, out to the query. You
   don't hop entity graphs.
3. **Ownership is clearer.** The team that owns the service owns its
   DB-client side too. No separate "who owns this DATABASE_SERVICE"
   question.

## The existing-customer concern

Two things customers notice and sometimes mistake for bugs:

- **"Where are my queue listeners?"** Each Classic `MESSAGING_SERVICE`
  became a Message Processing tab on its calling service. Don't
  expect it as a top-level row any more.
- **"My external service entity is gone."** Third-party HTTP calls
  show up in Outbound Calls. Recognized third parties (like cloud
  providers or DEM-list APIs) get `dt.service.thirdparty.*` metrics;
  everything else is visible via the trace side-pane and span attrs.

Some customers have spent days debugging IAM or security context
thinking these changes were permission bugs. The services aren't
gone. They're tabbed.

## The lab

**[Module 3.3 Lab — Downstreams are tabs](./module-3-3-downstreams-are-tabs.yaml)**

Three queries, each on the DB tab's underlying data:

1. **Database queries from a service.** Uses
   `dt.service.database.query.*` filtered to your service. What
   Classic would have called "DB service health," Latest calls
   "my service's DB interaction."
2. **Messaging publish side.** The side of messaging that wasn't its
   own MESSAGING_SERVICE entity in Classic — outbound publishes. Now
   queryable on the same service.
3. **Outbound HTTP.** Third-party and internal outbound traffic,
   rolled up per host.

## What you should see

The data that used to require clicking into a separate
DATABASE/MESSAGING/EXTERNAL entity in Classic is now available filtered
to your service, as dimensions on `dt.service.database.*`,
`dt.service.messaging.*`, and client-side span attrs.

The Services app's per-service detail page wraps these into named tabs.
The DQL in the lab shows the same data uncurated — useful for custom
dashboards and alerts.

### What to look for in the Dynatrace UI

Open your service's detail page in the **Services app** and locate
the tab strip at the top. You should see, depending on what the
service does:

- **DB Queries** — one row per (database-system, operation) pair.
  Clicking any row opens the underlying query-level view with
  duration distributions and failure breakdowns.
- **Message Processing** — one row per (destination, system,
  operation). Consume and publish both live here.
- **Outbound Calls** — one row per external host. Recognized
  third-party APIs get richer drill-down.

Each tab is a facet of *this* service. There are no separate rows in
the Services list for the database, the queue, or the third-party
hosts — look at the list itself to confirm. The topology simplified.

## Next

**[Module 3.4 — What's coming: SERVICE_DEPLOYMENT for
per-environment views.](./module-3-4-whats-coming-service-deployment.md)**
One remaining Classic-era pattern: splitting services by environment
(staging vs prod) or by version (v1 vs v2) by making separate
entities. The Latest model is moving to an additive
`SERVICE_DEPLOYMENT` entity that gives per-env slices without
fragmenting identity. That's the curriculum's final forward-looking
module.
