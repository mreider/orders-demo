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

# Module 3.3 — Downstreams are tabs, not entities

**DB, queue, and third-party calls moved to the caller's view**

---

# The question

Your service calls Postgres. Under SDv1, Postgres showed up as a `DATABASE_SERVICE` entity:

- Its own row in the Services list
- Its own failure rate, baselines
- "Is the DB slow?" = click into the DATABASE_SERVICE

Under SDv2, that row often doesn't exist.

> *Where do DB calls live, and why did the model change?*

---

# The claim

Downstream dependencies are **tabs on the calling service**:

| Tab | Metric family |
|---|---|
| **DB Queries** | `dt.service.database.query.*` |
| **Message Processing** | `dt.service.messaging.process.*` (consume + publish) |
| **Outbound Calls** | `dt.service.thirdparty.*` + client spans |

Data didn't disappear — it relocated.

---

# No more fake entities

Under SDv1, `postgres:orders-db` `DATABASE_SERVICE` existed not because Postgres was being monitored.

- It existed because Dynatrace needed somewhere to attach client-side JDBC metrics
- The entity was always a fiction
- Latest removes it

---

# Other benefits

- **Trace-based RCA** — follow the trace from HTTP handler into JDBC span, not across entity graphs
- **Clearer ownership** — the team that owns the service owns its DB-client side
- **Simpler topology** — fewer rows to navigate

---

# Customer concerns

Two things customers mistake for bugs:

- **"Where are my queue listeners?"** — Each Classic `MESSAGING_SERVICE` is now a Message Processing tab on the caller
- **"My external service entity is gone."** — Third-party HTTP now lives in Outbound Calls

They aren't gone. They're tabbed.

---

# The lab

Three queries on the data behind each tab:

- Database queries from a service (`dt.service.database.query.*`)
- Messaging by destination, system, operation (publish + process)
- Outbound HTTP via `span.kind == "client"`

Same DQL shape: filter to caller, group by downstream dimension.

---

# In the Dynatrace UI

Service detail page → tab strip:

- **DB Queries** — rows by (database-system, operation)
- **Message Processing** — rows by (destination, system, operation)
- **Outbound Calls** — rows by external host

Each tab is a facet of this service. No separate rows in the Services list.

---

<!-- _class: title -->

# Next: Module 3.4

**What's coming: SERVICE_DEPLOYMENT.**
