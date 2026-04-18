# Where names come from

Every service name in your tenant traces back to a single attribute on a span. Know the fallback chain and ugly names stop being mysterious.

## Names come from span resource attributes, first-match-wins

Under SDv2, service names resolve from span resource attributes in this order:

1. **`service.name`** (OpenTelemetry). Used directly if present.
2. **`k8s.workload.name`** (namespace-scoped). Used when `service.name` is absent.
3. **Cloud-native fallbacks**. `faas.name` for Lambda, task family for ECS, and so on.
4. **SDv1 detection residue**. Process-group fingerprinting: ports, paths, class names.

Steps 1 through 3 are under your control. Emit the right attribute on spans and Latest picks it up. OneAgent auto-injects the K8s attributes. OTel instrumentation sets `service.name` if you configure it.

## SDv1 runs the same chain, then fragments

SDv1 applies the same fallback chain, but the detection layer then produces per-class fragments of the resulting name: `<detected> - OrderController`, `OrderEventsListener`, and so on. That is why a single Spring Boot workload routinely shows up as seven different `dt.service.name` values on a Grail tenant.

The name you see in the Services app is not arbitrary. It is the output of that chain, occasionally sliced by SDv1 detection into per-class fragments.

## See it live

**[Demo: Where names come from](./05-where-names-come-from.yaml)**

- Audit the resource attributes arriving on spans for a given workload.
- Correlate span attributes with the resulting `dt.service.name`.
- Compare two workloads side-by-side: one with `OTEL_SERVICE_NAME` set, one without.

## What it looks like in the UI

- Row name matches `service.name` on the span: OTel won.
- Row name matches the K8s workload: K8s fallback fired.
- Composite like `<your-name> (<detected>)`: the Classic prefix fix is in effect (covered later in the service.name workaround section).
- Ugly detected string like `:8080` or a bare path: you fell all the way through to SDv1 residue.
