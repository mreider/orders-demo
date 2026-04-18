---
title: orders-demo
last_updated: 2026-04-18
---

# orders-demo

A Spring Boot application + a 90-minute Dynatrace curriculum for existing customers migrating from Classic to the Latest Services app.

## What this is

- A deliberately-small Spring Boot monolith (two REST controllers, a Kafka consumer, a JDBC client) deployed to Kubernetes.
- The same image runs in two namespaces on the same cluster:
  - `orders-sdv1` — Classic detection (SDv1), plus a second workload (`orders-demo-named`) with `OTEL_SERVICE_NAME` set, for the `service.name` workaround lab.
  - `orders-sdv2` — opted into Latest detection (SDv2).
- Identical traffic runs against each side. Every difference you see in the Dynatrace tenant is attributable to detection, not to the app.
- A 13-module curriculum under `curriculum/` teaches the Classic→Latest transition. Each module is a short markdown narrative + an executable Dynatrace notebook that runs against the learner's own tenant, with the demo app as a fallback when the tenant lacks a workload with the right shape.

## What this is for

- **Field enablement** — a reproducible hands-on for customers evaluating SDv2 or planning the move.
- **Self-paced learning** — customers load the notebooks into their own tenant and walk the curriculum in ~90 minutes.
- **Slide source of truth** — each module ships an editable PPTX alongside the Marp markdown source (see below).

## What this is not

- Not a reference architecture. The app is crafted for pedagogy, not production.
- Not a performance benchmark. Failure rates and latency are seeded.

## Setup

See **[SETUP.md](SETUP.md)** for a start-to-finish guide: prereqs, Dynatrace tokens, GKE cluster, Operator install, app deploy, loading the curriculum notebooks, and opting the `orders-sdv2` namespace into SDv2.

## Learn

See **[curriculum/README.md](curriculum/README.md)** for the course index. Three units, twelve labs plus two forward-looking readings. Start at Module 0 (lab setup) and walk in order.

## Layout

```
app/          Spring Boot source
k8s/          Kubernetes manifests (namespaces, Postgres, Redpanda, app, loadgen)
dynatrace/    DynaKube CR
scripts/      up.sh / down.sh (local) + load-curriculum.sh (notebook loader)
load/         k6 loadgen script
curriculum/   13-module course (markdown + notebook YAML + Marp slides + pptx)
notebooks/    home.yaml — the curriculum's landing notebook
.github/workflows/   cluster-up, cluster-down, build, deploy, release
```

## Slides

Each module ships with an editable `.pptx` alongside its `.slides.md`
Marp source. For most uses the committed PPTX files are enough — open
them in PowerPoint, edit freely. If you need to rebuild from the Marp
source (after editing `.slides.md`), run:

```bash
./scripts/build-slides.sh
```

The rebuild uses a Marp→PptxGenJS converter (`md-to-pptx`). If you
don't have one, any Marp-compatible tool that produces editable PPTX
will do; point `MDTPPX_DIR` at its path or edit `build-slides.sh` to
call your tool.

## Container image

The app image is built by `.github/workflows/build.yml` on every push
to `main` and published to the GitHub Container Registry:

- `ghcr.io/mreider/orders-demo:latest`
- `ghcr.io/mreider/orders-demo:<sha>`

`scripts/up.sh` pulls `:latest` by default, so you don't need to build
locally. Set `BUILD_LOCAL=1` and/or override `ORDERS_IMAGE` if you want
to build from source and push to your own registry.

## Releases

Tag and push to cut a GitHub Release that bundles:

- `curriculum-slides-<tag>.zip` — all 13 PPTX + Marp source.
- `curriculum-notebooks-<tag>.zip` — 11 lab YAMLs + home notebook.
- `curriculum-full-<tag>.tar.gz` — the whole teaching tree (markdown + YAML + slides + PPTX + SETUP.md).

The app image is not a release artifact — `build.yml` already pushes
it to `ghcr.io` on every main-branch commit.

## License

[MIT](LICENSE).
