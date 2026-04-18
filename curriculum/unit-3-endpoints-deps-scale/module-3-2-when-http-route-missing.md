# Module 3.2 — When `http.route` is missing

> **What you'll know by the end:** for any service showing `GET /*` or
> `POST /*` as its endpoint names, you can explain the root cause
> (missing `http.route` attribute), apply the supported fix today,
> and orient on the automatic fix that's shipping in 2026.

## The question

You open a service in the Services app. Its endpoint list shows:

```
GET  /*
POST /*
```

Two endpoints total for a service you know has dozens of routes. The
throughput is right. The endpoints are wrong.

> *Why is this happening, and what do you do?*

## The claim

`GET /*` is the fallback endpoint name when `http.route` isn't set on
server spans. The root cause is framework-level: many web frameworks
(Nginx, Kong, Apache, IIS, WebSphere Liberty, and about 80% of
enterprise HTTP workloads) don't emit `http.route` as an OTel
attribute. Without it, Dynatrace's endpoint detection has nothing to
use as a name, so it falls back to `METHOD /*`.

Today there are two fixes:

- **URL pattern matching** (Settings > Service detection > URL path
  pattern matching): you define patterns like
  `/api/orders/{orderId}` per service, and endpoints get named from
  them. Works, but requires per-service config.
- **Request naming rules** (Classic, for SDv1 services): similar, with
  a different UI. Deprecated path but still functional.

In 2026 a third fix ships: **automatic URL normalization**. When
`http.route` is missing, Dynatrace derives a stable route by truncating
paths at the first volatile segment (IDs, UUIDs, hashes, tokens). No
per-service configuration needed.

## Why this matters

- The `METHOD /*` fallback is common enough that customers conclude
  enhanced endpoints "doesn't work." It works; the signal it needs is
  missing.
- URL pattern matching is the production-ready fix today. Customers
  sometimes don't know it exists.
- The automatic normalization covers ~70–75% of cases without any
  config. For the remainder, URL pattern matching stays as the
  precise-control option.

## How the automatic normalization works

It applies four heuristic rules per path segment, in order:

1. More than one digit in the segment → truncate the path here.
2. Hex-code segment → truncate.
3. Mixed-case token (base64url style) → truncate.
4. All-uppercase segment (rare path component) → truncate.

Examples:

| URL path | Endpoint name |
|---|---|
| `/api/orders/12345/items/abc` | `GET /api/orders` |
| `/users/5f2b9a3c/profile` | `GET /users` |
| `/v1/payments/validate` | `POST /v1/payments/validate` |

The derived route is written to the `http.route` attribute itself, with
a marker distinguishing framework-provided routes from derived ones.
Your existing endpoint detection rules, metric extractions, and naming
rules continue to work unchanged — they just now have data to work with.

## Rollout status

- **Classic services**: behind a feature flag, turned on per-tenant via
  Dynatrace outreach. Ask your CSM if you want it enabled.
- **Latest services**: opt-in via a checkbox in the endpoints config
  screen. Will become the default once field validation is complete.

## The lab

**[Module 3.2 Lab — When `http.route` is missing](./module-3-2-when-http-route-missing.yaml)**

Three queries:

1. **Find services with bad endpoints.** Which services in your tenant
   show `GET /*` or `POST /*` as significant portions of their
   traffic?
2. **Check whether `http.route` is set on their spans.** This is the
   root cause confirmation.
3. **For a service where the problem is visible, apply URL pattern
   matching** (instructions point into the Settings app) and
   re-query. The result is clean endpoint names.

### What to look for in the Dynatrace UI

Open the service you identified in the lab's Question 1 and scroll
to the **Endpoints** section.

- Rows named `GET /*`, `POST /*`, etc. are the ones hit by the
  missing-`http.route` problem. These are the endpoints without
  meaningful names.
- In **Settings → Service detection → URL path pattern matching**,
  add a pattern for this service. Give it a moment, then reload the
  Endpoints section — the `/*` rows drop off and clean names appear
  for paths that match your pattern.
- If automatic URL normalization is enabled for your tenant, a span
  attribute **marker** on the originating spans distinguishes
  heuristic-derived routes from framework-provided ones. Open a trace
  on this service and inspect a server span's attributes — the
  `http.route` attribute will be present either way; a metadata flag
  indicates whether it came from the framework or the heuristic.

## Next

**[Module 3.3 — Downstreams are tabs, not entities.](./module-3-3-downstreams-are-tabs.md)**
Your service makes database queries, calls third-party APIs, and
publishes to queues. In Classic, some of those became separate entity
rows. In Latest, they're tabs on the *calling* service. This
consolidates the topology view.
