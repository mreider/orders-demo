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

# Dimensions, not entities, split the view

**Per-controller views without per-controller names**

---

# The point

The slicing you used to do across separate service identities now happens on one service, at query time, across metric dimensions.

- Under SDv1, "which endpoint is slowest?" meant switching to a different `dt.service.name` fragment
- Under SDv2, it means splitting one service by `endpoint.name`
- One name per workload. Granularity lives on first-class dimensions.

---

# Historical note

Modern K8s-aware SDv1 already backs each workload with a single `WEB_REQUEST_SERVICE` *entity*. Entity-graph fragmentation was retired before SDv2.

What SDv2 specifically adds:

- Collapses the per-class **`dt.service.name`** fragmentation SDv1 still produces
- Pushes that granularity onto endpoint and messaging dimensions

---

# Dimensions you'll use

**HTTP:**
- `endpoint.name`: the UI's endpoint concept, from `http.route` when set
- `http.route`, `http.request.method`, `http.response.status_code`

**Messaging:**
- `messaging.destination.name`: per queue
- `messaging.operation`: publish vs process

---

# See it in the Services app

- Latest service detail: split-by selector for `endpoint.name`, `messaging.destination.name`, `http.response.status_code`
- Classic service list: separate entity rows per controller class. You switch by clicking, not by picking a dimension.
- Same answer, shorter DQL on the Latest side (no `lookup` step needed).

**Demo: Dimensions, not entities** (`03-dimensions-not-entities.yaml`)
