---
title: Generic-workload (VM) demo for SDv2 Preview
last_updated: 2026-06-29
---

# Generic-workload (VM) demo — SDv2 for generic workloads (Preview)

Every other workload in this repo runs on Kubernetes, and **K8s SDv2 is GA**.
To demonstrate **SDv2 for generic workloads (Preview)** you need a workload
that is *not* Kubernetes and *not* Lambda. This directory provisions exactly
that: a single Linux VM running the OneAgent host agent plus an
`nginx → orders-demo app → Postgres/Kafka` stack via Docker Compose.

Why a VM proves the point:

- **No `k8s.*` attributes** on the traces. The built-in K8s opt-in condition
  (namespace + cluster) can't match it. You must define the opt-in condition
  yourself — the core Preview behavior.
- **Two supported shapes on one host**: `nginx` is a **web server** (no
  `http.route` → `GET /*` endpoint flattening) and the Spring app is a
  **single-service process**. Both are in scope for the Preview; monoliths and
  background-only services are not.

## What gets created

| Piece | Detail |
|---|---|
| GCE VM | `orders-demo-vm`, `e2-standard-2`, Ubuntu 22.04, project `dynatrace-dev-on-demand`, zone `us-central1-c` |
| OneAgent | Host agent, host group **`orders-demo-vm`** (installed by `startup.sh`) |
| Stack | `vm/docker-compose.yml`: postgres, kafka, app, nginx, k6 loadgen |
| Traffic | k6 → nginx → app, looping (same `load/loadtest.js` as the cluster) |

## Prereqs

Same Dynatrace tenant as the cluster (`abl46885.dev.dynatracelabs.com`). The
provisioner needs:

- `DT_API_URL` — e.g. `https://abl46885.dev.dynatracelabs.com/api`
- `DT_API_TOKEN` — token with **InstallerDownload** scope (fetches OneAgent)

In CI these come from the existing repo secrets (`DT_API_URL`, `DT_API_TOKEN`,
`GCP_*`). Locally, export them before running the script.

> **Important:** the VM clones this repo at `REPO_REF` (default `ee-demo`) on
> boot to get the `vm/` files. **Push these files to that branch before the VM
> boots**, or the compose stack won't be found.

## Run it

CI (recommended):

```
gh workflow run vm-up.yml -f repo_ref=ee-demo
# teardown:
gh workflow run vm-down.yml -f confirm=delete
```

Local:

```
export DT_API_URL="https://abl46885.dev.dynatracelabs.com/api"
export DT_API_TOKEN="<InstallerDownload-scoped token>"
scripts/vm-up.sh
# watch boot:
gcloud compute ssh orders-demo-vm --zone us-central1-c \
  --command 'sudo tail -f /var/log/orders-demo-startup.log'
# teardown:
scripts/vm-down.sh
```

A handy source for `DT_API_TOKEN` is the in-cluster secret (same tenant):

```
kubectl -n dynatrace get secret dynakube -o jsonpath='{.data.apiToken}' | base64 -d
```

## Designing the detection (the actual exercise)

Once traffic is flowing (~5–15 min after boot), the workflow is:

### 1. Inspect the real resource attributes on the trace

Find out what the VM's spans actually carry — there is no namespace/cluster to
lean on. Run against the host group in a notebook (or via the platform API):

```dql
fetch spans, from: -30m
| filter dt.host.group.id == "orders-demo-vm" or matchesValue(host.name, "orders-demo-vm*")
| fields timestamp, span.name, span.kind, service.name, endpoint.name,
         http.route, http.request.method, url.path,
         host.name, dt.host.group.id, process.technology, k8s.namespace.name
| limit 50
```

Specifically confirm:
- **Which identity attributes exist** — expect `host.name`, `dt.host.group.id`,
  process attributes; expect `k8s.*` to be **absent**.
- **Whether `http.route` is present** — present on the Spring app spans, absent
  on the nginx spans (→ `GET /*` flattening on nginx).
- **What `service.name` resolves to** before any naming is applied.

> Reading spans needs Grail/DQL access (a platform token), which the
> InstallerDownload token does **not** grant. Try an existing platform token
> first; otherwise generate a `dt0s16…` token with `storage:spans:read` and
> `storage:buckets:read`.

_(Fill in the observed attribute set here once the VM is live.)_

### 2. Define the opt-in matching condition (proper semantics)

Generic-workloads opt-in has **no built-in condition** — you write one. With no
`k8s.*` attributes, the correct anchor is the **host group** (deliberately set
to `orders-demo-vm` at install), which is stable, intentional, and scopes the
opt-in to exactly this host. Match on `dt.host.group.id == "orders-demo-vm"`
(host name is a fallback but is per-instance and churns on rebuild).

### 3. Name the service and shape the endpoints

- **Service name:** the Spring app is one service per process; control the name
  by setting `OTEL_SERVICE_NAME` on the `app` container (left unset initially so
  step 1 shows raw detection). nginx names from the host/process.
- **Endpoints:** nginx has no `http.route`, so add **URL path pattern matching**
  / request naming rules to split `GET /*` into `GET /inventory/check`,
  `GET /orders/search`, `POST /orders/submit`. The Spring app already gets
  per-route endpoints from `http.route` automatically.

The result of steps 1–3 is the concrete "design service detection from proper
semantics" deliverable, and feeds back into
[`../community-post-generic-workloads.md`](../community-post-generic-workloads.md).

## Teardown

`scripts/vm-down.sh` (or the `vm-down` workflow) deletes the instance. It does
**not** touch the tenant — remove the host from the tenant UI and rotate the
OneAgent token (it was passed via instance metadata) when you're done.
