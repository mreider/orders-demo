---
title: Install the Dynatrace Operator for orders-demo
description: Step-by-step for installing the operator, creating tokens, applying the DynaKube, and opting orders-sdv2 into SDv2.
last_updated: 2026-04-17
---

# Install the Dynatrace Operator

This demo needs one Dynatrace tenant, one GKE cluster, and a DynaKube that
injects OneAgent into both `orders-sdv1` and `orders-sdv2`. The per-namespace
SDv1 vs SDv2 choice happens in the Dynatrace UI after the operator is
running.

## 1. Tenant + tokens

On your Dynatrace tenant:

1. **Access tokens** → **Generate new token** called `orders-demo-api` with scopes:
   - `Access problem and event feed, metrics, and topology` (apiToken scope `entities.read`, `settings.read`, `settings.write`)
   - `Create ActiveGate tokens` (`activeGateTokenManagement.create`)
   - `PaaS integration - installer download` (`InstallerDownload`)
   - `Read configuration`, `Write configuration`
   - (See the Dynatrace docs for the current exact list - the operator will
     tell you via events if a scope is missing.)

2. **Access tokens** → **Generate new token** called `orders-demo-dataingest` with
   scope `Ingest metrics` (`metrics.ingest`) and `Ingest OpenTelemetry traces`
   (`openTelemetryTrace.ingest`).

Save both token values - you'll need them in Step 3.

Note: Matthew's local `$dt_token` / `$dt_metrics_endpoint` env vars are
OTLP-side; they will not work for the operator. The operator needs an API
token with K8s-management scopes.

## 2. Install the operator

```bash
# Namespace for operator + CSI driver
kubectl create namespace dynatrace

# Install CSI driver + operator via the release manifest.
# Replace <VERSION> with the latest from:
#   https://github.com/Dynatrace/dynatrace-operator/releases
kubectl apply -f https://github.com/Dynatrace/dynatrace-operator/releases/download/<VERSION>/kubernetes.yaml

# Wait for the operator and CSI driver to be Ready.
kubectl -n dynatrace wait pod --for=condition=Ready --selector=app.kubernetes.io/name=dynatrace-operator --timeout=180s
kubectl -n dynatrace rollout status daemonset/dynatrace-oneagent-csi-driver
```

## 3. Create the token Secret

```bash
kubectl -n dynatrace create secret generic dynakube \
  --from-literal=apiToken='<API_TOKEN_FROM_STEP_1>' \
  --from-literal=dataIngestToken='<DATA_INGEST_TOKEN_FROM_STEP_1>'
```

The Secret name (`dynakube`) must match `spec.tokens` in
[dynakube.yaml](dynakube.yaml).

## 4. Apply the DynaKube

```bash
# Edit dynakube.yaml and replace <YOUR_TENANT_ID>.
kubectl apply -f dynatrace/dynakube.yaml

# Verify the ActiveGate and OneAgent DaemonSet come up.
kubectl -n dynatrace get pods -w
```

Once the DynaKube is healthy, any pod created in a namespace labeled
`dynatrace: "enabled"` gets OneAgent injected. Both `orders-sdv1` and
`orders-sdv2` carry that label (see [k8s/00-namespaces.yaml](../k8s/00-namespaces.yaml)).

## 5. Opt `orders-sdv2` into SDv2 - **this is the switch**

In the Dynatrace UI:

1. Go to **Kubernetes Classic** → find the cluster you just added.
2. Drill to the **`orders-sdv2`** namespace.
3. **Settings** → **Service detection** → **Service Detection v2 for OneAgent**.
4. Enable **Service detection v2 for Kubernetes workloads**.
5. Save.

Leave `orders-sdv1` on default (SDv1) behavior.

Screenshot guidance: capture the settings toggle before and after flipping
it - useful for the docs/03 rung discussion later.

**Verify the asymmetry:**

- Under **Services**, you should start to see two different detections for the
  same `orders-demo` Deployment - one per namespace.
- `orders-sdv1`: classic process-group-based detection. Likely one service
  whose name reflects the Tomcat process and port.
- `orders-sdv2`: SDv2 detection. The service name will be `orders-demo`
  (the Deployment / `k8s.workload.name`). Endpoints baselined automatically.

Baselines need ~15 minutes of traffic to form. The load generator Job
runs 30 minutes by default, which is plenty.

## 6. Teardown

```bash
kubectl delete -f dynatrace/dynakube.yaml
kubectl delete namespace dynatrace
# Full GKE teardown: scripts/down.sh
```

## Known unknowns

- **Settings-as-code for the SDv2 toggle.** The per-namespace opt-in lives in
  Settings 2.0 but the exact schema key is not documented publicly as of
  2026-04. Step 5 is a manual UI click. If this becomes an obstacle, the
  Settings API can likely set it - open a ticket with the SDv2 team.
- **DynaKube apiVersion.** This file uses `dynatrace.com/v1beta3`. Newer
  operator releases may have moved to `v1`. Match the version in the release
  manifest you installed in Step 2.
