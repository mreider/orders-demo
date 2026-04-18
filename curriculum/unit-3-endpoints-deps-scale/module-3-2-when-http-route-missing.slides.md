---
marp: true
theme: uncover
class: invert
paginate: true
style: |
  section {
    background: linear-gradient(180deg, #0a0a14 0%, #0d0d1a 100%);
    font-family: 'Segoe UI', 'Arial', sans-serif;
    padding: 50px 70px 40px 70px;
    color: #ffffff;
    text-align: left;
    overflow: hidden;
  }
  section.title {
    text-align: center;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
  }
  section.title h1 {
    text-align: center;
    border-bottom: 4px solid;
    border-image: linear-gradient(90deg, #00a1e0, #b455b6) 1;
    padding-bottom: 16px;
    margin-bottom: 0;
    font-size: 1.8em;
  }
  h1 {
    color: #ffffff;
    font-size: 1.6em;
    font-weight: 700;
    text-align: left;
    border-bottom: 3px solid;
    border-image: linear-gradient(90deg, #00a1e0, #b455b6) 1;
    padding-bottom: 10px;
    margin-bottom: 20px;
    margin-top: 0;
  }
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
  .avail { font-size: 0.7em; margin-top: 16px; padding: 8px 12px; background: rgba(255,255,255,0.05); border-radius: 4px; }
---

<!-- _class: title -->

# Module 3.2 — When `http.route` Is Missing

**Unit 3: Endpoints, downstreams, and scale**

---

# The Question

You open a service in the Services app. Its endpoint list shows:

```
GET  /*
POST /*
```

Two endpoints total — for a service you know has dozens of routes. Throughput is right. Endpoints are wrong.

> *Why is this happening, and what do you do?*

---

# The Root Cause

`GET /*` is the **fallback name** when `http.route` isn't set on server spans.

Many web frameworks don't emit `http.route` as an OTel attribute:

- Nginx, Kong, Apache, IIS, WebSphere Liberty
- ~80% of enterprise HTTP workloads

Without it, endpoint detection has nothing to use as a name. So it falls back to `METHOD /*`.

---

# Today's Fixes

Two paths work today:

| Fix | How | Status |
|---|---|---|
| **URL pattern matching** | Settings > Service detection > URL path pattern matching | Production-ready, per-service config |
| **Request naming rules** (Classic / SDv1) | Different UI, similar idea | Deprecated path, still functional |

Both work but require **per-service configuration**. Customers often don't realize URL pattern matching exists.

---

# What's Coming in 2026

**Automatic URL normalization.** When `http.route` is missing, Dynatrace derives a stable route by truncating paths at the first volatile segment.

No per-service config needed. Covers about **70–75%** of the cases. URL pattern matching stays as the precise-control option for the rest.

---

# How the Heuristic Works

Four rules per path segment, in order:

1. More than one digit → truncate
2. Hex-code segment → truncate
3. Mixed-case token (base64url style) → truncate
4. All-uppercase segment → truncate

| URL path | Endpoint name |
|---|---|
| `/api/orders/12345/items/abc` | `GET /api/orders` |
| `/users/5f2b9a3c/profile` | `GET /users` |
| `/v1/payments/validate` | `POST /v1/payments/validate` |

---

# Backward Compatibility

The derived route is **written to the `http.route` attribute itself**, with a marker distinguishing framework-provided routes from derived ones.

Your existing endpoint detection rules, metric extractions, and naming rules **continue to work unchanged** — they just now have data to work with.

No migration. No breaking change. The signal that was missing now exists.

---

# Rollout Status Today

- **Classic services**: behind a feature flag, turned on per-tenant via Dynatrace outreach. Ask your CSM.
- **Latest services**: opt-in via a checkbox in the endpoints config screen. Will become default once field validation completes.

---

# What the Lab Does

Open the companion notebook in your tenant: **Curriculum / Module 3.2**.

Three queries:

1. **Find services with bad endpoints.** Which show `GET /*` or `POST /*` as significant traffic?
2. **Confirm root cause.** Is `http.route` empty on their spans?
3. **Apply URL pattern matching** in Settings, then re-query. Watch endpoints clean up.

---

<!-- _class: screenshot -->

# What to Look For in the UI

![placeholder](assets/placeholder-bad-endpoint-fix.png)

**SCREENSHOT:** Services app — Endpoints section, before and after
- Before: rows showing `GET /*`, `POST /*` with high throughput
- Settings → Service detection → URL path pattern matching: add a pattern
- After: clean endpoint names appear, `/*` rows drop off
- If automatic URL normalization is enabled: open a span and inspect the `http.route` attribute marker
- **Key point:** The fix is in Settings today, automatic in 2026 — same outcome either way

---

<!-- _class: title -->

# Next: Module 3.3

**Downstreams are tabs, not entities**

Database, queue, third-party calls used to be separate entity rows. In Latest, they're tabs on the calling service.
