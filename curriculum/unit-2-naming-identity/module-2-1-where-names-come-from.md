# Module 2.1 — Where names come from

> **What you'll know by the end:** given a service in the Services app,
> you can explain which resource attribute produced its name, and what
> the fallback chain looks like when the preferred attribute is absent.

## The question

Open the Services app. Pick a service that looks well-named (e.g. a
clean string like `payments` rather than an IP with a port). Now pick
one that looks badly-named (e.g. `:8080`, `/`, or a Java fully-qualified
class name). Answer:

> *Why does one have a clean name and the other doesn't?*

The answer is a chain of span resource attributes. Whichever one
Dynatrace finds first, wins.

## The claim

Under the Latest detection model, service names are produced from span
resource attributes in this order:

1. **`service.name`** (OpenTelemetry convention). If present, used directly.
2. **`k8s.workload.name`** (with namespace scoping). If running in
   Kubernetes without `service.name`, the workload name is used.
3. **Cloud-native detection fallbacks** — for Lambda it's
   `faas.name`, for ECS it's the task family name, etc.
4. **Classic detection residue** — derived names from process-group
   fingerprinting (ports, paths, class names). This is what you see
   when nothing above fires.

Every step above the last is something you can *control* by emitting the
right resource attribute on spans. OneAgent auto-injects some of these
(k8s ones) for you in K8s environments. OTel instrumentation sets
`service.name` if you do.

## Why this matters

- **Clean names are the default you earn by instrumenting.** The Latest
  detection model's best-case naming depends on your spans, not on a
  Dynatrace-side naming rule overlay.
- **Naming rules are deprecated.** The old Services Classic overlay that
  turned `:8080` into `checkout-service` via a UI rule is going away. The
  replacement path is: set the right resource attribute on your spans,
  and Latest picks it up.
- **Filtering by deployment context is a dimension, not a name.** In
  Classic, people stuffed environment (prod/staging), region, and
  version into the service name. In Latest, the name stays clean and
  environment lives on separate dimensions (`k8s.namespace.name`,
  `deployment.environment`, `service.version`).

## The lab

**[Module 2.1 Lab — Where names come from](./module-2-1-where-names-come-from.yaml)**

Three queries:

1. **Span-level audit.** For a workload of your choice, what resource
   attributes actually arrive on the spans? This is the raw input to
   naming.
2. **Which attribute won?** Correlate the span attributes with the
   resulting entity name.
3. **Compare two workloads.** One with `service.name` set as a resource
   attribute, one without. Same k8s.workload.name either way, but the
   entity names and the `dt.service.name` dimension differ.

## What you should see

For a pure K8s-monitored Spring Boot app (OneAgent, no OTel
auto-instrumentation): `service.name` is often empty on spans. The
Latest detection model falls back to `k8s.workload.name` — so the entity
is named after the Deployment.

For an OTel-instrumented app that sets `OTEL_SERVICE_NAME=<name>`:
`service.name` is populated. The entity takes that name instead.

For a legacy service detected under Classic: the entity name is what the
detection rules produced — often ugly, often prefixed with a port or a
path. Module 2.3 shows how setting `service.name` on such a service
helps today, and what changes in the short- and long-term.

### What to look for in the Dynatrace UI

In the **Services app**, each service row has a name. Compare it
to the span-level attributes from the lab:

- Clean name matching your `service.name` value → OTel resource
  attribute won.
- Clean name matching your Kubernetes workload name → K8s fallback.
- Composite like `<your-name> (<detected-class-method>)` → the Classic
  prefix fix is active and combining both.
- Ugly detected name (`:8080`, a bare path, a class-method string) →
  fallback to Classic detection, no resource attribute in play.

Click into one and open **Properties** (or the properties side-panel
— the exact label depends on your tenant's UI version). You should
see `k8s.workload.name`, `k8s.namespace.name`, and, if set,
`service.name` listed as resource attributes. Those are the same
columns the lab's Question 1 DQL pulled.

## Next

**[Module 2.2 — Metric-first queries: skip the entity table.](./module-2-2-metric-first-queries.md)**
The second benefit of good naming is that `service.name` and
`dt.service.name` live as metric *dimensions*, not just as entity
display names. That makes your DQL dramatically shorter.
