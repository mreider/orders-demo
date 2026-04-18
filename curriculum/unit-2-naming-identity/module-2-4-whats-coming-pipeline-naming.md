# Module 2.4 — What's coming: pipeline-side name control

*Forward-looking orientation. No lab.*

## Today's workaround

Module 2.3's `service.name` fix requires touching every workload. At enterprise scale (thousands of workloads, teams that don't own every deployment, third-party images) that's friction.

## The direction

Naming will move into **OpenPipeline** — the server-side processing layer spans already flow through. A tenant admin writes a processing rule that sets `dt.service.name` on incoming spans before entity and metric extraction. Same central-control UX as the old Classic naming-rules overlay, but operating on resource attributes with pipeline composability.

## Why it's not here yet

Three platform prerequisites:

1. Pipeline rules need permission to modify `dt.*` attributes (today read-only at processing layer).
2. Entity creation must move after processing so rules can affect the entity graph.
3. Batched topology updates to avoid storms from tenant-wide renames.

No committed external timeline. Watch the Dynatrace community for 2026 milestones.

## What to do today

- Use the `service.name` workaround for Classic services you own.
- Don't invest new effort in Services Classic naming-rules — being retired.
- Pick a `service.name` that will survive both the SDv2 move and the pipeline-naming move.

## Next

**[Unit 3, Module 3.1 — Every endpoint is baselined.](../unit-3-endpoints-deps-scale/module-3-1-every-endpoint-baselined.md)**
