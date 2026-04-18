# Module 2.2 — Metric-first queries: skip the entity table

*Rewrite an entity-joined DQL query as a metric-first query in fewer lines, and point at the query metadata to see the cost difference.*

## The question

> *"What's my slowest endpoint right now?"*

Two DQL shapes answer it. Both return the same numbers. One is five lines, one is two. One reads from the entity graph; the other filters on a metric dimension.

## The claim

`dt.service.name` and `service.name` are first-class metric dimensions in Latest. You can `filter` and `by` them directly on the timeseries metric — no `fetch dt.entity.service` needed. The entity table is still there for entity metadata (ownership, tags), just not on the critical path for metric questions.

Consequences:

- Shorter queries — fewer lines, easier to read and share.
- Fewer scanned records — often an order of magnitude less.
- Dimension values are stable across entity ID changes.

## The lab

**[Module 2.2 Lab — Metric-first queries](./module-2-2-metric-first-queries.yaml)**

Four comparisons, each answering the same question two ways:

- List endpoints of a service.
- Average response time for one endpoint.
- Failure rate by HTTP status.
- Workload total across three families.

## What you should see

- Entity-joined version: 4–6 lines longer, scans more records.
- Metric-first: same result, one filter.
- The difference adds up in scheduled dashboards, alerts, and notebooks.

## In the Dynatrace UI

Nothing changes in the Services app — it already runs the right queries internally. Where this matters is DQL you write yourself. Watch the **Scanned records** and **Execution time** in the notebook cell metadata panel: metric-first is cheaper.

## Where it breaks

Classic-detected services may not have `dt.service.name` populated consistently. Module 2.3 covers that.

## Next

**[Module 2.3 — The `service.name` workaround.](./module-2-3-service-name-workaround.md)**
