# Capstone — your workload, end-to-end

> **What you'll do:** run one notebook that walks the full curriculum
> narrative on a workload you choose. No new concepts. The goal is
> integration practice and a portable artifact you can share with a
> colleague to onboard them fast.

## Why a capstone

The three units covered a lot of ground in small pieces. A single
end-to-end pass on a real workload — yours, not the demo's — helps
the framework stick. And a one-notebook walk-through is also the
artifact that's easiest to share: point a teammate at it, they run
through it in 30 minutes, they understand.

## What you'll need

- A workload in your tenant, ideally one you own and know well.
- Its `k8s.namespace.name` and `k8s.workload.name`.
- Its `dt.service.name` — find it with:
  ```
  timeseries cnt = sum(dt.service.request.count),
  by: {dt.service.name, k8s.workload.name},
  filter: matchesValue(k8s.workload.name, "<YOUR_WORKLOAD>"),
  from: now()-30m
  ```

If your tenant has both Classic and Latest services, pick a Latest
one for the main walk-through. The Unit 1.4 side-by-side query at the
end uses a second workload for contrast.

## The capstone notebook

**[Capstone Lab — one service, full walkthrough](./capstone.yaml)**

The notebook is structured as seven sections, one per Unit-level
learning:

| Section | Asks | From |
|---|---|---|
| 1. Identity | How many entities is this workload? Which one? | Unit 1.1 |
| 2. Activity | What metric families does it emit? | Unit 1.2 |
| 3. Slices | Split by endpoint, destination, etc. | Unit 1.3 |
| 4. Naming | Where does its name come from? | Unit 2.1 |
| 5. Query shape | Rewrite a dashboard query metric-first. | Unit 2.2 |
| 6. Endpoints | Which are baselined? Any `METHOD /*`? | Units 3.1 + 3.2 |
| 7. Downstreams | DB, messaging, outbound HTTP tabs. | Unit 3.3 |

There's one optional final section:

| 8. Side-by-side | Compare with a Classic workload if you have one | Unit 1.4 |

### What to look for in the Dynatrace UI

The capstone's sections each reinforce what a particular Services app
view should show you. After running a section's DQL, open the
corresponding UI location to anchor the query result to something
visible:

| Section | Open this in the UI |
|---|---|
| 1. Identity | Services app → your service → Overview |
| 2. Activity | Services app → your service → "Transactions" metric |
| 3. Slices | Services app → your service → Explorer tab, split-by endpoint.name |
| 4. Naming | Services app → your service → Properties panel (or its equivalent) |
| 5. Query shape | Notebooks app → query metadata panel, Scanned records column |
| 6. Endpoints | Services app → your service → Endpoints section |
| 7. Downstreams | Services app → your service → DB Queries / Message Processing / Outbound Calls tabs |

Pairing each DQL cell with its UI view makes the capstone a "read the
platform in two modes" walk — which is exactly what you'd hand a
colleague who's trying to learn the Latest Services app from scratch.

## Sharing

The notebook is environment-shared by default when loaded with
`dtctl apply --share-environment`. Send the URL to a colleague who
needs this material. They can re-run every query in place, substitute
their own workload, and the lab serves as a personal onboarding guide.

## What's next after the curriculum

This curriculum focuses on the **service detection** shift and the
query/naming patterns that follow from it. Adjacent topics not
covered here but worth learning in order of priority:

- **Segments and Primary Tags** — the cross-cutting tagging system
  that replaces Management Zones. Services app now filters by Primary
  Tag.
- **Failure Analysis** — the unified failure detection story across
  the three metric families (using `transaction.is_failed`).
- **Baselining and anomaly detection** — the mechanics of how per-
  endpoint baselines are computed and tuned.
- **Kubernetes app topology** — how Dynatrace's K8s app relates to
  the Services app you just learned.
- **Pipeline processing rules** — OpenPipeline-side transformations,
  including the in-flight naming rules replacement (Module 2.4).

Each of those deserves its own curriculum. Ask your Dynatrace
representative if a learning path for any of them exists yet.

## Feedback

This curriculum is maintained in the
[orders-demo](https://github.com/mreider/orders-demo) repo alongside
the companion application. PRs welcome — especially for sections that
don't land, queries that need fixing for a specific Dynatrace version,
or lab steps that assume too much.
