# Module 3.1 — Every endpoint is baselined

*In Latest Dynatrace, every endpoint on every service has a baseline and anomaly detection by default. You can stop configuring key requests.*

## The question

In Classic, you picked a handful of endpoints per service as **key requests** — those got individual baselines and alerts; everything else rolled up into `NON_KEY_REQUESTS`.

> *What happens in Latest when you don't configure key requests?*

## The claim

Every endpoint gets individual baselines, latency percentiles, and failure rates. The dimensions that define an endpoint (`endpoint.name`, `http.route`, `messaging.destination.name`) are what the baselining system reads from. There is no key vs non-key split.

Existing Classic key-request configs are preserved as named endpoints during transition. Other endpoints become auto-named instead of rolled into the `NON_KEY_REQUESTS` bucket.

## The lab

**[Module 3.1 Lab — Every endpoint is baselined](./module-3-1-every-endpoint-baselined.yaml)**

- List every endpoint for your service with throughput, avg RT, p95 RT, failures.
- Pull per-endpoint p50/p95/p99 over 24 hours.

## What you should see

- Dozens of endpoints, each with distinct numbers.
- Low-throughput rows at the bottom (admin paths, health probes) — what used to be `NON_KEY_REQUESTS`.
- Every one has live baselines backing it.

## In the Dynatrace UI

- Service detail page → Endpoints section has one row per endpoint with throughput, latency, failure-rate columns.
- Filter by throughput ascending to see the long tail.
- Existing key requests appear as named endpoints alongside auto-named ones.

## Next

**[Module 3.2 — When `http.route` is missing.](./module-3-2-when-http-route-missing.md)**
