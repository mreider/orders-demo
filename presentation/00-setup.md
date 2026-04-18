# Follow along in your own tenant

If you want to run the demos live in your own environment, here's the 3-minute setup.

## Two axes worth naming up front

This presentation sits at the intersection of two things that get conflated:

- **UI generation**: *Classic Dynatrace* vs *Latest Dynatrace*. This is the tenant-level app experience, the shape of the Services app, the Notebooks app, the Kubernetes app.
- **Detection model**: *Service Detection v1 (SDv1)* vs *Service Detection v2 (SDv2)*. This is how Dynatrace turns spans into service entities.

They're orthogonal in principle but coupled in practice: **SDv2 for OneAgent is available only on Latest Dynatrace**. (SDv2 for OTel-instrumented workloads works on either, but this deck uses OneAgent.) To see SDv2 on your own workload you need both: a Latest Dynatrace tenant *and* SDv2 opted in for the namespace.

When we say "under SDv2", we mean the detection model. When we say "in Latest Dynatrace", we mean the UI.

## What you'll need

- Dynatrace SaaS tenant you can log into.
- A Kubernetes workload under monitoring, or the companion `orders-demo` deployed to any cluster (see repo root README).
- [`dtctl`](https://github.com/dynatrace-oss/dtctl) installed: `brew install dynatrace-oss/tap/dtctl`.
- Platform token (or OAuth) with: `document:documents:read`, `document:documents:write`, `document:environment-shares:read`, `document:environment-shares:write`.

## Load the demo notebook

```bash
dtctl auth login
dtctl apply -f presentation/sdv2-demo.yaml --share-environment
```

`--share-environment` makes the notebook visible tenant-wide. The YAML already carries the notebook's UUID, so re-applies update in place.

Open the Notebooks app, filter by `SDv2 demo`, and run the preamble tenant-health check. If three workload rows come back, you're set — then run questions 1-4 for section 1 of the deck and questions 5-10 for section 2.
