# Module 2.3 — The `service.name` workaround for Classic services

> **What you'll know by the end:** for any Classic-detected workload with
> an ugly name or limited query ergonomics today, you can explain
> exactly what setting `service.name` on spans gets you, what it
> doesn't, and when the remaining gaps will close.

## The question

You have a Classic-detected service in your tenant. Its name is `:8080`,
or `OrderController`, or a Java class path. You can't query it cleanly
by name because there's no `service.name` dimension on its metrics. And
your naming rules overlay is deprecated — it works today but won't in
the Latest Services app.

> *What can you do this month, without a Dynatrace release, to make
> that service queryable and readable?*

## The claim

Set `service.name` as a resource attribute on that workload's spans.
You get **three immediate wins today**, and **one deferred win**:

| Benefit | Delivered today? | How |
|---|---|---|
| `service.name` as a queryable metric dimension | **Yes** | Standard metric extraction propagates resource attributes. |
| Prefixed `dt.service.name` on metrics (`<service.name> (<detected>)`) | **Yes** | A 2026-Q1 detection-layer fix that prefixes the detected Classic name with `service.name` when it's set. |
| Visible `service.name` on traces / span analysis | **Yes** | Span resource attribute carries through. |
| Clean entity display name in the Services app | **Coming** | Services app will read the prefixed name once the UI update ships. |

Classic's entity fragmentation (multiple entities per workload) does
**not** go away by setting `service.name`. The workaround helps you
*query* and *identify* Classic services; it does not collapse them into
one entity. For that, you need Latest (SDv2) detection enabled for the
namespace.

## Why this matters

A huge amount of the value of Latest Dynatrace is in the **query
ergonomics** (Module 2.2) and the **naming** (Module 2.1). Setting
`service.name` delivers most of that benefit for your Classic-detected
services today, without waiting for Latest to roll out to every
namespace.

This is also the single most useful thing to teach customers who are
blocked on Latest for compatibility reasons. Their Classic services can
get metric-first query ergonomics this afternoon.

## How to set `service.name`

The mechanism depends on how the app is instrumented:

- **OTel-native**: `OTEL_SERVICE_NAME=<name>` environment variable, or
  `OTEL_RESOURCE_ATTRIBUTES=service.name=<name>`. The OpenTelemetry
  Resource detector picks these up automatically.
- **OTel Java agent**: Same env vars, set on the container running the
  agent.
- **OneAgent deep monitoring**: OneAgent respects the OTel env vars on
  container-injected auto-instrumentation. Set them on the container;
  OneAgent's OTel bridge surfaces them as span resource attributes.
- **Code-level (any language)**: Configure the OpenTelemetry SDK's
  Resource with `service.name`. This overrides env vars if both are
  set.

## The lab

**[Module 2.3 Lab — The `service.name` workaround](./module-2-3-service-name-workaround.yaml)**

Four queries comparing two Classic-detected workloads that share
everything except one environment variable. The companion demo has
exactly this setup in the `orders-sdv1` namespace:

- `orders-demo` — no `OTEL_SERVICE_NAME`, baseline Classic behavior.
- `orders-demo-named` — `OTEL_SERVICE_NAME=orders-api` set.

The four queries demonstrate, in order:

1. `service.name` is on the spans of the "named" workload and empty on
   the baseline.
2. `service.name` is a queryable metric dimension on the named workload
   but absent on the baseline.
3. `dt.service.name` is **prefixed** on the named workload
   (`orders-api (orders-demo - OrderController)`) and raw on the
   baseline.
4. Entity counts are the same — fragmentation didn't collapse. Both
   workloads still produce 4 Classic entities. The workaround is
   about *naming* and *queryability*, not about entity consolidation.

### What to look for in the Dynatrace UI

In the **Services app**, find the two workloads side by side. The
named one should show:

- A prefixed name in the service list — e.g.
  `orders-api (orders-demo - OrderController)` instead of just
  `orders-demo - OrderController`. (If your tenant's Services app
  hasn't shipped the UI update yet, the list may still show the raw
  detected name; the prefixed form is what the **metrics** carry and
  the UI will eventually catch up.)
- If you open a Dashboard tile or a Notebook cell and split by
  `service.name`, the named workload will have a value
  (`orders-api`) and the unnamed one won't. That's the
  query-ergonomics difference made visible.

## What this looks like as a recommendation

When a customer asks "my Classic services have ugly names, what do I
do?", the answer is:

1. Decide the right `service.name` per workload (use workload name,
   team name, or business name — not a port or a path).
2. Set it as `OTEL_SERVICE_NAME` on the container.
3. Re-deploy. Within minutes, `service.name` appears on spans, metrics
   pick it up as a dimension, and `dt.service.name` gets the prefixed
   value.
4. Write DQL using the new dimension (Module 2.2 patterns).
5. Wait for the Services app UI to start reading the prefixed name for
   the entity display — that's the one gap still closing.

## Next

**[Module 2.4 — What's coming: pipeline-side name control.](./module-2-4-whats-coming-pipeline-naming.md)**
The workaround requires a re-deploy because `service.name` has to be on
the span at emit time. A longer-term fix moves name modification into
the server-side pipeline, so naming decisions can be made centrally
without touching every workload. Module 2.4 orients you on that
direction.
