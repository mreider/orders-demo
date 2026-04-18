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

# Downstreams are tabs, not entities

**DB, queue, and third-party calls live on the caller.**

---

# The point

Downstream dependencies are tabs on the calling service, not separate entities.

| Tab | Metric family | Dimensions |
|---|---|---|
| **DB Queries** | `dt.service.database.query.*` | `db.system.name`, `db.operation`, `db.sql.table` |
| **Message Processing** | `dt.service.messaging.process.*` | `messaging.destination.name`, `messaging.system` |
| **Outbound Calls** | `dt.service.thirdparty.*` + client spans | host, endpoint, status |

Identity lives on the caller's client span: `db.system`, `db.namespace`, `server.address`.

---

# Not an SDv2-only feature

The tabs work on **modern SDv1 and SDv2** tenants alike.

- Both detection models already route downstreams through the caller.
- The tabs are a **Latest Services app** feature, not an SDv2 feature.
- The data was already there; the UI curates it into tabs.

---

# Historical note for Classic refugees

Coming from Classic Dynatrace (pre-Latest)? You may remember:

- A separate `DATABASE_SERVICE` entity per database
- A `MESSAGING_SERVICE` per Kafka listener
- `EXTERNAL_SERVICE` rows for third-party hosts

On modern Latest tenants those entities are gone. SDv1 already moved to the caller-side dimensional model. Tabs replace entity-per-downstream without losing drill-down.

Upgrading customers sometimes mistake this for a bug:

- *"Where are my queue listeners?"* is now **Message Processing**.
- *"My external service entity is gone."* is now **Outbound Calls**.

Relocation, not removal.

---

# See it in the Services app

Service detail page, tab strip:

- **DB Queries**: rows by (database-system, operation).
- **Message Processing**: rows by (destination, system, operation).
- **Outbound Calls**: rows by external host.

Each tab is a facet of the calling service. Recognized third parties get richer drill-down. No separate DATABASE, MESSAGING, or EXTERNAL rows in the Services list.

**Demo: Downstreams are tabs, not entities** (`10-downstreams-are-tabs.yaml`)
