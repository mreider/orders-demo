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

# Module 1.1 — One workload, one service

**How many service entities represent one Kubernetes workload?**

---

# The question

You open the Services app and pick a Kubernetes-deployed service.

> *How many Dynatrace service entities does this one workload produce?*

Most engineers' gut answer is *one*. That's only true under one of the two detection models.

---

# Latest Dynatrace

**One Kubernetes workload = one service entity.**

- One Deployment, one SERVICE row
- Regardless of how many controllers, listeners, or clients live in the pod
- `serviceType = UNIFIED`

---

# Classic Dynatrace

**Same workload fragments into multiple entities.**

A Spring Boot app with two REST controllers and a Kafka listener becomes **four** SERVICE entities:

- `WEB_REQUEST_SERVICE` — workload aggregate
- Two `WEB_SERVICE` entities — one per controller class
- `MESSAGING_SERVICE` — the Kafka consumer

Health, naming, and alerting are per-entity.

---

# The lab

Three queries on a workload you pick:

- **Count** — distinct `dt.entity.service` IDs
- **Classify** — which `serviceType` did detection produce?
- **Compare** — what does each entity represent?

---

# What you should see

- **Latest**: 1 row, `UNIFIED`
- **Classic**: 4–10 rows for non-trivial apps
- **Mixed**: transitioning namespaces carry both for a window

---

# In the Dynatrace UI

- Services app → filter by your workload
- **One row** = Latest
- **Many rows** = Classic
- Each Classic row has its own health surface, baselines, alerts

---

<!-- _class: title -->

# Next: Module 1.2

**The three transport families.**
