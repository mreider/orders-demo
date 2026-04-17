---
title: Secrets required for the GitHub Actions workflows
description: The five GitHub Secrets and the GCP service account setup needed to run cluster-up, build, and deploy.
last_updated: 2026-04-17
---

# Secrets

The workflows in `.github/workflows/` read five secrets. Set them once in the
repo's **Settings → Secrets and variables → Actions**, or via `gh secret set`.

| Secret | Purpose | Used by |
|---|---|---|
| `GCP_PROJECT_ID` | GCP project that owns the GKE cluster and Artifact Registry | all workflows |
| `GCP_SA_KEY` | JSON key for a service account with the roles below | all workflows |
| `DT_TENANT_ID` | Dynatrace tenant short ID (e.g. `abc12345`) | cluster-up |
| `DT_API_TOKEN` | API token with operator scopes | cluster-up |
| `DT_DATA_INGEST_TOKEN` | Token with `metrics.ingest` + `openTelemetryTrace.ingest` | cluster-up |

## 1. GCP service account

```bash
PROJECT=dynatrace-dev-on-demand   # or whichever
SA_NAME=orders-demo-ci
SA_EMAIL="${SA_NAME}@${PROJECT}.iam.gserviceaccount.com"

gcloud iam service-accounts create "$SA_NAME" \
  --display-name="orders-demo CI" --project="$PROJECT"

# Roles required across the three workflows:
#   container.admin           - create/manage GKE cluster
#   artifactregistry.admin    - create AR repo; push and pull images
#   iam.serviceAccountUser    - attach default node SA to the cluster
#   compute.networkAdmin      - optional, for VPC-native cluster creation
for role in container.admin artifactregistry.admin iam.serviceAccountUser compute.networkAdmin; do
  gcloud projects add-iam-policy-binding "$PROJECT" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/${role}"
done

# Generate the JSON key
gcloud iam service-accounts keys create /tmp/orders-demo-ci.json \
  --iam-account="$SA_EMAIL"
```

## 2. Dynatrace tokens

On the tenant:

- **Access tokens** → generate `orders-demo-api` with scopes: `settings.read`,
  `settings.write`, `entities.read`, `InstallerDownload`,
  `activeGateTokenManagement.create`. (Exact list may drift; the operator
  logs tell you if a scope is missing.)
- **Access tokens** → generate `orders-demo-dataingest` with scopes:
  `metrics.ingest`, `openTelemetryTrace.ingest`.

Tenant ID is the subdomain of your live URL: `https://abc12345.live.dynatrace.com`
→ `abc12345`.

## 3. Set the secrets

```bash
gh secret set GCP_PROJECT_ID --repo mreider/orders-demo --body "dynatrace-dev-on-demand"
gh secret set GCP_SA_KEY --repo mreider/orders-demo < /tmp/orders-demo-ci.json
gh secret set DT_TENANT_ID --repo mreider/orders-demo --body "abc12345"
gh secret set DT_API_TOKEN --repo mreider/orders-demo --body "<the-api-token-value>"
gh secret set DT_DATA_INGEST_TOKEN --repo mreider/orders-demo --body "<the-data-ingest-value>"
```

## 4. Verify

```bash
gh secret list --repo mreider/orders-demo
# Should show all five.
```

## Rotation / cleanup

- Delete the key file after setting it: `rm /tmp/orders-demo-ci.json`.
- Rotate the Dynatrace tokens every 90 days on your tenant.
- Rotate the GCP service account key periodically:
  `gcloud iam service-accounts keys create ... && gh secret set GCP_SA_KEY ...`
- When the demo is over, run `cluster-down` workflow, then delete the
  service account: `gcloud iam service-accounts delete "$SA_EMAIL"`.

## Upgrade path: Workload Identity Federation

Service-account keys work but carry rotation risk. For production-grade
repos, swap `GCP_SA_KEY` for WIF:

1. Create a Workload Identity Pool + Provider trusting `token.actions.githubusercontent.com`.
2. Bind the service account to the provider with an attribute condition
   (`attribute.repository == 'mreider/orders-demo'`).
3. Replace the `google-github-actions/auth@v2` step to use
   `workload_identity_provider` + `service_account` instead of
   `credentials_json`.

Not wired into this repo; it's a minor refactor when Matthew wants it.
