#!/usr/bin/env bash
# GCE startup script for the orders-demo generic-workload VM.
#
# Runs as root on first boot. Reads its configuration from instance metadata
# (set by scripts/vm-up.sh), installs Docker + the Dynatrace OneAgent host
# agent, clones this repo, and brings up the vm/docker-compose.yml stack.
#
# Idempotent-ish: re-running skips OneAgent if already installed and re-applies
# the compose stack.
set -euo pipefail
exec > >(tee -a /var/log/orders-demo-startup.log) 2>&1
echo "[startup] $(date -u) begin"

meta() {
  curl -s -H "Metadata-Flavor: Google" \
    "http://metadata.google.internal/computeMetadata/v1/instance/attributes/$1" || true
}

DT_API_URL="$(meta dt-api-url)"
DT_PAAS_TOKEN="$(meta dt-paas-token)"
HOST_GROUP="$(meta host-group)"
ORDERS_IMAGE="$(meta orders-image)"
REPO_URL="$(meta repo-url)"
REPO_REF="$(meta repo-ref)"

HOST_GROUP="${HOST_GROUP:-orders-demo-vm}"
ORDERS_IMAGE="${ORDERS_IMAGE:-ghcr.io/mreider/orders-demo:latest}"
REPO_URL="${REPO_URL:-https://github.com/mreider/orders-demo.git}"
REPO_REF="${REPO_REF:-ee-demo}"

# ---- 1. base packages + Docker ----
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y git curl ca-certificates
if ! command -v docker >/dev/null 2>&1; then
  echo "[startup] installing Docker"
  curl -fsSL https://get.docker.com | sh
fi
systemctl enable --now docker

# ---- 2. Dynatrace OneAgent (host agent) ----
# This is the classic host OneAgent - NOT the K8s operator. It deep-monitors
# the container processes (nginx, the JVM) on this host. The host group lets
# the SDv2 generic-workloads opt-in target exactly this VM.
if [ ! -d /opt/dynatrace/oneagent ]; then
  if [ -n "$DT_API_URL" ] && [ -n "$DT_PAAS_TOKEN" ]; then
    echo "[startup] installing OneAgent (host group: ${HOST_GROUP})"
    curl -fsSL -o /tmp/oneagent.sh \
      "${DT_API_URL}/v1/deployment/installer/agent/unix/default/latest?arch=x86&flavor=default" \
      -H "Authorization: Api-Token ${DT_PAAS_TOKEN}"
    sh /tmp/oneagent.sh \
      --set-host-group="${HOST_GROUP}" \
      --set-app-log-content-access=true \
      --set-infra-only=false
    rm -f /tmp/oneagent.sh
  else
    echo "[startup] WARN: dt-api-url / dt-paas-token metadata missing - skipping OneAgent install"
  fi
else
  echo "[startup] OneAgent already present, skipping install"
fi

# ---- 3. workload stack ----
mkdir -p /opt
if [ ! -d /opt/orders-demo ]; then
  git clone --depth 1 --branch "${REPO_REF}" "${REPO_URL}" /opt/orders-demo
else
  git -C /opt/orders-demo fetch --depth 1 origin "${REPO_REF}" && git -C /opt/orders-demo checkout "${REPO_REF}" && git -C /opt/orders-demo pull --ff-only || true
fi

cd /opt/orders-demo/vm
echo "ORDERS_IMAGE=${ORDERS_IMAGE}" > .env
echo "[startup] bringing up compose stack with ${ORDERS_IMAGE}"
docker compose pull
docker compose up -d

echo "[startup] $(date -u) done"
