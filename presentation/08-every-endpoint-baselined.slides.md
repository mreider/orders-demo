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

# Every endpoint is baselined

**Key requests are gone. Stop configuring them.**

---

# The point

Every endpoint gets what key requests used to get, by default.

- Individual baselines
- Individual latency percentiles
- Individual failure rates
- No configuration, no `NON_KEY_REQUESTS` bucket

---

# How it works

The dimensions that define an endpoint (`endpoint.name`, `http.route`, `messaging.destination.name`) are the same dimensions the baselining system reads from. One dimensional model, one set of baselines, no split.

Your existing Classic key-request configs carry forward:

- Named key requests become named endpoints.
- Everything else becomes auto-named instead of rolling up.
- You keep what you configured and gain the rest.

---

# See it in the Services app

Service detail, **Endpoints** section:

- One row per endpoint with throughput, latency, and failure-rate columns.
- Each row backed by a live baseline.
- Sort by throughput ascending to surface the long tail: admin paths, health probes, rare routes.

A service that had a handful of Classic key requests now shows dozens of endpoints. That's visibility you didn't have before, not noise.

**Demo: Every endpoint is baselined** (`08-every-endpoint-baselined.yaml`)
