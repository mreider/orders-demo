#!/usr/bin/env bash
# Bring up the orders-demo on GKE end to end.
#
# Required env vars:
#   DT_TENANT_ID           Dynatrace tenant (e.g. abc12345)
#   DT_API_TOKEN           API token with operator scopes
#   DT_DATA_INGEST_TOKEN   Token with metrics.ingest + openTelemetryTrace.ingest
#
# Optional env vars (with defaults):
#   GCP_PROJECT            dynatrace-dev-on-demand
#   GKE_CLUSTER            orders-demo
#   GKE_REGION             us-central1
#   GKE_ZONE               us-central1-c
#   AR_REPO                orders-demo
#   IMAGE_TAG              1.0.0
#   OPERATOR_VERSION       (resolved from GitHub latest release)
#
# Usage:
#   DT_TENANT_ID=abc12345 DT_API_TOKEN=... DT_DATA_INGEST_TOKEN=... ./scripts/up.sh

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

: "${DT_TENANT_ID:?DT_TENANT_ID is required}"
: "${DT_API_TOKEN:?DT_API_TOKEN is required}"
: "${DT_DATA_INGEST_TOKEN:?DT_DATA_INGEST_TOKEN is required}"

GCP_PROJECT="${GCP_PROJECT:-dynatrace-dev-on-demand}"
GKE_CLUSTER="${GKE_CLUSTER:-orders-demo}"
GKE_REGION="${GKE_REGION:-us-central1}"
GKE_ZONE="${GKE_ZONE:-us-central1-c}"
AR_REPO="${AR_REPO:-orders-demo}"
IMAGE_TAG="${IMAGE_TAG:-1.0.0}"

IMAGE_BASE="${GKE_REGION}-docker.pkg.dev/${GCP_PROJECT}/${AR_REPO}"
export ORDERS_IMAGE="${IMAGE_BASE}/orders-demo:${IMAGE_TAG}"

log() { printf '\n\033[1;36m[up] %s\033[0m\n' "$*"; }

# ---- 1. prereqs ----
log "Checking prerequisites"
for bin in gcloud kubectl docker envsubst; do
  command -v "$bin" >/dev/null || { echo "missing: $bin"; exit 1; }
done

# ---- 2. GCP project / cluster ----
log "Targeting GCP project ${GCP_PROJECT}"
gcloud config set project "${GCP_PROJECT}" >/dev/null

if ! gcloud container clusters describe "${GKE_CLUSTER}" --zone "${GKE_ZONE}" >/dev/null 2>&1; then
  log "Creating GKE cluster ${GKE_CLUSTER} in ${GKE_ZONE} (this takes 3-5 minutes)"
  gcloud container clusters create "${GKE_CLUSTER}" \
    --zone "${GKE_ZONE}" \
    --num-nodes 3 \
    --machine-type e2-standard-4 \
    --release-channel regular \
    --enable-ip-alias \
    --workload-pool "${GCP_PROJECT}.svc.id.goog"
else
  log "Cluster ${GKE_CLUSTER} already exists"
fi

gcloud container clusters get-credentials "${GKE_CLUSTER}" --zone "${GKE_ZONE}"

# ---- 3. Artifact Registry ----
log "Ensuring Artifact Registry repo ${AR_REPO}"
if ! gcloud artifacts repositories describe "${AR_REPO}" --location "${GKE_REGION}" >/dev/null 2>&1; then
  gcloud artifacts repositories create "${AR_REPO}" \
    --repository-format=docker \
    --location="${GKE_REGION}"
fi
gcloud auth configure-docker "${GKE_REGION}-docker.pkg.dev" --quiet

# ---- 4. build + push app image ----
log "Building ${ORDERS_IMAGE}"
(cd "${ROOT}/app" && docker build -t "${ORDERS_IMAGE}" .)
log "Pushing ${ORDERS_IMAGE}"
docker push "${ORDERS_IMAGE}"

# ---- 5. Dynatrace operator ----
OPERATOR_VERSION="${OPERATOR_VERSION:-$(curl -s https://api.github.com/repos/Dynatrace/dynatrace-operator/releases/latest | grep tag_name | head -1 | cut -d '"' -f 4)}"
log "Installing Dynatrace Operator ${OPERATOR_VERSION}"
kubectl create namespace dynatrace --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f "https://github.com/Dynatrace/dynatrace-operator/releases/download/${OPERATOR_VERSION}/kubernetes.yaml"
kubectl -n dynatrace wait pod \
  --for=condition=Ready \
  --selector=app.kubernetes.io/name=dynatrace-operator \
  --timeout=300s

# ---- 6. DynaKube secret + CR ----
log "Creating DynaKube secret"
kubectl -n dynatrace create secret generic dynakube \
  --from-literal=apiToken="${DT_API_TOKEN}" \
  --from-literal=dataIngestToken="${DT_DATA_INGEST_TOKEN}" \
  --dry-run=client -o yaml | kubectl apply -f -

log "Applying DynaKube"
export DT_TENANT_ID
envsubst < "${ROOT}/dynatrace/dynakube.yaml" | sed "s|<YOUR_TENANT_ID>|${DT_TENANT_ID}|g" | kubectl apply -f -

# ---- 7. namespaces + infra + app ----
log "Applying namespaces and infra"
kubectl apply -f "${ROOT}/k8s/00-namespaces.yaml"
kubectl apply -f "${ROOT}/k8s/10-postgres.yaml"
kubectl apply -f "${ROOT}/k8s/20-redpanda.yaml"

log "Waiting for Postgres and Redpanda to be ready"
for ns in orders-sdv1 orders-sdv2; do
  kubectl -n "${ns}" rollout status statefulset/postgres --timeout=180s
  kubectl -n "${ns}" rollout status statefulset/redpanda --timeout=180s
done

log "Applying app Deployments (image: ${ORDERS_IMAGE})"
envsubst < "${ROOT}/k8s/30-app.yaml" | kubectl apply -f -

for ns in orders-sdv1 orders-sdv2; do
  kubectl -n "${ns}" rollout status deployment/orders-demo --timeout=300s
done

# ---- 8. load gen (create ConfigMap from the real k6 script, then apply Job) ----
log "Creating load-gen ConfigMaps from load/loadtest.js"
for ns in orders-sdv1 orders-sdv2; do
  kubectl -n "${ns}" create configmap loadtest-script \
    --from-file=loadtest.js="${ROOT}/load/loadtest.js" \
    --dry-run=client -o yaml | kubectl apply -f -
done

log "Applying load Jobs"
# The manifest re-declares the ConfigMap as a placeholder; we have the real
# ConfigMap above, so apply just the Job parts. envsubst is not needed here.
kubectl apply -f "${ROOT}/k8s/40-load.yaml"

# ---- 9. final instructions ----
cat <<EOF

======================================================================
Orders-demo is deploying.

Next steps (manual):

1. In the Dynatrace UI, go to Kubernetes Classic > ${GKE_CLUSTER} >
   namespace 'orders-sdv2' > Settings > Service detection >
   Service Detection v2 for OneAgent > enable.

   Leave 'orders-sdv1' on default (SDv1).

2. Wait about 15 minutes for baselines to form.

3. Walk the ladder starting at:
   ${ROOT}/docs/00-anchor.md

4. For Rung 3 (namespace-is-a-dimension), apply the staging manifest:
   kubectl apply -f ${ROOT}/k8s/50-sdv2-staging.yaml
   Then opt that namespace into SDv2 the same way as step 1.

Teardown: ./scripts/down.sh
======================================================================
EOF
