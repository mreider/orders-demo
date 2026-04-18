# Module 3.1 — Every endpoint is baselined

> **What you'll know by the end:** in Latest Dynatrace, every
> endpoint on every service has a baseline and anomaly detection by
> default. You can stop configuring "key requests" and explain to
> existing customers what happened to that feature.

## The question

In Classic, you picked a handful of endpoints per service and marked
them as **key requests**. Those were the endpoints that got individual
baselines, individual alerts, and prominent placement in the Services
UI. Everything else rolled up into an aggregate called `NON_KEY_REQUESTS`
— measured, but without per-endpoint insight.

> *What happens in Latest when you don't configure key requests?*

Answer: every endpoint gets what used to be reserved for key requests.
Individual baselines. Individual latency percentiles. Individual
failure rates. No configuration required.

## The claim

Latest Dynatrace baselines every endpoint automatically. The
dimensions that define an endpoint (`endpoint.name`, `http.route`,
`messaging.destination.name`) are the same dimensions the baselining
system reads from. There is no "key" and "non-key" split anymore — the
cost structure of baselining has improved enough that the carve-out
isn't needed.

Existing customers who had key requests configured on Classic services
keep them. When enhanced-endpoints kicks in, the named key requests are
preserved as named endpoints; other endpoints become auto-named
instead of rolling up to the `NON_KEY_REQUESTS` bucket. You don't lose
the endpoints you worked to configure; you gain insight into the ones
you didn't.

## Why this matters

- **Less manual config.** The common customer workflow of "pick my
  important endpoints, mark them key, accept the rest as a blob"
  doesn't apply anymore. Everything is important enough to baseline.
- **Anomaly detection extends to long-tail endpoints.** The endpoint
  that never got picked as key — because it was only called ten times
  a day — can still be baselined and alerted on.
- **Baselines move with dimensions.** Since endpoint identity is just
  a dimension value, a new endpoint (new route, new message queue)
  automatically gets a baseline as soon as data arrives. No "wait for
  baseline to warm up" gate.

## The existing-customer concern

Key requests are gone in Latest Dynatrace; enhanced endpoints replaces
them. While your tenant is in transition, existing key requests are
preserved as named endpoints. The migration path is:

1. If you have custom naming via request naming rules — review them.
   They'll survive the transition.
2. If you have custom baselines tuned on specific key requests —
   those transfer onto the equivalent `endpoint.name` dimension values
   under the new model.
3. If you had the UI button to "mark this a key request" — it's being
   replaced by the enhanced-endpoints config, which just sets the
   criteria for what constitutes a nameable endpoint.

## The lab

**[Module 3.1 Lab — Every endpoint is baselined](./module-3-1-every-endpoint-baselined.yaml)**

Two queries on a real service:

1. **Endpoint inventory.** List every endpoint Dynatrace sees for your
   service over the last 24 hours. You're looking at the full surface
   area — what used to be key-requests-plus-NON_KEY_REQUESTS.
2. **Per-endpoint latency percentiles.** Pull p50/p95/p99 per endpoint
   over the same window. Every endpoint — not just the ones you'd
   have marked as key — has distinct, queryable latency. That same
   dimension is what the platform baselines against.

## What you should see

A service with a handful of endpoints in Classic (the ones you marked
key) becomes a service with dozens in Latest — each baselined
individually. If your service has real long-tail traffic
(administrative endpoints, health checks, rarely-hit paths), you'll
see them all now.

The surprise is usually how *many* endpoints there are. Don't be alarmed
by high counts — that's the visibility you didn't have before.

### What to look for in the Dynatrace UI

Open your service in the **Services app** and scroll to the
**Endpoints** section (its exact label depends on your UI version).

- Every endpoint listed has its own row with throughput, latency, and
  failure-rate columns. Each of those cells is backed by a live
  baseline on the underlying dimension value — no manual configuration
  needed.
- Endpoints that would have been rolled up as `NON_KEY_REQUESTS` in
  Classic appear individually here. Filter by throughput ascending to
  find the long tail — administrative paths, rarely-hit routes, health
  probes.
- If you had key requests configured on this service in Classic,
  they're preserved as named endpoints and appear alongside the
  auto-named ones. No migration action required from you.

## Next

**[Module 3.2 — When `http.route` is missing.](./module-3-2-when-http-route-missing.md)**
One wrinkle: the clean per-endpoint baseline story assumes every
endpoint has a clean name. For services where the web framework
doesn't provide `http.route`, you'll see `GET /*` everywhere instead.
Module 3.2 covers what to do.
