# Module 2.4 — What's coming: pipeline-side name control

> **No lab for this module.** This is a forward-looking orientation so
> you can plan around what changes later in 2026.

## The question you'll ask next

You've seen the `service.name` workaround in Module 2.3. It works. But
imagine you're the Dynatrace admin at a large enterprise with a
thousand workloads, a dozen teams, and some containers you can't
touch:

> *"Does every team really have to redeploy every workload to get a
> good service name?"*

That friction is what the next wave of platform work is trying to
remove.

## Why touching every workload isn't enough

The Module 2.3 workaround is fine at a team's scale but not at a
platform's:

- Large customers have hundreds or thousands of workloads.
- Not every team has the authority to change every deployment.
- Some workloads are third-party or immutable.
- Every rename means another deploy.

The old Services Classic naming-rules UI solved this server-side — a
tenant admin wrote one rule that renamed N services without anyone
touching app code. That UI is deprecated. What replaces it, and when?

## The answer: pipeline-side naming

The target state moves naming decisions into **OpenPipeline** — the
server-side processing layer your spans and logs already flow through.
A tenant admin writes a processing rule that modifies `dt.service.name`
on incoming spans *before* entity extraction and metric extraction.
Same central-control UX as the old naming rules, but:

- Operates on resource attributes, not on entity fingerprints.
- Applied once in the pipeline, reflected everywhere downstream.
- Composable with other pipeline processing (enrichment, filtering,
  SemConv mapping).

## Why it's not here yet

Three platform-side prerequisites need to land first:

1. **A path for pipeline rules to modify `dt.*` attributes.** Today
   the `dt.*` namespace is read-only at the processing layer, which
   blocks naming rules from operating on `dt.service.name` directly.
2. **Entity creation moved into the pipeline.** Entities are currently
   created before the processing step. For pipeline rules to affect
   the entity graph, creation must happen after the rules run.
3. **Batched topology updates.** Without batching, a tenant-wide
   rename would produce a large number of topology updates at once.
   Batching coalesces them.

Timelines aren't committed externally. Watch the Dynatrace community
for 2026 milestones.

## What this means for you *today*

- **Use the `service.name` workaround** (Module 2.3) for Classic
  services you own. It's the production-ready answer right now.
- **Don't re-invest** in Services Classic naming-rules that are being
  deprecated. Those rules won't survive the transition.
- **Plan around the shift**. If you have a large fleet of ugly-named
  Classic services, picking the right `service.name` *now* is a
  one-time investment: whatever you choose will survive the move to
  SDv2 and the move to pipeline-side naming.

## What this means for the Services app

The short-term UI update that makes the prefixed `dt.service.name`
appear as the entity display name (see Module 2.3) is a stopgap. Once
pipeline-side naming ships, the entity name equals the pipeline-
computed value directly, with no prefixing. Customers who've set
`service.name` today will see cleaner entity names at that point, not
prefixed composites.

## The bigger shift

Pipeline-side naming is part of a broader "move processing to the
pipeline" initiative that also touches:

- **Endpoint detection** (Module 3.2 covers the near-term
  `http.route` heuristic piece).
- **Entity extraction** (including the SERVICE_DEPLOYMENT entity for
  per-environment views — see Module 3.4).
- **Metric extraction** with Primary Fields/Tags as first-class
  dimensions.

Each of these changes makes the "everything is a dimension on a span"
model more complete. Naming is the one that most customers feel
fastest.

## Next

**Unit 2 is done.** You understand where names come from, how to make
queries shorter by using them as metric dimensions, how to fix
Classic services today, and what the longer-term plan looks like.

**[Unit 3, Module 3.1 — Every endpoint is baselined.](../unit-3-endpoints-deps-scale/module-3-1-every-endpoint-baselined.md)**
Unit 3 moves from identity to the things *inside* a service: endpoints,
their health, and the downstream dependencies that used to be separate
entities.
