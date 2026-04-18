# Module 1.3 — Dimensions, not entities, split the view

*Produce the same per-controller or per-destination breakdown that Classic used separate entities for — using one DQL and one service entity.*

## The question

You're on one service in the Services app.

> *"Which of my endpoints is the slowest?"*

Under SDv1, the answer lived in a *different* service (OrderController was its own WEB_SERVICE). Under SDv2, they live on one entity and you split at query time.

## The claim

What split into separate entities under SDv1 becomes a **dimension value** with SDv2. Group or filter by the dimension to get the slice. Nothing new is created in the entity graph.

On HTTP:

- `endpoint.name` — the UI's endpoint concept, derived from `http.route` when set (Module 3.2 covers missing cases).
- `http.route`, `http.request.method`, `http.response.status_code` — raw dimensions you can split on.

On messaging: `messaging.destination.name` per queue, `messaging.operation` for publish vs process.

## The lab

**[Module 1.3 Lab — Dimensions, not entities](./module-1-3-dimensions-not-entities.yaml)**

- Classic style: group by `dt.entity.service`, lookup entity table for names.
- Latest style: group by `endpoint.name` on one entity, no lookup.
- Same shape for messaging: swap metric family and dimension.

## What you should see

- Classic query: entity-joined, one row per WEB_SERVICE entity.
- Latest query: one row per dimension value, no `lookup` step.
- Same answer, shorter DQL.

## In the Dynatrace UI

- Latest service detail page has a split-by selector for `endpoint.name`, `messaging.destination.name`, `http.response.status_code`.
- Classic service list shows separate entity rows per controller class — you switch by clicking, not by picking a dimension.

## Next

**[Module 1.4 — Classic vs Latest, side by side.](./module-1-4-classic-vs-latest.md)**
