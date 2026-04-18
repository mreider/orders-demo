# Metric-first queries

Skip the entity table. Your SDv2 DQL gets shorter, cheaper, and more stable.

## `dt.service.name` is a first-class metric dimension

With SDv2, `dt.service.name` and `service.name` are indexed directly on timeseries metrics. You can `filter` and `by` them on the metric without fetching `dt.entity.service` first. The entity table still exists for metadata (ownership, tags), just not on the critical path for metric questions.

Three consequences:

- **Shorter queries.** Fewer lines, easier to read and share.
- **Fewer scanned records.** Often an order of magnitude less.
- **Stable identity.** Dimension values ride through entity re-detection.

## See it live

**[Demo: Metric-first queries](./06-metric-first-queries.yaml)**

Four comparisons, each asking the same question two ways (entity-joined vs. metric-first):

- List endpoints of a service.
- Average response time for one endpoint.
- Failure rate by HTTP status.
- Workload total across three families.

## What it looks like in the UI

The Services app already runs the right queries internally. Where metric-first pays off is the DQL you write yourself in Notebooks, Dashboards, and alerts. Watch **Scanned records** and **Execution time** in the cell metadata panel. Cheaper queries mean cheaper dashboards.

Classic caveat: SDv1-detected services may not have `dt.service.name` populated consistently. The service.name workaround section addresses that.
