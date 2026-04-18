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

# Module 3.1 — Every endpoint is baselined

**Key requests are gone. Stop configuring them.**

---

# The question

Under SDv1, you picked a handful of endpoints per service and marked them **key requests**.

- Those got individual baselines, alerts, and prominent UI placement
- Everything else rolled up into `NON_KEY_REQUESTS`

> *What happens with SDv2 when you don't configure key requests?*

---

# The claim

Every endpoint gets what used to be reserved for key requests:

- Individual baselines
- Individual latency percentiles
- Individual failure rates
- No configuration required

The dimensions that define an endpoint (`endpoint.name`, `http.route`, `messaging.destination.name`) are the same dimensions the baselining system reads from.

---

# Existing customers

Existing Classic key-request configs are preserved during transition:

- Named key requests → named endpoints under Latest
- Other endpoints → auto-named instead of `NON_KEY_REQUESTS` bucket
- You don't lose what you worked to configure; you gain insight into what you didn't

---

# The lab

Two queries on a service you choose:

- **Endpoint inventory** — full surface area with throughput, latency, failures
- **Per-endpoint latency percentiles** — p50/p95/p99 over 24 hours

---

# What you should see

- A service that had a handful of Classic key requests now has **dozens** of endpoints
- Low-throughput rows at the bottom: admin paths, health probes, rare routes
- Every one has live baselines

Don't be alarmed by high counts — that's visibility you didn't have before.

---

# In the Dynatrace UI

- Service detail → **Endpoints** section has one row per endpoint
- Throughput, latency, failure-rate columns — each backed by a live baseline
- Filter by throughput ascending to see the long tail
- Existing key requests appear alongside auto-named endpoints

---

<!-- _class: title -->

# Next: Module 3.2

**When http.route is missing.**
