# Module 1.3 — Dimensions, not entities, split the view

> **What you'll know by the end:** you can produce the same per-controller
> or per-destination breakdown the Classic model used separate entities
> for — using a single DQL query and a single service entity.

## The question

You're looking at one service in the Services app. You want to answer:

> *"Which of my endpoints is the slowest?"*

In Classic, the answer lived in a *different service*. The OrderController
was its own WEB_SERVICE entity with its own response-time chart; to
compare it with InventoryController you'd open two tabs. In Latest, they
both live on one entity, and you split the view at *query time*.

## The claim

The thing that split into separate entities in Classic — a controller, a
Kafka listener, a database client — becomes a **dimension value** in
Latest. You group or filter by the dimension to get the slice you want.
Nothing new is created in the entity graph.

Concretely, on the HTTP family you'll use:

- `endpoint.name` — the UI's "endpoint" concept. Clean values come from
  `http.route` when it's set; Module 3.2 covers what happens when it
  isn't.
- `http.route` — the raw route attribute from the framework.
- `http.request.method` — split GETs from POSTs if the controller mixes.
- `http.response.status_code` — split 200s from 5xxs.

On messaging you'll use `messaging.destination.name` to split per queue,
and `messaging.operation` (`publish` vs `process`) to split sender vs
receiver work.

## Why this matters

The pattern in Classic was "create a new entity to get a new slice." The
pattern in Latest is "add a dimension to your group-by." The consequence
shows up everywhere:

- **Ownership.** One entity, one owner. Classic forced each controller's
  owner metadata to be maintained separately.
- **Alerting.** An alert on the workload covers all its activity by
  default. In Classic, you needed a composite rule or one alert per
  entity.
- **Baselining.** Per-endpoint baselines happen on dimension values, not
  on entities — so adding a new endpoint doesn't require creating a new
  SERVICE.
- **Cardinality.** Adding dimensions is cheap. Adding entities is not.

## The lab

**[Module 1.3 Lab — Dimensions, not entities](./module-1-3-dimensions-not-entities.yaml)**

Three queries that answer the same question three ways:

1. **Classic style** — what you would have done on a Classic-detected
   service. Uses the entity graph, one row per WEB_SERVICE entity.
2. **Latest style** — same question against a Latest-detected service.
   Split a single entity's metrics by `endpoint.name`.
3. **Same view, messaging instead of HTTP** — proves the mechanism
   generalises: one entity, different metric family, different
   dimension.

## What you should see

On the Classic side, you get a row per controller/listener entity with
independent numbers. It takes a `lookup` against the entity table to even
name them.

On the Latest side, you get a row per dimension value — same data,
computed by group-by alone, no table lookup. One query, one entity.

That difference in DQL structure is the *query tax* of entity-first
modelling. Module 2.2 lands on this explicitly; this module just surfaces
it so you have the shape in mind.

### What to look for in the Dynatrace UI

Open a Latest-detected service's detail page in the **Services app**.

- The **Explorer** tab (or equivalent in your tenant's version)
  offers a **split-by** selector for `endpoint.name`,
  `messaging.destination.name`, `http.response.status_code`, and
  more. Picking one renders the same split the lab's Question 2 and
  Question 3 DQL produces — one entity, many dimension values.
- For contrast, on a Classic-detected service, the Services app
  shows a *list of separate service entities* (one per controller
  class) at the top level. You switch between them by clicking, not
  by picking a dimension. That click-between is the UI version of
  the `lookup` the lab's Question 1 DQL performs.

## Next

**[Module 1.4 — Classic vs Latest, side by side.](./module-1-4-classic-vs-latest.md)**
Unit 1 closes with a direct comparison: the same application, deployed
twice, one namespace under each model. You'll see the entity counts, the
name shape, and the query shape diverge — all from the same source data.
