#!/usr/bin/env bash
# Tear down the orders-demo generic-workload VM.
#
# Deletes the GCE instance. The Dynatrace tenant is not touched - remove the
# host / ingested data from the tenant UI if you want to, and rotate the
# OneAgent token that was passed via instance metadata.
set -euo pipefail

GCP_PROJECT="${GCP_PROJECT:-dynatrace-dev-on-demand}"
GKE_ZONE="${GKE_ZONE:-us-central1-c}"
VM_NAME="${VM_NAME:-orders-demo-vm}"

log() { printf '\n\033[1;33m[vm-down] %s\033[0m\n' "$*"; }

gcloud config set project "${GCP_PROJECT}" >/dev/null

if gcloud compute instances describe "${VM_NAME}" --zone "${GKE_ZONE}" >/dev/null 2>&1; then
  log "Deleting VM ${VM_NAME}"
  gcloud compute instances delete "${VM_NAME}" --zone "${GKE_ZONE}" --quiet
else
  log "VM ${VM_NAME} not found, skipping"
fi

log "Done. Remove the host from the Dynatrace tenant and rotate the OneAgent token if desired."
