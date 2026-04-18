# Every endpoint is baselined

Key requests are gone. In Latest Dynatrace, every endpoint on every service gets a baseline by default.

## Stop configuring key requests

Under SDv1, you picked a handful of endpoints per service as **key requests**. Those got individual baselines and alerts; everything else rolled up into a single `NON_KEY_REQUESTS` bucket.

With SDv2, the split disappears. Every endpoint gets individual baselines, latency percentiles, and failure rates. No configuration, no buckets. The dimensions that define an endpoint (`endpoint.name`, `http.route`, `messaging.destination.name`) are the same dimensions the baselining system reads from.

Your existing Classic key-request configs are preserved during transition. Named key requests become named endpoints. Everything else becomes auto-named instead of disappearing into `NON_KEY_REQUESTS`. You keep what you worked to configure and gain visibility into what you didn't.

## See it live

**[Demo: Every endpoint is baselined](./08-every-endpoint-baselined.yaml)**

- List every endpoint on a service with throughput, avg RT, p95 RT, and failures.
- Pull per-endpoint p50/p95/p99 over 24 hours.

## What it looks like in the UI

- Service detail page, Endpoints section: one row per endpoint with throughput, latency, and failure-rate columns.
- Filter by throughput ascending to reveal the long tail: admin paths, health probes, rare routes.
- Former key requests appear as named endpoints alongside auto-named ones, each backed by a live baseline.
