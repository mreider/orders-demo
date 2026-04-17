---
title: orders-demo
description: A Spring Boot monolith deployed to GKE, instrumented by OneAgent via the Dynatrace Operator, that teaches SDv1 vs SDv2 side-by-side through a Vygotsky-style ladder (one concept per rung).
last_updated: 2026-04-17
---

# orders-demo

A deliberately-small Spring Boot application that teaches Service Detection v2
by running the exact same code in two Kubernetes namespaces:

- `orders-sdv1` - default SDv1 detection
- `orders-sdv2` - SDv2 opted in via the per-namespace toggle

Identical traffic runs against both sides. Every difference you see in the
Dynatrace tenant is attributable to detection, not to the app.

## The teaching ladder

The guide teaches **one new idea at a time**, each building on the previous.

| Doc | What the viewer already knows | New idea introduced |
|---|---|---|
| [00-anchor](docs/00-anchor.md) | Their SDv1 app, splitting rules, key requests | (ground truth - count the entities and the config) |
| [01-endpoints-are-the-unit](docs/01-endpoints-are-the-unit.md) | Anchor | Endpoints are the unit of health, not services |
| [02-messaging-is-first-class](docs/02-messaging-is-first-class.md) | Rung 1 | `@KafkaListener` is a peer of HTTP endpoints |
| [03-namespace-is-a-dimension](docs/03-namespace-is-a-dimension.md) | Rungs 1-2 | Namespace is a metric dimension, not a service split |
| [04-failure-crosses-the-seam](docs/04-failure-crosses-the-seam.md) | Rungs 1-3 | Failure analysis follows HTTP → Kafka → DB as one trace |

## What's in the app

The app is intentionally small. Every component earns its place on the ladder.

| Component | What it exercises | Rung served |
|---|---|---|
| `OrderController`: `POST /orders/submit` (strict, low-volume) | HTTP request baseline with strict latency | Anchor + Rung 1 |
| `OrderController`: `GET /orders/search` (loose, high-volume) | HTTP request baseline with loose latency, different from submit | Rung 1 |
| `InventoryController`: `GET /inventory/check` (fast, very-high-volume) | Third endpoint on a different controller | Anchor + Rung 1 |
| `@KafkaListener("order-events")` | Messaging.process metric family | Rung 2 + Rung 4 |
| Postgres writes via JPA | Database client-side metric (`dt.service.database.query.*`) | Rung 4 |
| Two replicas per deployment | Demonstrates replicas do not fragment identity in SDv2 | Rung 1 |
| Two namespaces, same image | Demonstrates namespace as a dimension | Rung 3 |
| 2% seeded bad-payload orders | Consumer-side failure for unified `transaction.is_failed` | Rung 4 |

Intentionally **not** built for v1 (parked as appendix if a customer asks):
`@Scheduled` jobs, `@Async` methods, webhook controllers, FaaS-invoke surface.
Adding them teaches N+1 without new rungs.

## Quick start

Preferred path is the GitHub Actions workflows. Secrets setup first
(see [SECRETS.md](SECRETS.md) for the five secrets and how to create
the GCP service account):

```bash
# One-time, per-repo
gh secret set GCP_PROJECT_ID     --body "dynatrace-dev-on-demand"
gh secret set GCP_SA_KEY         < /tmp/orders-demo-ci.json
gh secret set DT_TENANT_ID       --body "<your-tenant>"
gh secret set DT_API_TOKEN       --body "<api-token>"
gh secret set DT_DATA_INGEST_TOKEN --body "<ingest-token>"
```

Then run the workflows in order:

1. **cluster-up** (Actions → cluster-up → Run workflow): creates the GKE
   cluster, Artifact Registry repo, installs the Dynatrace Operator, applies
   the DynaKube. Run once.
2. **build** runs automatically on any push under `app/**`. First run:
   push to `main` or trigger manually.
3. **deploy** (Actions → deploy → Run workflow): applies the manifests and
   waits for rollout. Set `apply_staging: true` when you reach Rung 3.
4. In the Dynatrace UI, opt `orders-sdv2` into SDv2 (see
   [dynatrace/install.md](dynatrace/install.md) step 5).
5. Wait ~15 minutes for baselines to form, then walk the ladder in [docs/](docs/).

**Local / no-GitHub path**: `./scripts/up.sh` does the same thing from a
dev machine. Useful for iteration before you push. See [scripts/up.sh](scripts/up.sh)
for prereqs.

**Teardown**: Actions → cluster-down → Run workflow (type `delete` to
confirm). Or `./scripts/down.sh` locally.

## What this is not

- Not a reference architecture. The app is crafted for pedagogy, not production.
- Not a performance benchmark. The failure rates and latency distributions are seeded.
- Not a replacement for `context/architecture/sdv2-service-detection.md` - that page is the canonical SDv2 reference.

## Layout

```
app/                     Spring Boot source
k8s/                     Kubernetes manifests (namespaces, infra, app, load gen)
dynatrace/               DynaKube and install instructions
docs/                    The teaching ladder
scripts/                 Local up.sh / down.sh (alternative to Actions)
load/                    k6 script used by the load-gen Job
.github/workflows/       cluster-up, cluster-down, build, deploy
SECRETS.md               What to put in GitHub Secrets
```
