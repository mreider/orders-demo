# SDv1 to SDv2: a migration presentation

A ~60-minute presentation for Dynatrace customers planning the move from Service Detection v1 to Service Detection v2 on OneAgent-monitored workloads. SDv2 for OneAgent is only available on Latest Dynatrace tenants, so this assumes you're on a Latest tenant.

The presentation is built from short section narratives paired with live demo notebooks that run against your own tenant. You can give the deck on its own, or open each demo in sequence to show the point live.

> **Roadmap snapshot: May 1, 2026.** Direction in the "What's coming" section is firm; timing is not. Core sections describe current behavior that's stable.

## Flow

1. **Follow along in your own tenant** (optional opener, setup steps).
2. **One workload, one service** (the dt.service.name fragmentation story).
3. **Three transport families** (HTTP, messaging, FaaS metrics).
4. **Dimensions, not entities** (splitting by query dimension, not by entity).
5. **SDv1 vs SDv2, side by side** (the side-by-side comparison).
6. **Where names come from** (resource attribute fallback chain).
7. **Metric-first queries** (the DQL pattern shift).
8. **The `service.name` workaround** (what to do about Classic names today).
9. **Every endpoint is baselined** (SDv2's endpoint guarantee).
10. **When `http.route` is missing** (and what's coming to fix it).
11. **Downstreams are tabs, not entities** (databases, queues, third parties).
12. **What's coming** (pipeline-side naming + SERVICE_DEPLOYMENT).

## Running the demos in your tenant

```bash
dtctl auth login
for f in presentation/*.yaml; do
  dtctl apply -f "$f" --share-environment
done
```

`--share-environment` makes each notebook visible tenant-wide. Open the Notebooks app and filter by `SDv2 demo` to find them.
