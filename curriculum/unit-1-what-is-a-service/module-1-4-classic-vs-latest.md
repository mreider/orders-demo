# Module 1.4 — Classic vs Latest, side by side

> **What you'll know by the end:** given the same application code
> deployed twice — once under Classic detection, once under Latest — you
> can pinpoint exactly what changed in the entity graph, the naming, and
> the query shape. And you can explain to a colleague why.

## The setup

The companion `orders-demo` application is a plain Spring Boot app with:

- Two REST controllers (`OrderController`, `InventoryController`)
- A Kafka consumer (`OrderEventsListener`)
- A PostgreSQL client (JDBC calls from both controllers)

It is deployed into two Kubernetes namespaces on the same cluster, under
the same OneAgent, with the same image:

| Namespace | Detection |
|---|---|
| `orders-sdv1` | Classic (OneAgent default SDv1) |
| `orders-sdv2` | Latest (SDv2 opt-in enabled for this namespace) |

Both namespaces run identical pods. Whatever differences you see in the
Services app or in DQL are detection-model differences only — not app
differences.

If you have the demo running locally, skip the setup. If not, see the
repo root README for the up.sh script.

## What you will find

The lab runs four queries that answer one structural question each:

1. **How many SERVICE entities exist for each workload?**  
   Classic produces multiple — one WEB_REQUEST_SERVICE, one WEB_SERVICE
   per controller class, one MESSAGING_SERVICE for the Kafka listener,
   and sometimes a DATABASE_SERVICE for the JDBC client.  
   Latest produces one — a UNIFIED entity per workload.
2. **Are any of those entities "fake"?**  
   The `orders-sdv1` side often shows a DATABASE_SERVICE named after
   the JDBC connection. There is no Postgres service being monitored
   here — it's the Spring app's *client-side* JDBC calls that produce
   that entity. That's what "fake" means: an entity invented to hold
   metrics for a thing that isn't really a service you run.
3. **Is the underlying activity the same?**  
   Yes. Both namespaces emit the same spans with the same transport
   dimensions, and the activity totals (transactions per minute) line
   up. Only the *modelling* over those spans differs.
4. **How does DQL shape differ?**  
   Classic queries for a workload-level picture require a `lookup`
   against the entity table to resolve IDs to names and a filter on
   `serviceType`. Latest queries name the service directly via
   `dt.service.name` — no lookup.

## Why this is Unit 1's payoff

Modules 1.1, 1.2, 1.3 each established one piece of the shift:

- 1.1: one workload → one entity (in Latest).
- 1.2: three metric families, with native dimensions.
- 1.3: splits live in dimensions, not entities.

Module 1.4 is the composite demonstration. Same application, same
traffic, two models. The DQL and UI side-by-side make the architectural
claim tangible.

## The lab

**[Module 1.4 Lab — Classic vs Latest side by side](./module-1-4-classic-vs-latest.yaml)**

Four queries. Most of them answer the question twice — once against
`orders-sdv1` and once against `orders-sdv2` — so the diff is visible
without switching contexts. You'll see the entity counts and query
shapes diverge while the underlying activity totals stay aligned.

### What to look for in the Dynatrace UI

Open the **Services app** and filter the service list by Kubernetes
namespace:

- Filter to `k8s.namespace.name = orders-sdv1`. You'll see a column
  of Classic entities: `orders-demo`, `orders-demo - OrderController`,
  `orders-demo - InventoryController`, `OrderEventsListener`, and —
  if your tenant has it — a DATABASE_SERVICE named `orders` or
  `postgres`. That last row is the fake-entity example called out in
  the lab's Question 2. There is no Postgres service being monitored
  here; it's the Spring app's JDBC client dressed up as a service.
- Filter to `k8s.namespace.name = orders-sdv2`. One row:
  `orders-sdv2 -- orders-demo` with serviceType UNIFIED. Same
  application, same pods, one entity.

Opening the UNIFIED entity's detail page shows the **Message
Processing** and **DB Queries** tabs — the downstreams are not
separate entities; they're tabs on the one service. Module 3.3
expands on this.

## What's next

Unit 1 is done. You know *what* a service is in Latest Dynatrace and
how it differs from Classic.

Unit 2 shifts from "what is it" to "how is it named, and how do I query
it efficiently?" The naming story directly shapes the DQL you'll write
for the rest of your career on this platform.

**[Unit 2, Module 2.1 — Where names come from.](../unit-2-naming-identity/module-2-1-where-names-come-from.md)**
