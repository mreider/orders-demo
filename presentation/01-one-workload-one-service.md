# One workload, one service

How many distinct service names does a single Kubernetes workload produce? The answer depends on which detection model is running.

## SDv2 collapses the name to one

Under **SDv2**, one Kubernetes workload produces **one `dt.service.name`**, typically `<namespace> -- <workload>` (or whatever `service.name` the app emits). Controllers, Kafka listeners, and JDBC clients inside the pod all tag spans with the same name. Per-endpoint granularity lives on first-class metric dimensions like `endpoint.name` and `messaging.destination.name`.

Under **SDv1**, the same workload produces **many `dt.service.name` values**: one per controller class, one per Kafka listener, one aggregate. A Spring Boot app with two REST controllers plus a Kafka consumer commonly emits:

- `<workload>` (aggregate)
- `<workload> - OrderController` (per controller class)
- `<workload> - InventoryController` (per controller class)
- `OrderEventsListener` (the Kafka consumer)

All of these still point at a single `dt.entity.service` (a `WEB_REQUEST_SERVICE`). The entity graph already consolidated to one-per-workload years ago. But queries that filter by `dt.service.name` see each fragment as a separate identity. Health and alerts written against those names end up scoped per-class instead of per-workload.

## See it live

**[Demo: One workload, one service](./01-one-workload-one-service.yaml)**

- Count distinct `dt.service.name` values tagged to a workload.
- Enumerate them to see where SDv1 fragmentation lives.
- Check the `dt.entity.service` `serviceType`: `UNIFIED` (SDv2) vs `WEB_REQUEST_SERVICE` (SDv1) to confirm which detection model is active.

Expected shape:

- **SDv2**: one `dt.service.name`, entity `serviceType = UNIFIED`.
- **SDv1**: 4-7 `dt.service.name` values, entity `serviceType = WEB_REQUEST_SERVICE`.
- **Mixed**: transitioning namespaces carry both patterns for a window.

## What it looks like in the UI

- Filter by your workload's name. Under SDv2 you see one row. Under SDv1 you often see multiple rows with names like `orders-demo - OrderController`. That's the `dt.service.name` fragmentation surfaced as separate Services list entries, even though they share a single underlying entity.
- Each fragmented row has its own health, baselines, and alerts. That's the cost the SDv2 collapse removes.
