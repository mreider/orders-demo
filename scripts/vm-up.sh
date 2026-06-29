#!/usr/bin/env bash
# Provision the orders-demo generic-workload VM on GCE.
#
# Creates one Linux VM that runs the OneAgent host agent plus an
# nginx -> orders-demo app -> Postgres/Kafka stack (see vm/docker-compose.yml).
# This is the NON-Kubernetes demo for SDv2 for generic workloads (Preview).
#
# The VM clones this repo at REPO_REF on boot, so the vm/ files must be pushed
# to that branch before (or shortly after) the VM comes up.
#
# Required env vars:
#   DT_API_URL    Full API URL, e.g. https://abl46885.dev.dynatracelabs.com/api
#   DT_API_TOKEN  Token with InstallerDownload scope (used to fetch OneAgent)
#
# Optional env vars (defaults shown):
#   GCP_PROJECT   dynatrace-dev-on-demand
#   GKE_ZONE      us-central1-c
#   VM_NAME       orders-demo-vm
#   MACHINE_TYPE  e2-standard-2
#   HOST_GROUP    orders-demo-vm
#   ORDERS_IMAGE  ghcr.io/mreider/orders-demo:latest
#   REPO_URL      https://github.com/mreider/orders-demo.git
#   REPO_REF      ee-demo
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

: "${DT_API_URL:?DT_API_URL is required}"
: "${DT_API_TOKEN:?DT_API_TOKEN is required (InstallerDownload scope)}"

GCP_PROJECT="${GCP_PROJECT:-dynatrace-dev-on-demand}"
GKE_ZONE="${GKE_ZONE:-us-central1-c}"
VM_NAME="${VM_NAME:-orders-demo-vm}"
MACHINE_TYPE="${MACHINE_TYPE:-e2-standard-2}"
HOST_GROUP="${HOST_GROUP:-orders-demo-vm}"
ORDERS_IMAGE="${ORDERS_IMAGE:-ghcr.io/mreider/orders-demo:latest}"
REPO_URL="${REPO_URL:-https://github.com/mreider/orders-demo.git}"
REPO_REF="${REPO_REF:-ee-demo}"

log() { printf '\n\033[1;36m[vm-up] %s\033[0m\n' "$*"; }

log "Targeting GCP project ${GCP_PROJECT}"
gcloud config set project "${GCP_PROJECT}" >/dev/null

if gcloud compute instances describe "${VM_NAME}" --zone "${GKE_ZONE}" >/dev/null 2>&1; then
  log "VM ${VM_NAME} already exists in ${GKE_ZONE} - nothing to do"
  exit 0
fi

# NOTE: the OneAgent token is passed via instance metadata. Anyone with read
# access to this instance's metadata can read it. Acceptable for a short-lived
# dev-tenant demo VM; rotate the token when you tear the demo down.
log "Creating VM ${VM_NAME} (${MACHINE_TYPE}) in ${GKE_ZONE}"
gcloud compute instances create "${VM_NAME}" \
  --zone "${GKE_ZONE}" \
  --machine-type "${MACHINE_TYPE}" \
  --image-family ubuntu-2204-lts \
  --image-project ubuntu-os-cloud \
  --boot-disk-size 30GB \
  --labels "purpose=orders-demo,demo=sdv2-generic-workloads" \
  --metadata "dt-api-url=${DT_API_URL},dt-paas-token=${DT_API_TOKEN},host-group=${HOST_GROUP},orders-image=${ORDERS_IMAGE},repo-url=${REPO_URL},repo-ref=${REPO_REF}" \
  --metadata-from-file "startup-script=${ROOT}/vm/startup.sh"

cat <<EOF

======================================================================
VM ${VM_NAME} is booting. The startup script will:
  1. install Docker
  2. install the OneAgent host agent (host group: ${HOST_GROUP})
  3. clone ${REPO_URL} @ ${REPO_REF} and run vm/docker-compose.yml

Watch progress:
  gcloud compute ssh ${VM_NAME} --zone ${GKE_ZONE} --command 'sudo tail -f /var/log/orders-demo-startup.log'

Then in the tenant, the host appears under host group "${HOST_GROUP}".
Opt it into SDv2 for generic workloads with a matching condition on the
host group / host name (see vm/README.md).

Teardown: scripts/vm-down.sh
======================================================================
EOF
