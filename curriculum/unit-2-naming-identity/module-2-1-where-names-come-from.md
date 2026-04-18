# Module 2.1 — Where names come from

*Given a service in the Services app, explain which resource attribute produced its name and what the fallback chain looks like when the preferred attribute is absent.*

## The question

Pick a well-named service (e.g. `payments`) and a badly-named one (e.g. `:8080`, a class path).

> *Why does one have a clean name and the other doesn't?*

## The claim

Under SDv2, service names come from span resource attributes in this order, first-match-wins:

1. **`service.name`** (OpenTelemetry). Used directly if present.
2. **`k8s.workload.name`** (with namespace scoping). Used if no `service.name`.
3. **Cloud-native fallbacks** — `faas.name` for Lambda, task family for ECS, etc.
4. **SDv1 detection residue** — process-group fingerprinting (ports, paths, class names).

Steps 1–3 are controllable: emit the right attribute on spans and Latest picks it up. OneAgent auto-injects K8s attributes. OTel instrumentation sets `service.name` if you do.

## The lab

**[Module 2.1 Lab — Where names come from](./module-2-1-where-names-come-from.yaml)**

- Audit the resource attributes arriving on spans for a workload.
- Correlate span attributes with the resulting `dt.service.name`.
- Compare two workloads — one with `OTEL_SERVICE_NAME` set, one without.

## What you should see

- K8s Spring Boot, no OTel: `service.name` empty → falls back to `k8s.workload.name`.
- OTel app with `OTEL_SERVICE_NAME=foo`: `service.name=foo`, entity named `foo`.
- SDv1-detected service: ugly names, Module 2.3 covers the fix.

## In the Dynatrace UI

- Service row name matching `service.name` → OTel won.
- Name matching K8s workload → K8s fallback.
- Composite like `<your-name> (<detected>)` → Classic prefix fix is active (Module 2.3).
- Ugly detected string (`:8080`, bare path) → fallback to Classic residue.

## Next

**[Module 2.2 — Metric-first queries.](./module-2-2-metric-first-queries.md)**
