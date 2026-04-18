# Module 0 — Lab setup

*You'll have a tenant ready to run every lab and one notebook loaded as a sanity check.*

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
