# Dimensions, not entities, split the view

You're on one service and you want to know which endpoint is slowest. Under SDv1, that answer lived in a different service. Under SDv2, it lives on the same service and you split at query time.

## The shift

What used to split into separate *identities* under SDv1 (per controller, per listener) becomes a **metric dimension value** under SDv2. You group or filter by the dimension (`endpoint.name`, `messaging.destination.name`) to get the slice. The workload keeps one `dt.service.name`. The per-class granularity that SDv1 baked into the name gets pushed onto dimensions the platform treats as first-class query fields.

### Historical note

Modern K8s-aware SDv1 already backs each workload with a single `WEB_REQUEST_SERVICE` *entity*. The fragmentation at the entity-graph level was retired before SDv2 shipped. What SDv2 specifically adds is collapsing the per-class `dt.service.name` fragmentation that SDv1 still produces, and pushing that granularity onto endpoint and messaging dimensions.

## Dimensions you'll actually use

On HTTP:

- `endpoint.name`: the UI's endpoint concept, derived from `http.route` when set (covered later in the deck when we get to instrumentation gaps).
- `http.route`, `http.request.method`, `http.response.status_code`: raw dimensions you can split on.

On messaging: `messaging.destination.name` per queue, `messaging.operation` for publish vs process.

## See it live

**[Demo: Dimensions, not entities](./03-dimensions-not-entities.yaml)**

- Classic style: group by `dt.entity.service`, lookup the entity table for names.
- Latest style: group by `endpoint.name` on one entity, no lookup.
- Same shape for messaging: swap the metric family and the dimension.

Expected shape:

- Classic query: entity-joined, one row per WEB_SERVICE entity.
- Latest query: one row per dimension value, no `lookup` step.
- Same answer, shorter DQL.

## What it looks like in the UI

- Latest service detail page has a split-by selector for `endpoint.name`, `messaging.destination.name`, `http.response.status_code`.
- Classic service list shows separate entity rows per controller class. You switch by clicking between list entries, not by picking a dimension.
