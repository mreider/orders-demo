#!/usr/bin/env bash
# Tear down orders-demo. Deletes the GKE cluster and the Artifact Registry repo.
# The Dynatrace tenant is not touched; remove the ingested data / Kubernetes
# connection from the tenant UI if you want to.

set -euo pipefail

GCP_PROJECT="${GCP_PROJECT:-your-gcp-project}"
GKE_CLUSTER="${GKE_CLUSTER:-orders-demo}"
GKE_ZONE="${GKE_ZONE:-us-central1-c}"
GKE_REGION="${GKE_REGION:-us-central1}"
AR_REPO="${AR_REPO:-orders-demo}"

log() { printf '\n\033[1;33m[down] %s\033[0m\n' "$*"; }

gcloud config set project "${GCP_PROJECT}" >/dev/null

if gcloud container clusters describe "${GKE_CLUSTER}" --zone "${GKE_ZONE}" >/dev/null 2>&1; then
  log "Deleting GKE cluster ${GKE_CLUSTER}"
  gcloud container clusters delete "${GKE_CLUSTER}" --zone "${GKE_ZONE}" --quiet
else
  log "Cluster ${GKE_CLUSTER} not found, skipping"
fi

if gcloud artifacts repositories describe "${AR_REPO}" --location "${GKE_REGION}" >/dev/null 2>&1; then
  log "Deleting Artifact Registry repo ${AR_REPO}"
  gcloud artifacts repositories delete "${AR_REPO}" --location "${GKE_REGION}" --quiet
else
  log "Artifact Registry ${AR_REPO} not found, skipping"
fi

log "Done. Remove the K8s cluster connection from the Dynatrace tenant if desired."
