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

# Module 3.2 — When http.route is missing

**`GET /*` isn't a bug. It's a missing attribute.**

---

# The question

You open a service. Its endpoint list shows:

```
GET  /*
POST /*
```

Two endpoints total for a service you know has dozens of routes. Throughput is right. Endpoints are wrong.

> *Why, and what do you do?*

---

# The claim — root cause

`GET /*` is the fallback name when `http.route` isn't set on server spans.

- Many web frameworks — Nginx, Kong, Apache, IIS, WebSphere Liberty — don't emit `http.route` as an OTel attribute
- About **80% of enterprise HTTP workloads** are affected
- Without it, endpoint detection has nothing to use as a name

---

# Today's fixes

- **URL pattern matching** (Settings → Service detection → URL path pattern matching)
  - You define patterns per service
  - Works, requires per-service config
- **Request naming rules** (Classic-only)
  - Deprecated, still functional

---

# Shipping in 2026: automatic URL normalization

When `http.route` is missing, Dynatrace derives a stable route by truncating paths at the first volatile segment.

Four heuristic rules per path segment:

1. More than one digit → truncate
2. Hex code → truncate
3. Mixed-case token (base64url) → truncate
4. All-uppercase segment → truncate

---

# Examples

| URL | Endpoint |
|---|---|
| `/api/orders/12345/items/abc` | `GET /api/orders` |
| `/users/5f2b9a3c/profile` | `GET /users` |
| `/v1/payments/validate` | `POST /v1/payments/validate` |

The derived route is written to `http.route` with a marker distinguishing framework-provided from derived.

---

# Rollout status

- **Classic services**: behind a feature flag, per-tenant via Dynatrace outreach
- **Latest services**: opt-in checkbox in endpoints config
- Becomes default once field validation completes

Existing detection rules, metric extractions, and naming rules continue working unchanged.

---

# The lab

- Find tenant-wide services where `METHOD /*` dominates
- Check whether `http.route` is populated on their server spans
- Apply URL pattern matching and re-query

---

# In the Dynatrace UI

- Endpoints section: `GET /*` rows identify affected endpoints
- Settings → Service detection → URL path pattern matching → add rule → wait 2–3 minutes → reload
- If normalization is enabled: inspect server span attributes; marker distinguishes framework vs heuristic origin

---

<!-- _class: title -->

# Next: Module 3.3

**Downstreams are tabs, not entities.**
