# Module 0 — Lab setup

*You'll have a tenant ready to run every lab and one notebook loaded as a sanity check.*

## Two axes worth naming

This course sits at the intersection of two things that sometimes get conflated:

- **UI generation**: *Classic Dynatrace* vs *Latest Dynatrace*. This is the tenant-level app experience — the shape of the Services app, the Notebooks app, the Kubernetes app.
- **Detection model**: *Service Detection v1 (SDv1)* vs *Service Detection v2 (SDv2)*. This is how Dynatrace turns spans into service entities.

They're orthogonal in principle but coupled in practice: **SDv2 for OneAgent is available only on Latest Dynatrace**. (SDv2 for OTel-instrumented workloads works on either, but this course uses OneAgent.) So to see SDv2 on your own workload you need both: a Latest Dynatrace tenant *and* SDv2 opted in for the namespace.

Where the course says "under SDv2" or "with SDv2", the claim is about the detection model. Where it says "in Latest Dynatrace" or "the Latest Services app", the claim is about the UI.

## Prereqs

- Dynatrace SaaS tenant you can log into.
- A Kubernetes workload under monitoring, or the companion `orders-demo` deployed to any cluster (see repo root README).
- [`dtctl`](https://github.com/dynatrace-oss/dtctl) installed: `brew install dynatrace-oss/tap/dtctl`.
- Platform token (or OAuth) with: `document:documents:read`, `document:documents:write`, `document:environment-shares:read`, `document:environment-shares:write`.

## Load

```bash
dtctl auth login
for f in curriculum/**/*.yaml; do
  dtctl apply -f "$f" --write-id --share-environment
done
```

`--write-id` stamps the notebook ID back so future applies update in place. `--share-environment` makes the notebook visible tenant-wide.

Open the Notebooks app, filter by `Curriculum /`, run Module 1.1. If results come back, you're set.

## Next

**[Module 1.1 — One workload, one service.](./module-1-1-one-workload-one-service.md)**
