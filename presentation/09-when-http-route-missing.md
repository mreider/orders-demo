# When `http.route` is missing

`GET /*` isn't a bug. It's a missing attribute, and there's a fix today plus automatic relief coming soon.

## Why you see `GET /*`

Open a service, and its endpoint list shows:

```
GET  /*
POST /*
```

Throughput is right. Endpoints are wrong.

`GET /*` is the fallback name when `http.route` isn't set on server spans. Nginx, Kong, Apache, IIS, WebSphere Liberty, and roughly 80% of enterprise HTTP workloads don't emit it. With no route, Dynatrace has nothing to name the endpoint with and falls back to `METHOD /*`.

## What to do today

Two supported fixes work right now:

- **URL pattern matching** (Settings, Service detection, URL path pattern matching). Works on SDv1 and SDv2. Requires per-service configuration.
- **Request naming rules** (Classic services only). Deprecated path, still functional.

Both are manual. You define the pattern, Dynatrace applies it.

## Automatic URL normalization is coming

Approved and underway: when `http.route` is missing, Dynatrace will derive a stable route by truncating paths at the first volatile segment (IDs, hashes, UUIDs, uppercase tokens). Four heuristic rules per path segment: digits, hex, mixed-case tokens, all-uppercase.

| URL | Endpoint |
|---|---|
| `/api/orders/12345/items/abc` | `GET /api/orders` |
| `/users/5f2b9a3c/profile` | `GET /users` |
| `/v1/payments/validate` | `POST /v1/payments/validate` |

The derived route is written to `http.route` itself with a marker distinguishing framework-provided from derived. Your existing URL-pattern rules, metric extractions, and naming rules continue working unchanged.

## Rollout priority

*As of May 1, 2026.*

**Classic services first.** More Classic customers hit `GET /*`, and Classic doesn't have SDv2's dimensional fallbacks. Rollout is via feature flag, per-tenant.

**SDv2 services** get an opt-in checkbox in the endpoints config. It becomes the default after field validation completes.

Either way, your existing URL-pattern-matching rules, metric extractions, and naming rules continue working unchanged after normalization turns on.

## See it live

**[Demo: When `http.route` is missing](./09-when-http-route-missing.yaml)**

- Find services where `METHOD /*` dominates traffic tenant-wide.
- Check whether `http.route` is populated on server spans for one problem service.
- Apply URL pattern matching and re-query to validate.

## What it looks like in the UI

- Endpoints section: `GET /*` rows identify affected endpoints immediately.
- Settings, Service detection, URL path pattern matching: add a rule, wait 2-3 minutes, reload.
- When automatic normalization is enabled, server span attributes include a marker that tells you framework-provided vs heuristic-derived.
