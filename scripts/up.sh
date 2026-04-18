#!/usr/bin/env bash
# Bring up the orders-demo on GKE end to end.
#
# Required env vars:
#   DT_API_URL             Full API URL, e.g. https://abc.live.dynatrace.com/api
#   DT_API_TOKEN           API token with operator scopes
#   DT_DATA_INGEST_TOKEN   Token with metrics.ingest + openTelemetryTrace.ingest
#
# Optional env vars (defaults shown):
#   GCP_PROJECT            your-gcp-project
#   GKE_CLUSTER            orders-demo
#   GKE_REGION             us-central1
#   GKE_ZONE               us-central1-c
#   ORDERS_IMAGE           ghcr.io/mreider/orders-demo:latest
#                          (override to pull from your own registry)
#   BUILD_LOCAL            unset = pull ORDERS_IMAGE from its registry
#                          any value = build ./app and push to ORDERS_IMAGE
#                          (BUILD_LOCAL also requires docker + credentials
#                           for the target registry)
#   OPERATOR_VERSION       (resolved from Dynatrace Operator latest release)

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

: "${DT_API_URL:?DT_API_URL is required}"
: "${DT_API_TOKEN:?DT_API_TOKEN is required}"
: "${DT_DATA_INGEST_TOKEN:?DT_DATA_INGEST_TOKEN is required}"

GCP_PROJECT="${GCP_PROJECT:-your-gcp-project}"
GKE_CLUSTER="${GKE_CLUSTER:-orders-demo}"
GKE_REGION="${GKE_REGION:-us-central1}"
GKE_ZONE="${GKE_ZONE:-us-central1-c}"
export ORDERS_IMAGE="${ORDERS_IMAGE:-ghcr.io/mreider/orders-demo:latest}"

log() { printf '\n\033[1;36m[up] %s\033[0m\n' "$*"; }

# ---- 1. prereqs ----
log "Checking prerequisites"
PREREQS="gcloud kubectl envsubst"
[ -n "${BUILD_LOCAL:-}" ] && PREREQS="$PREREQS docker"
for bin in $PREREQS; do
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

# ---- 3. app image ----
if [ -n "${BUILD_LOCAL:-}" ]; then
  log "Building ${ORDERS_IMAGE} locally"
  (cd "${ROOT}/app" && docker build -t "${ORDERS_IMAGE}" .)
  log "Pushing ${ORDERS_IMAGE}"
  docker push "${ORDERS_IMAGE}"
else
  log "Using pre-built ${ORDERS_IMAGE} (set BUILD_LOCAL=1 to build from ./app)"
fi

# ---- 4. Dynatrace operator ----
OPERATOR_VERSION="${OPERATOR_VERSION:-$(curl -s https://api.github.com/repos/Dynatrace/dynatrace-operator/releases/latest | grep tag_name | head -1 | cut -d '"' -f 4)}"
log "Installing Dynatrace Operator ${OPERATOR_VERSION}"
kubectl create namespace dynatrace --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f "https://github.com/Dynatrace/dynatrace-operator/releases/download/${OPERATOR_VERSION}/kubernetes.yaml"
kubectl -n dynatrace wait pod \
  --for=condition=Ready \
  --selector=app.kubernetes.io/name=dynatrace-operator \
  --timeout=300s

# ---- 5. DynaKube secret + CR ----
log "Creating DynaKube secret"
kubectl -n dynatrace create secret generic dynakube \
  --from-literal=apiToken="${DT_API_TOKEN}" \
  --from-literal=dataIngestToken="${DT_DATA_INGEST_TOKEN}" \
  --dry-run=client -o yaml | kubectl apply -f -

log "Applying DynaKube"
sed "s|<DT_API_URL>|${DT_API_URL}|g" "${ROOT}/dynatrace/dynakube.yaml" | kubectl apply -f -

# ---- 6. namespaces + infra + apps ----
log "Applying namespaces and infra (Postgres + Redpanda in each namespace)"
kubectl apply -f "${ROOT}/k8s/00-namespaces.yaml"
kubectl apply -f "${ROOT}/k8s/10-postgres.yaml"
kubectl apply -f "${ROOT}/k8s/20-redpanda.yaml"

log "Waiting for Postgres and Redpanda to be ready"
for ns in orders-sdv1 orders-sdv2; do
  kubectl -n "${ns}" rollout status statefulset/postgres --timeout=180s
  kubectl -n "${ns}" rollout status statefulset/redpanda --timeout=180s
done

log "Applying app Deployments (image: ${ORDERS_IMAGE})"
envsubst < "${ROOT}/k8s/30-app.yaml"       | kubectl apply -f -
envsubst < "${ROOT}/k8s/31-app-named.yaml" | kubectl apply -f -

for ns in orders-sdv1 orders-sdv2; do
  kubectl -n "${ns}" rollout status deployment/orders-demo --timeout=300s
done
kubectl -n orders-sdv1 rollout status deployment/orders-demo-named --timeout=300s

# ---- 7. load gen ----
log "Creating load-gen ConfigMaps from load/loadtest.js"
for ns in orders-sdv1 orders-sdv2; do
  kubectl -n "${ns}" create configmap loadtest-script \
    --from-file=loadtest.js="${ROOT}/load/loadtest.js" \
    --dry-run=client -o yaml | kubectl apply -f -
done

log "Applying load Jobs"
kubectl apply -f "${ROOT}/k8s/40-load.yaml"
kubectl apply -f "${ROOT}/k8s/41-load-named.yaml"

# ---- 8. next steps ----
cat <<EOF

======================================================================
orders-demo is deploying.

Next steps (manual):

1. Opt orders-sdv2 into SDv2 detection:
   Dynatrace UI > Kubernetes > ${GKE_CLUSTER} > namespace orders-sdv2
   > Settings > Service detection > Service Detection v2 for OneAgent > enable.
   (Leave orders-sdv1 on default SDv1.)

2. Wait ~5 minutes for the UNIFIED entity to appear.

3. Load the curriculum notebooks into your tenant:
   export DT_ENV=https://<your-tenant>.apps.dynatrace.com
   export DT_PLATFORM_TOKEN=dt0s16.XXXX...
   ./scripts/load-curriculum.sh

4. Walk the curriculum:
   Notebooks app > filter "Curriculum /" > Module 0 > run in order.

Teardown: ./scripts/down.sh
======================================================================
EOF
