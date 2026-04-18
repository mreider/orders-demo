# Module 3.2 — When `http.route` is missing

*For any service showing `GET /*` or `POST /*` as endpoints, explain the root cause, apply the supported fix today, and orient on the automatic fix shipping in 2026.*

## The question

You open a service. Its endpoint list shows:

```
GET  /*
POST /*
```

Throughput is right. Endpoints are wrong.

> *Why, and what do you do?*

## The claim

`GET /*` is the fallback name when `http.route` isn't set on server spans. Nginx, Kong, Apache, IIS, WebSphere Liberty, and roughly 80% of enterprise HTTP workloads don't emit it. With no route, Dynatrace has nothing to name the endpoint with and falls back to `METHOD /*`.

Today's fixes:

- **URL pattern matching** (Settings → Service detection → URL path pattern matching). Works, requires per-service config.
- **Request naming rules** (Classic services only). Deprecated path, still functional.

Shipping in 2026: **automatic URL normalization**. When `http.route` is missing, Dynatrace derives a stable route by truncating paths at the first volatile segment (IDs, hashes, UUIDs, uppercase tokens). Four heuristic rules per path segment: digits, hex, mixed-case tokens, all-uppercase.

Examples:

| URL | Endpoint |
|---|---|
| `/api/orders/12345/items/abc` | `GET /api/orders` |
| `/users/5f2b9a3c/profile` | `GET /users` |
| `/v1/payments/validate` | `POST /v1/payments/validate` |

The derived route is written to `http.route` itself with a marker distinguishing framework-provided from derived. Existing detection rules, metric extractions, and naming rules continue working unchanged.

## Rollout status

- Classic: feature flag, per-tenant via Dynatrace outreach.
- Latest: opt-in checkbox in endpoints config; becomes default after field validation.

## The lab

**[Module 3.2 Lab — When `http.route` is missing](./module-3-2-when-http-route-missing.yaml)**

- Find services where `METHOD /*` dominates traffic tenant-wide.
- Check if `http.route` is populated on server spans for one problem service.
- Apply URL pattern matching and re-query to validate.

## What you should see

- Question 1 top entries = prioritized targets.
- `http.route` empty on most rows → confirmed framework miss.
- After URL pattern matching: `/*` rows drop off, clean names appear.

## In the Dynatrace UI

- Endpoints section: `GET /*` rows identify affected endpoints.
- Settings → Service detection → URL path pattern matching → add rule, wait 2–3 minutes, reload.
- If automatic normalization is enabled, inspect server span attributes — the marker indicates framework vs heuristic origin.

## Next

**[Module 3.3 — Downstreams are tabs, not entities.](./module-3-3-downstreams-are-tabs.md)**
