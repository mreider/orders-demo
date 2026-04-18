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

# Module 2.3 — The service.name workaround

**Fix Classic-detected services today**

---

# The question

You have a Classic-detected service named `:8080`, `OrderController`, or a Java class path.

- You can't query it cleanly by name
- The old naming-rules overlay is deprecated

> *What can you do this month to make it queryable and readable?*

---

# The claim

**Set `service.name` as a resource attribute on spans.**

Three immediate wins today, one pending:

| Benefit | Today? |
|---|---|
| `service.name` as a queryable metric dimension | Yes |
| Prefixed `dt.service.name` | Yes (2026-Q1 fix) |
| `service.name` on traces | Yes |
| Clean entity display name in Services app | Pending UI update |

---

# What it does NOT do

Classic's entity fragmentation **does not** go away.

- You still get 4 entities per Spring Boot workload under SDv1
- The workaround fixes *naming* and *queryability*
- It does **not** collapse entities

For one-entity-per-workload, you need **Latest (SDv2)** on the namespace.

---

# How to set service.name

- **OTel-native / OTel Java agent**: `OTEL_SERVICE_NAME=<name>`
- **Resource attributes**: `OTEL_RESOURCE_ATTRIBUTES=service.name=<name>`
- **OneAgent**: respects OTel env vars on container-injected auto-instrumentation
- **Code-level**: configure the OTel SDK Resource — overrides env vars

---

# The lab

Two Classic workloads identical except one env var:

- `orders-demo` — no `OTEL_SERVICE_NAME`
- `orders-demo-named` — `OTEL_SERVICE_NAME=orders-api`

Four queries demonstrate:

- `service.name` on spans (present on named, empty on baseline)
- `service.name` as metric dimension (queryable on named only)
- `dt.service.name` prefixed on named, raw on baseline
- Entity counts — still 4 on both

---

# The prefix in action

- Baseline: `dt.service.name = orders-demo - OrderController`
- Named: `dt.service.name = orders-api (orders-demo - OrderController)`

The prefix makes fragments legible as belonging to one logical service. Classic detection still fragments; the fix makes it query-friendly.

---

# Customer recommendation

1. Pick `service.name` per workload (business name, not ports/paths)
2. Set as `OTEL_SERVICE_NAME` on the container
3. Re-deploy. Dimension appears within minutes.
4. Write DQL against the new dimension (Module 2.2 patterns)
5. Wait for the UI to read the prefixed name — the last remaining gap

---

# In the Dynatrace UI

- Named workload shows prefixed name in service list once UI ships
- Split a dashboard tile by `service.name` — named workload has a value, unnamed one is empty
- That's the query-ergonomics difference, made visible

---

<!-- _class: title -->

# Next: Module 2.4

**What's coming: pipeline-side naming.**
