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

# Module 1.2 — The three transport families

**Every service's activity lives in one of three metric families**

---

# The question

Pick the service from Module 1.1.

> *What kind of activity does it do, and in which metric family is it counted?*

---

# The three families

| Family | Counts |
|---|---|
| `dt.service.request.*` | HTTP/gRPC/RMI entry points |
| `dt.service.messaging.process.*` | Message consumption (Kafka, SQS, Pub/Sub) |
| `dt.service.faas_invoke.*` | Serverless function invocations |

A service that handles both HTTP and Kafka has activity in two families.

---

# Key dimensions per family

- **Requests**: `endpoint.name`, `http.route`, `http.response.status_code`
- **Messaging**: `messaging.destination.name`, `messaging.system`, `messaging.operation`
- **FaaS**: `faas.trigger`

---

# The Transactions column

The Services app's **Transactions** column is the **coalesced sum** across all three families.

Database client calls and outbound HTTP do **not** get their own family — they attach to the caller and surface via Downstream tabs (Module 3.3).

---

# The lab

- Sum the three families for one workload side by side
- Split each by its native dimension
- Coalesce to one-number Transactions view

---

# What you should see

- Pure HTTP service: only `request.*` has counts
- Kafka-consuming REST service: `request.*` + `messaging.process.*`
- Lambda: `faas_invoke.*` (plus `request.*` if behind API Gateway)

---

# In the Dynatrace UI

- Overview tab shows **Transactions** — coalesced total
- **Message Processing** tab appears only when messaging data exists
- **Functions** tab appears only when FaaS data exists
- Split-by charts Transactions by `endpoint.name`, `messaging.destination.name`, or `faas.trigger`

---

<!-- _class: title -->

# Next: Module 1.3

**Dimensions, not entities, split the view.**
