---
title: orders-demo
last_updated: 2026-04-18
---

# orders-demo

A Spring Boot application plus a presentation on the Service Detection v1 to Service Detection v2 migration for OneAgent-monitored workloads. SDv2 for OneAgent is available only on Latest Dynatrace tenants; the presentation assumes a Latest tenant.

## What this is

- A deliberately-small Spring Boot monolith (two REST controllers, a Kafka consumer, a JDBC client) deployed to Kubernetes.
- The same image runs in two namespaces on the same cluster:
  - `orders-sdv1`: SDv1 detection, plus a second workload (`orders-demo-named`) with `OTEL_SERVICE_NAME` set, which powers the `service.name` fix demo.
  - `orders-sdv2`: opted into SDv2 detection.
- Identical traffic runs against each side. Every difference you see in the Dynatrace tenant is attributable to the detection model, not the app.
- A presentation under `presentation/` walks the migration in sections. Each section is a short narrative + a live demo notebook that runs against the speaker's (or customer's) own tenant, with the demo app as a fallback when the tenant lacks a workload with the right shape.

## Who this is for

- Dynatrace customers planning the SDv1 to SDv2 move.
- Field teams who want a repeatable hands-on to show what changes and why.
- Anyone who wants to see the difference live in their tenant before committing.

## What this is not

- Not a reference architecture. The app is crafted for the talk track, not production.
- Not a performance benchmark. Failure rates and latency are seeded.

## Setup

See **[SETUP.md](SETUP.md)** for a start-to-finish guide: prereqs, Dynatrace tokens, GKE cluster, Operator install, app deploy, loading the demo notebooks, and opting the `orders-sdv2` namespace into SDv2.

## The presentation

See **[presentation/README.md](presentation/README.md)** for the section index and flow. Give it as a talk, or open each demo live to show the point in the speaker's own tenant.

## Layout

```
app/          Spring Boot source
k8s/          Kubernetes manifests (namespaces, Postgres, Redpanda, app, loadgen)
dynatrace/    DynaKube CR
scripts/      up.sh / down.sh (local) + load-demos.sh (demo loader)
load/         k6 loadgen script
presentation/   Presentation sections (narrative markdown + demo notebook YAML + Marp slides + 1 pptx)
notebooks/    home.yaml: the presentation's landing notebook
.github/workflows/   cluster-up, cluster-down, build, deploy, release
```

## Slides

The presentation ships as a single editable deck at
`presentation/sdv2-presentation.pptx`, covering every section in order.
For most uses the committed PPTX is enough; open it in PowerPoint and
edit freely. Per-section Marp sources live alongside each section as
`.slides.md` if you want to tweak one piece without touching the rest.

To rebuild the PPTX after editing any `.slides.md`:

```bash
./scripts/build-slides.sh
```

The build concatenates every `.slides.md` into one Marp document and
runs a Marp-to-PptxGenJS converter (`md-to-pptx`). Point `MDTPPX_DIR`
at your clone, or edit `build-slides.sh` to call whichever
Marp-to-editable-PPTX tool you prefer.

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

- `sdv2-presentation-<tag>.pptx`: single editable deck, every section.
- `sdv2-demos-<tag>.zip`: the demo notebook YAMLs + home notebook.
- `sdv2-presentation-full-<tag>.tar.gz`: the whole presentation tree (markdown + YAML + Marp source + pptx + SETUP.md).

The app image is not a release artifact — `build.yml` already pushes
it to `ghcr.io` on every main-branch commit.

## License

[MIT](LICENSE).
