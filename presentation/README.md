# SDv1 to SDv2: a migration presentation

A short presentation for Dynatrace customers planning the move from Service Detection v1 to Service Detection v2 on OneAgent-monitored workloads. SDv2 for OneAgent is only available on Latest Dynatrace tenants, so this assumes you're on a Latest tenant.

Two sections, one unified demo notebook. Each section pairs a short narrative with live DQL against your own tenant — give the deck on its own, or open the notebook and walk the questions live.

> **Roadmap snapshot: May 1, 2026.** Direction in the "What's coming" subsections is firm; timing is not. Core content describes current behavior that's stable (with one explicit exception: the `dt.service.request.*`-for-messaging double-count goes away in a future SDv2-for-OneAgent release).

## Flow

1. **[Follow along in your own tenant](./00-setup.md)** — optional opener, setup steps.
2. **[One workload, one service](./01-one-workload-one-service.md)** — SDv1 creates four separate `dt.entity.service` entities for one Kubernetes workload (one per controller class, one per Kafka listener, plus an actuator entity). SDv2 collapses all of them to one `UNIFIED` entity with one `dt.service.name`. `OTEL_SERVICE_NAME` works on both models — as a prefix on every SDv1 fragment, or as the outright name on SDv2.
3. **[Dimensions do the slicing](./02-dimensions-do-the-slicing.md)** — the three metric families (`request`, `messaging.process`, `faas_invoke`) that the Services app coalesces as **Transactions**; the legacy `request.*`-for-messaging double-count disappearing in a future SDv2-for-OneAgent release; `endpoint.name` with the `http.route` gap and automatic URL normalization coming; downstreams (DB, queues, outbound HTTP) as dimensions on the caller, not separate entities; and metric-first DQL that skips the entity-table join entirely.

## The unified demo notebook

One notebook, ten DQL questions (questions 1-4 cover section 1, questions 5-10 cover section 2).

```bash
dtctl auth login
dtctl apply -f presentation/sdv2-demo.yaml --share-environment --write-id
```

Or, with the current dtctl, use `scripts/load-demos.sh` (see repo root `SETUP.md`). Open the Notebooks app and filter by `SDv2 demo`.

## Files in this directory

| File | Purpose |
|---|---|
| `00-setup.md` / `.slides.md` | Optional opener — how to follow along in your own tenant |
| `01-one-workload-one-service.md` / `.slides.md` | Section 1 narrative + slides |
| `02-dimensions-do-the-slicing.md` / `.slides.md` | Section 2 narrative + slides |
| `sdv2-demo.yaml` | The single `dtctl`-applyable notebook with all ten DQL questions |
| `sdv2-presentation.pptx` | Built editable PPTX (regenerate with `scripts/build-slides.sh`) |
