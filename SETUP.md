---
title: orders-demo setup guide
last_updated: 2026-04-18
---

# Setup

Start-to-finish guide: Dynatrace tokens, GKE cluster, Dynatrace Operator, deploy the app, load the curriculum notebooks into your tenant. Start-to-working state ≈ 20 minutes.

## Prerequisites

Local tools:

- [`gcloud`](https://cloud.google.com/sdk/docs/install) — authenticated to a GCP project you can create resources in.
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/) — for managing the cluster.
- [`docker`](https://docs.docker.com/get-docker/) — for building the app image.
- [`dtctl`](https://github.com/dynatrace-oss/dtctl) — for loading curriculum notebooks. `brew install dynatrace-oss/tap/dtctl`.
- [`jq`](https://stedolan.github.io/jq/) — used by `scripts/load-curriculum.sh`.
- [`envsubst`](https://www.gnu.org/software/gettext/) — part of gettext, usually pre-installed on macOS (`brew install gettext`) or Linux.

Access:

- A Dynatrace SaaS tenant you own or have admin on. The tenant URL looks like `https://abc12345.apps.dynatrace.com` or `https://abc12345.dev.apps.dynatracelabs.com`.
- A GCP project with billing enabled.

## 1. Dynatrace tokens

You need two tokens in your tenant:

### 1a. Operator API token (for the Dynatrace Operator on the cluster)

In the Dynatrace UI: **Access tokens** → **Generate new token**. Name it `orders-demo-operator`. Required scopes (tick each):

- `entities.read`
- `settings.read`, `settings.write`
- `DataExport` (Ingest metrics)
- `InstallerDownload`
- `PaaSIntegration-InstallerDownload`
- `ActiveGateTokenManagement.Create`
- `EntityTokenManagement.Create`

Save the token; you'll pass it to the cluster setup as `DT_API_TOKEN`.

### 1b. Data-ingest token

Generate a second token named `orders-demo-ingest`. Scopes:

- `metrics.ingest`
- `openTelemetryTrace.ingest`
- `logs.ingest`

Save as `DT_DATA_INGEST_TOKEN`.

### 1c. Platform token (for loading curriculum notebooks)

Generate a third token named `orders-demo-notebooks` under **Settings → Personal access tokens → Generate new token**. Scopes:

- `document:documents:read`
- `document:documents:write`
- `document:environment-shares:read`
- `document:environment-shares:write`

Save as `DT_PLATFORM_TOKEN`. (This one is distinct from the two above — it's an OAuth-style platform token used by the notebook loader script.)

### 1d. Note the API URL

You'll need `DT_API_URL` set to the full API path, e.g. `https://abc12345.live.dynatrace.com/api` (production SaaS) or `https://abc12345.dev.dynatracelabs.com/api` (dev/lab environments).

And `DT_ENV` set to the apps root for the platform token calls: `https://abc12345.apps.dynatrace.com` or `https://abc12345.dev.apps.dynatracelabs.com`.

## 2. Cluster + app deploy

Two options: local script or GitHub Actions.

### Option A — Local script (fastest)

```bash
export DT_API_URL="https://abc12345.live.dynatrace.com/api"
export DT_API_TOKEN="dt0c01.XXXX…"
export DT_DATA_INGEST_TOKEN="dt0c01.YYYY…"

# Optional overrides (defaults shown)
export GCP_PROJECT="${GCP_PROJECT:-your-gcp-project}"
export GKE_CLUSTER="${GKE_CLUSTER:-orders-demo}"
export GKE_REGION="${GKE_REGION:-us-central1}"
export GKE_ZONE="${GKE_ZONE:-us-central1-c}"

./scripts/up.sh
```

`up.sh` does the full sequence end to end: ensures the GCP project, creates the GKE cluster if missing, creates the Artifact Registry repo, builds and pushes the app image, installs the Dynatrace Operator + DynaKube, applies namespaces + Postgres + Redpanda + the two app Deployments + the loadgen Jobs. Runtime ≈ 10 minutes the first time (cluster creation dominates), 2–3 minutes on re-runs.

### Option B — GitHub Actions

See [SECRETS.md](SECRETS.md) for the five repo secrets the workflows need. Then from the Actions tab, run **cluster-up** once, push to `main` (or run **build** manually) to build the image, and run **deploy** to apply manifests.

Use Option B when you want the cluster managed by a repo you share with teammates; Option A when you're iterating locally.

## 3. Opt `orders-sdv2` into SDv2 detection

SDv2 is enabled per Kubernetes namespace via a setting.

In the Dynatrace UI:

1. Go to **Kubernetes Classic** (or the Kubernetes app) → your cluster → namespace `orders-sdv2`.
2. **Settings → Service detection → Service Detection v2 for OneAgent** → enable (`enableSDV2ForKubernetesWorkloads: true`).
3. Leave `orders-sdv1` on default (SDv1).

Wait ~5 minutes for the new UNIFIED entity to appear. You can confirm from a terminal:

```bash
dtctl auth login   # if not already
dtctl query 'fetch dt.entity.service | filter contains(entity.name, "orders") | fields id, entity.name, serviceType'
```

Expected: one row with `serviceType = UNIFIED` named `orders-sdv2 -- orders-demo`, alongside several Classic entities (`WEB_REQUEST_SERVICE`, `WEB_SERVICE`, `MESSAGING_SERVICE`, possibly `DATABASE_SERVICE`) for the `orders-sdv1` side.

## 4. Load the curriculum notebooks

The 11 lab notebooks and the home notebook live in `curriculum/` and `notebooks/`. To load them into your tenant as environment-shared (`isPrivate: false`) notebooks, use the wrapper script:

```bash
export DT_ENV="https://abc12345.apps.dynatrace.com"
export DT_PLATFORM_TOKEN="dt0s16.XXXX…"

dtctl auth login    # one-time; the wrapper uses dtctl for the apply step

./scripts/load-curriculum.sh
```

What it does, per notebook:

1. `dtctl apply -f <file> --write-id` — creates the notebook (or updates in place if already applied) and stamps the generated ID into the YAML.
2. `curl POST /environment-shares` — creates a read-access environment share so colleagues can discover the notebook.
3. `curl PATCH /documents/{id}` with `isPrivate=false` — flips the notebook's visibility flag so it appears in the Notebooks app listing.

Steps 2 and 3 exist because upstream `dtctl` currently lacks a `--share-environment` flag that does them automatically. PR [#165](https://github.com/dynatrace-oss/dtctl/pull/165) against `dynatrace-oss/dtctl` adds the flag; once merged and released, you can drop the wrapper and just use `dtctl apply -f <file> --share-environment --write-id`. See [scripts/load-curriculum.sh](scripts/load-curriculum.sh) for the wrapper source.

### If you already have the patched dtctl

If you've built dtctl from [PR #165](https://github.com/dynatrace-oss/dtctl/pull/165), skip the wrapper:

```bash
for f in curriculum/**/*.yaml notebooks/home.yaml; do
  dtctl apply -f "$f" --write-id --share-environment
done
```

That's equivalent. The wrapper just backfills the two extra API calls `--share-environment` makes.

## 5. Verify

Open the Dynatrace **Notebooks** app. Filter by `Curriculum /`. You should see:

- `Curriculum / Module 1.1 - One workload, one service`
- … through `Curriculum / Module 3.4 - What's coming: SERVICE_DEPLOYMENT`
- `Services in Latest Dynatrace - Curriculum Home`

Each is marked as shared with the environment (icon indicator in the notebooks list).

Open Module 0 (lab setup) and run its sanity query. If it returns data, you're ready. Walk the curriculum in order.

## Teardown

```bash
./scripts/down.sh
```

Or run **Actions → cluster-down** (requires typing `delete` as confirmation). This deletes the GKE cluster, the Artifact Registry repo, and the OAuth client. It does NOT delete the Dynatrace tokens — revoke those manually if you want to.

## Troubleshooting

### `access denied to document` on `dtctl delete`

Your OAuth client was issued before `document:documents:delete` was added to the `readwrite-all` safety level. Run `dtctl auth login` again to refresh scopes. If it persists, see PR [#164](https://github.com/dynatrace-oss/dtctl/pull/164).

### Notebooks show `isPrivate: true` after the wrapper runs

Check `$DT_PLATFORM_TOKEN` has `document:environment-shares:write` AND `document:documents:write`. The wrapper silently skips the PATCH if it's missing one.

### `fetch dt.entity.service` returns no rows for `orders-sdv2`

SDv2 opt-in takes a few minutes to surface a UNIFIED entity. If nothing appears after 10 minutes, verify the setting stuck: **Settings → Service detection → Service Detection v2 for OneAgent**, scope `CLOUD_APPLICATION_NAMESPACE-<hash>` for `orders-sdv2`.

### Loadgen Jobs completed too early

The k6 Jobs run for 30 minutes then stop. Re-apply to restart:

```bash
kubectl -n orders-sdv1 delete job loadgen loadgen-named --ignore-not-found
kubectl -n orders-sdv2 delete job loadgen --ignore-not-found
kubectl apply -f k8s/40-load.yaml -f k8s/41-load-named.yaml
```
