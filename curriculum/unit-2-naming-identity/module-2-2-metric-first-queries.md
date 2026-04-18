# Module 2.2 — Metric-first queries: skip the entity table

> **What you'll know by the end:** you can rewrite an entity-joined DQL
> query as a metric-first query in three or four fewer lines, and you
> can point at the query metadata to prove it's cheaper.

## The question

You have a question: *"What's my slowest endpoint right now?"*

There are two DQL shapes that answer it. Both return the same numbers.
One is five lines, one is two. One reads from the entity graph and joins
it in; the other filters on a metric dimension directly.

> *Why does the two-line version exist, and why should you prefer it?*

## The claim

`dt.service.name` and `service.name` are **first-class metric
dimensions** in the Latest model. You can `filter` and `by` them
directly on the timeseries metric — no `fetch dt.entity.service` needed.
The entity table is still there if you need the *entity metadata*
(ownership, tags, description) — it's just no longer on the critical
path for most metric questions.

This matters because:

1. **Shorter queries** are easier to read, share, and teach.
2. **Fewer table scans**. The query metadata (`Scanned records`) shows
   the difference — often an order of magnitude less.
3. **Dimension is stable identity**. If the service entity is renamed or
   re-detected, the dimension value that names it on metrics rides
   through the same way. Classic entity lookups break when IDs change.

## Why this exists

In Classic, `dt.entity.service` was the primary key. Metrics carried
entity IDs; names lived on the entity. The only way to ask "response
time for service X" was to look up X's ID, then query metrics by that
ID.

In Latest, the pipeline writes `dt.service.name` onto the metric itself
— with the value already set to whatever the detection chain produced
(see Module 2.1). So metric-by-name queries work without the detour.

## The lab

**[Module 2.2 Lab — Metric-first queries](./module-2-2-metric-first-queries.yaml)**

Four comparisons, each answering the same question two ways:

1. **List all endpoints of a service.** Entity-joined version first, then
   metric-first. Note the `Scanned records` difference in the query
   metadata pane.
2. **Average response time for one endpoint.**
3. **Failure rate split by HTTP status.**
4. **Workload-level throughput across three metric families.** This is
   the most dramatic saving — Classic needs a lookup + filter by
   serviceType; Latest is a single filter on `dt.service.name`.

## What you should see

The entity-joined version is 4–6 lines longer and typically scans one to
two orders of magnitude more records. For small tenants the wall-clock
difference is small, but it adds up in dashboards, alerts, and
notebooks that run these queries on a schedule.

At the Services-app level this is invisible — the app internally does
the right thing. Where it matters is when you're writing custom DQL:
for dashboards, for alerts, for notebooks like the ones in this
curriculum. Prefer metric-first by default. Fall back to entity-joined
only when you specifically need entity metadata.

### What to look for in the Dynatrace UI

Nothing in the Services app itself changes here — this module is about
the DQL you write in Notebooks, Dashboards, and alert definitions.

The thing to *see* is the **query metadata** panel underneath each
DQL cell in the Notebooks app. Run both queries (entity-joined and
metric-first) on the same service and compare:

- **Scanned records** — lower is cheaper. Metric-first skips the
  entity table scan.
- **Execution time** — typically shorter for metric-first on tenants
  with large numbers of services.

That metadata panel exists for a reason. This module teaches you to
watch it when you're writing DQL that will run in a dashboard or an
alert: cheaper queries mean cheaper dashboards and alerts.

## Where this breaks down (today)

**Classic-detected services** may not have `dt.service.name` populated
consistently. If your workload is under Classic and you haven't set
`service.name`, metric-first queries by name will miss it or collapse
multiple entities into a single dimension value. Module 2.3 covers that
case directly — the `service.name` workaround fixes the dimension.

## Next

**[Module 2.3 — The `service.name` workaround.](./module-2-3-service-name-workaround.md)**
If you have Classic services with bad names and no `service.name` set,
this is what to do today to get clean queries. And what it gets you
immediately, vs what's still in flight.
