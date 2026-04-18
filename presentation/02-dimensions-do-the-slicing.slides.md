---
marp: true
---

<!-- _class: title -->

# Dimensions do the slicing

**The per-endpoint, per-queue, per-database detail you used to navigate by clicking between entities lives on dimensions now**

---

# Three metric families per service

| Family | Counts | Key dimensions |
|---|---|---|
| `dt.service.request.*` | HTTP / gRPC / RMI entry points | `endpoint.name`, `http.route`, `http.response.status_code` |
| `dt.service.messaging.process.*` | Kafka / SQS / Pub/Sub consume | `messaging.destination.name`, `messaging.system`, `messaging.operation` |
| `dt.service.faas_invoke.*` | Serverless function invocations | `faas.trigger` |

The UI's **Transactions** column is the coalesced sum across all three.

---

# One legacy overlap to know

- Kafka consume activity **double-counts** today — shows up in both `request.*` AND `messaging.process.*`
- On `OrderEventsListener`: `dt.service.request.count` reads ~240/min with `endpoint.name = NON_KEY_REQUESTS` (Classic artifact)
- Predates dedicated messaging families
- **Goes away in a future SDv2-for-OneAgent release** — `request.*` becomes HTTP-only

Don't sum families in alerts until this lands.

---

# Downstream tabs — caller today, real entity tomorrow

| Tab | Metric family (target) | Dimensions |
|---|---|---|
| **DB Queries** | `dt.service.database.*` | `db.system`, `db.operation.name`, `server.address` |
| **Message Processing** | `dt.service.messaging.process.*` | `messaging.destination.name`, `messaging.system` |
| **Outbound Calls** | `dt.service.thirdparty.*` + client spans | host, endpoint, status |

**SDv1:** measures the client-side call and labels it "the database." Latency is the round-trip from the caller — not what's happening inside Postgres.

**SDv2 target:** the metric links to the **real DB entity** (produced by a Postgres extension). Query latency, alerts, RCA run on the database itself. **Landing in a future SDv2-for-OneAgent release.**

Messaging follows the same vision; broker-as-owner linking is less mature.

---

# `endpoint.name` and the `GET /*` reality

- `endpoint.name` derives from `http.route` on server spans
- If `http.route` isn't set → fallback to `<METHOD> /*`
- Spring MVC + OneAgent + `orders-demo` today → every endpoint is `GET /*`
- **Throughput and latency are still right.** The labels are wrong.

**Fix today:** Settings → Service detection → URL path pattern matching (SDv1 and SDv2).

**Automatic URL normalization coming.** Derives `http.route` by truncating at the first volatile segment (IDs, hashes, UUIDs). Classic-first rollout; SDv2 opt-in then default.

---

# Metric-first DQL

```
// Classic shape
fetch dt.entity.service
| filter entity.name == "orders-sdv2 -- orders-demo"
| lookup [timeseries count = sum(dt.service.request.count), by: {dt.entity.service}],
    sourceField: id, lookupField: dt.entity.service

// Latest shape
timeseries count = sum(dt.service.request.count),
  filter: dt.service.name == "orders-sdv2 -- orders-demo"
```

Same answer. Fewer lines, fewer scanned records, stable across entity re-detection.

---

# What's coming

- **Automatic URL normalization** — closes the `GET /*` gap
- **Pipeline-side naming in OpenPipeline** — admin writes a rule, `dt.service.name` set on every span centrally
- **`SERVICE_DEPLOYMENT`** — per-env entity orthogonal to SERVICE; `staging` vs `prod` without splitting identity (maps to Datadog's `service`+`env`+`version`)
- **Primary Fields as metric dimensions** — `k8s.cluster.name`, tags become first-class on service metrics
- **Services app rewire to timeseries-first** — list + detail pages go query-led
- **`dt.service.database.*` linked to real DB entities** — future SDv2-for-OneAgent release; span data is already shaped correctly
- **Messaging → broker entity** — same idea, further out

*Direction firm, timing not — road shape, not arrival date.*

---

# What to do today

- Set `service.name` on workloads you own — `OTEL_SERVICE_NAME` **and** `OTEL_RESOURCE_ATTRIBUTES`
- Write DQL metric-first — skip the entity table unless you need ownership or tags
- Don't invest new effort in Services Classic naming rules
- Don't double down on splitting rules for per-env views — use dimensions now, SERVICE_DEPLOYMENT for the rest
- Pick names durable enough to survive the SDv2 move **and** the pipeline-naming move

---

# See it live

**Demo: SDv2 demo** (`sdv2-demo.yaml`) — Questions 5-10

- Three families side-by-side on the SDv2 workload
- The legacy `request.*`/messaging double-count on `OrderEventsListener`
- Split requests by `endpoint.name` — see the `GET /*` fallback
- Messaging + DB as dimensions on the caller
- Metric-first vs entity-first — same question, two shapes
