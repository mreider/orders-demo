---
marp: true
theme: uncover
class: invert
paginate: true
style: |
  section { background: linear-gradient(180deg, #0a0a14 0%, #0d0d1a 100%); font-family: 'Segoe UI', 'Arial', sans-serif; padding: 50px 70px 40px 70px; color: #ffffff; text-align: left; overflow: hidden; }
  section.title { text-align: center; display: flex; flex-direction: column; justify-content: center; align-items: center; }
  section.title h1 { text-align: center; border-bottom: 4px solid; border-image: linear-gradient(90deg, #00a1e0, #b455b6) 1; padding-bottom: 16px; margin-bottom: 0; font-size: 1.8em; }
  h1 { color: #ffffff; font-size: 1.6em; font-weight: 700; text-align: left; border-bottom: 3px solid; border-image: linear-gradient(90deg, #00a1e0, #b455b6) 1; padding-bottom: 10px; margin-bottom: 20px; margin-top: 0; }
  p { font-size: 0.78em; line-height: 1.5; margin: 10px 0; }
  ul, ol { font-size: 0.78em; line-height: 1.5; margin: 8px 0; padding-left: 24px; }
  li { margin-bottom: 6px; }
  strong { color: #00a1e0; }
  code { font-size: 0.75em; background: rgba(255,255,255,0.1); padding: 2px 6px; border-radius: 3px; }
  pre { font-size: 0.6em; margin: 12px 0; background: rgba(0,0,0,0.3); padding: 15px; border-radius: 5px; }
  table { font-size: 0.68em; margin: 12px 0; border-collapse: collapse; width: 100%; }
  th { background: rgba(0,161,224,0.25); padding: 6px 10px; text-align: left; border-bottom: 2px solid #00a1e0; }
  td { padding: 6px 10px; border-bottom: 1px solid rgba(255,255,255,0.15); }
  img { max-width: 90%; max-height: 280px; border-radius: 6px; }
---

<!-- _class: title -->

# When http.route is missing

**`GET /*` isn't a bug. It's a missing attribute.**

---

# The point

`GET /*` is the fallback name when `http.route` isn't set on server spans.

- Nginx, Kong, Apache, IIS, WebSphere Liberty don't emit it
- About **80% of enterprise HTTP workloads** are affected
- Without it, endpoint detection has nothing to use as a name

---

# Today's fixes

- **URL pattern matching** (Settings, Service detection, URL path pattern matching). Works on SDv1 and SDv2. Per-service config.
- **Request naming rules** (Classic-only). Deprecated, still functional.

Both are manual. You define the pattern, Dynatrace applies it.

---

# Automatic URL normalization is coming

When `http.route` is missing, Dynatrace derives a stable route by truncating paths at the first volatile segment.

Four heuristic rules per path segment:

1. More than one digit, truncate
2. Hex code, truncate
3. Mixed-case token (base64url), truncate
4. All-uppercase segment, truncate

The derived route is written to `http.route` with a marker distinguishing framework-provided from derived.

---

# Examples

| URL | Endpoint |
|---|---|
| `/api/orders/12345/items/abc` | `GET /api/orders` |
| `/users/5f2b9a3c/profile` | `GET /users` |
| `/v1/payments/validate` | `POST /v1/payments/validate` |

Your existing URL-pattern rules, metric extractions, and naming rules keep working unchanged.

---

# Rollout priority

*As of May 1, 2026.*

- **Classic services first.** More customers hit `GET /*` there, and Classic lacks SDv2's dimensional fallbacks. Feature flag, per-tenant.
- **SDv2 services**: opt-in checkbox in endpoints config, default after field validation.
- Existing rules keep working unchanged.

---

# See it in the Services app

- Endpoints section: `GET /*` rows identify affected endpoints immediately.
- Settings, Service detection, URL path pattern matching: add a rule, wait 2-3 minutes, reload.
- When normalization is on: inspect server span attributes. The marker tells you framework vs heuristic origin.

**Demo: When http.route is missing** (`09-when-http-route-missing.yaml`)
