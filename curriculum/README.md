# Services in Latest Dynatrace — a curriculum

This curriculum teaches existing Dynatrace customers how services work under
the Latest Dynatrace detection model, and how it differs from what Classic
Dynatrace gave them. Every module pairs a short concept narrative with a
hands-on lab notebook that runs against the learner's own tenant.

## Audience

Existing Dynatrace SaaS customers. Comfort with the Services app is assumed.
Basic DQL familiarity helps but is not required — every lab spells out the
query.

## How to work through it

In order. Each module takes 10–20 minutes. Modules marked *"What's coming"*
have no lab; they orient the learner on features that will land later in 2026.

| Unit | Focus | Modules |
|---|---|---|
| **1 — What is a service, really?** | The shift from entity-first to attribute-first | 1.1 · 1.2 · 1.3 · 1.4 |
| **2 — Naming and identity** | How services get their names and why queries get easier | 2.1 · 2.2 · 2.3 · *2.4* |
| **3 — Endpoints, dependencies, scale** | Endpoints, downstreams, per-environment views | 3.1 · 3.2 · 3.3 · *3.4* |

A **Module 0** (Lab setup) covers tenant access, scopes, and how to load the
companion notebooks. A **Capstone** at the end walks the full narrative
end-to-end on a workload of the learner's choice.

## Running the labs

Each `.yaml` in this tree is a Dynatrace notebook. To load them into your
tenant:

```bash
dtctl auth login   # one-time, needs document:documents:write + env-shares:write
for f in curriculum/**/*.yaml; do
  dtctl apply -f "$f" --write-id --share-environment
done
```

The `--write-id` flag stamps your tenant's notebook ID into your local copy
so re-applies update in place. `--share-environment` makes the notebook
visible to everyone in your environment so you can pair-walk them with a
colleague without manual UI sharing.

If you don't yet have a workload in your tenant where both detection models
have been observed, several labs fall back to the companion **orders-demo**
application — a Spring Boot app deployed twice, once under Classic SDv1 and
once under Latest SDv2, that you can run locally on any Kubernetes cluster.
See `../README.md` in the repo root for setup.

## Terminology

This curriculum uses customer-facing terms. "Latest Dynatrace" and "Classic
Dynatrace" are what the UI labels will show. Some internal documents and
Confluence pages use "SDv2" (Latest) and "SDv1" (Classic); those appear only
where the DQL asks for a specific technical value.

## What's in flight

Two modules — 2.4 and 3.4 — are deliberately forward-looking. They mark the
places where the Latest model is still improving through 2026: pipeline-side
service naming, the SERVICE_DEPLOYMENT entity for per-environment views, and
Datadog-style `service + env + version` tagging. Each flags the gap today and
the ticket/timeline so you can plan around it.
