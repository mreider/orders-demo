# Enhanced Endpoints demo for orders-demo

A set of ten Kubernetes workloads that demonstrate, side by side, how endpoint detection behaves in Dynatrace under different configurations of Service Detection v1 (SDv1) and Service Detection v2 (SDv2). Built to be the workload backing for a customer-facing guide on Enhanced Endpoints and the upcoming endpoint-naming heuristic.

This is the `enhanced-endpoints-demo` branch. The `main` branch of this repo is the SDv1→SDv2 migration demo; the two are independent.

## What this demonstrates

Endpoint detection in Dynatrace turns each incoming HTTP request into a row in the **new Services app**, keyed by the `endpoint.name` dimension of `dt.service.request.count` and friends. Whether a given request shows up as a clean `GET /orders/search` or collapses into something less useful like `GET /*` depends on three things:

1. **Which service detection engine runs** (SDv1 or SDv2)
2. **What rules are active** (Key Requests, Enhanced Endpoints for SDv1, Request Naming Rules, endpoint-detection rules, URL path pattern matching, etc.)
3. **What attributes the spans actually carry** (`http.route`, `url.path.pattern`, `url.truncated_path`, `span.name`)

This demo isolates each of those variables in its own namespace, so you can see the effect of changing exactly one thing.

### Two rollout safeguards: SDv1 feature flag vs SDv2 opt-out rule

The endpoint-naming heuristic ships in cluster version 1.341 (SDv1 side) with two distinct rollout safeguards, one per detection engine. The SDv2 side of the heuristic is staggered to cluster version 1.342, with a built-in opt-out rule landing in 1.341 to give customers an opt-out window:

- **SDv1: a per-tenant feature flag.** One flag (the SDv1 naming flag, `sdv1-url-and-http-route-naming`) gates the full bundle of SDv1 naming-behavior changes shipping in 1.341: heuristic-derived endpoint names, custom-placeholder resolution for URL-path attributes, and the related handling. Existing Enhanced Endpoints customers have the flag off by default and flip it when they're ready to receive the new endpoint names.
- **SDv2: a built-in opt-out rule on every existing tenant.** When cluster version 1.341 lands, Dynatrace pre-provisions a built-in endpoint-detection rule (`builtin:endpoint-detection-rules`) on every existing tenant, enabled by default. It preserves the old `GET /*` shape on heuristic-derived routes (matching condition `supportability.is_http_route_derived == true`). Customers disable the rule when they're ready to receive the new endpoint names. New tenants created after the cutoff don't get the rule, so they receive the new SDv2 behavior automatically once cluster version 1.342 activates the heuristic. Example 7 in this demo applies a manually-recreated version of the rule to a single namespace so its effect can be screenshotted in isolation.

### Service display names and the retirement of Service Naming Rules

The legacy Service Naming Rules surface (`builtin:naming.services`) is being retired. Naming rules only changed the UI display, never propagating to spans, metrics, logs, dashboards, SLOs, or DQL. In the new model, the name comes from telemetry: set `OTEL_SERVICE_NAME` as an environment variable on the application process (works with OneAgent, no OpenTelemetry SDK required) and the value lands as `service.name` on every span. The Nginx workloads in this demo set `OTEL_SERVICE_NAME=<example*-shop>` on each Deployment for that reason.

What's coming on the same path: Primary Fields and Primary Tags as dimensions on service metrics in June 2026, a short-term display fix that combines `service.name` with the detected name (`my-app (WebRequestService)`), and server-side renaming via OpenPipeline processing rules later.

## The ten examples

All examples run the same overall workload. It's either a small Spring Boot app (clean `http.route`) or an Nginx reverse proxy (no `http.route`), so any difference you see in the Services app is attributable to the configuration, not the application.

| # | Namespace | Workload | SDv1/v2 | Per-namespace configuration | What it shows |
|---|---|---|---|---|---|
| 1 | `example1-empty` | Spring Boot `example1-app` | SDv1 | nothing | Starting state. No Key Request, no Enhanced Endpoints. The new Services app shows `NON_KEY_REQUESTS` only. |
| 2 | `example2-keyreq` | Spring Boot `example2-app` | SDv1 | Key Request `["search"]` | Marking a request as Key gives you one named endpoint plus the `NON_KEY_REQUESTS` catchall for everything else. |
| 3 | `example3-ee-on` | Spring Boot `example3-app` | SDv1 | Enhanced Endpoints enabled | EE auto-detects every routed request as its own endpoint. With `http.route` present, all rows are clean. |
| 4 | `example4-rule` | Nginx `example4-shop` | SDv1 | EE enabled + Request Naming Rule `{URL:Path-Clean}` scoped by `k8s.namespace.name` tag | A Request Naming Rule shaping endpoint names on a service without `http.route`. Shows what Path-Clean normalizes (four specific patterns: UUIDs `[UUID]`, IPv4 `[IPv4]`, IPv6 `[IPv6]`, IBANs `[IBAN]`; plus any configured clean-up URL rules) and what it leaves alone (short alphanumeric IDs, hex tokens, multi-digit numbers, all-uppercase tokens). |
| 4b | `example4b-custom-placeholder` | Nginx `example4b-shop` | SDv1 | EE enabled + per-service Request Naming Rule using a custom placeholder (`REGEX_EXTRACTION` with regex `^(/shop/[^/]++)`) that captures the first two segments of `/shop/...` URLs and drops everything after | A custom placeholder demo. Before the SDv1 naming flag is on, the placeholder renders literally as `{ItemPath}` on endpoint.name. After the flag is on, the rule resolves and produces clean templated paths (`/shop/products`, `/shop/carts`, `/shop/orders`, `/shop/checkout`), catching the short alphanumeric IDs that Path-Clean misses. The trade-off is loss of path detail past the second segment (cart URLs roll up to `/shop/carts`, losing the `/items` tail). Setup happens in the per-service "Web request naming" settings (Services app → ⋮ → Settings → Web request naming → Add rule), not in the tenant-level Global request naming rules table. |
| 5 | `example5-overcollapse` | Nginx `example5-shop` | SDv1 | EE enabled, no rule | SDv1 with EE on but no rule and no `http.route`: textbook `GET /*` / `POST /*` over-collapse. |
| 6 | `example6-sdv2` | Spring Boot `example6-app` | SDv2 | SDv2 detection enabled | SDv2's default behavior on a workload that provides `http.route`. Clean per-route endpoints, no toggle required. |
| 7 | `example7-sdv2-overcollapse` | Nginx `example7-shop` | SDv2 | SDv2 detection plus pre-provisioned opt-out rule (matches `supportability.is_http_route_derived == true`, forces `{method} /*`) | Represents a tenant where the SDv2 opt-out rule is enabled by default. The rule sits dormant until the SDv2 heuristic activates, then forces endpoint names back to `GET /*` to preserve cardinality. Disabling the rule adopts the new behavior. |
| 8 | `example8-sdv2-fallback` | Nginx `example8-shop` | SDv2 | SDv2 detection + namespace-scoped Fallback HTTP endpoint rule | The textbook `GET /*` / `POST /*` over-collapse on SDv2. |
| 9 | `example9-sdv2-pattern-rule` | Nginx `example9-shop` | SDv2 | SDv2 detection + namespace-scoped URL path pattern matching rule | A URL path pattern matching rule producing clean templated endpoint names (`GET /shop/products/{id}` etc.) on the same Nginx workload. |
| 10 | `example10-sdv1-fallback` | Nginx `example10-shop` | SDv1 | EE enabled | SDv1 mirror of example 5; gives a parallel "before" state to compare against the SDv2 over-collapse case. |

Two infrastructure namespaces stay in place to host Postgres + Kafka:

| Namespace | Role |
|---|---|
| `orders-sdv1` | Postgres + Kafka used by the SDv1 Spring examples. |
| `orders-sdv2` | Postgres + Kafka used by the SDv2 Spring example. |

## Prerequisites

- A Dynatrace tenant with permission to enable OneAgent and configure service-detection settings.
- The Dynatrace Operator installed in the cluster, with a Dynakube CR configured for full-stack monitoring.
- `kubectl` and a target Kubernetes cluster (the demo was developed against GKE).
- `dtctl` (or any other client that can write Dynatrace Settings 2.0 objects).
- For the SDv1 Request Naming Rule used in example 4, an API token with `ReadConfig` and `WriteConfig` scopes. The legacy `/api/config/v1` surface is separate from Settings 2.0.

## Deploy

```bash
# 1. Namespaces + workloads
kubectl apply -f k8s/00-namespaces.yaml

# 2. Loadgen ConfigMaps in each namespace (must exist before the loadgen pods start)
for ns in example1-empty example2-keyreq example3-ee-on example6-sdv2; do
  kubectl -n "$ns" create configmap loadtest-script \
    --from-file=loadtest.js=load/loadtest.js \
    --dry-run=client -o yaml | kubectl apply -f -
done
for ns in example4-rule example4b-custom-placeholder example5-overcollapse \
         example7-sdv2-overcollapse example8-sdv2-fallback \
         example9-sdv2-pattern-rule example10-sdv1-fallback; do
  kubectl -n "$ns" create configmap loadtest-script-legacy \
    --from-file=loadtest.js=load/loadtest-legacy.js \
    --dry-run=client -o yaml | kubectl apply -f -
done

# 3. Apply all example workloads
kubectl apply -f k8s/60-example1-empty.yaml \
              -f k8s/61-example2-keyreq.yaml \
              -f k8s/62-example3-ee-on.yaml \
              -f k8s/63-example4-rule.yaml \
              -f k8s/63b-example4b-custom-placeholder.yaml \
              -f k8s/64-example5-overcollapse.yaml \
              -f k8s/65-example6-sdv2.yaml \
              -f k8s/66-example7-sdv2-overcollapse.yaml \
              -f k8s/67-example8-sdv2-fallback.yaml \
              -f k8s/68-example9-sdv2-pattern-rule.yaml \
              -f k8s/69-example10-sdv1-fallback.yaml
```

`scripts/up.sh` automates the full bring-up (cluster, operator, Dynakube, all example workloads). Run it end-to-end if you want a one-shot deploy from scratch.

## Configure Dynatrace settings

After the namespace and SERVICE entities surface in Dynatrace (typically 5 to 15 minutes after the pods are Running), apply the per-example settings.

### Namespace entity IDs

Each `example*` namespace gets a `dt.entity.cloud_application_namespace` entity. Find the IDs with:

```bash
dtctl query 'fetch dt.entity.cloud_application_namespace
| filter contains(entity.name, "example")
| fields id, entity.name' --plain
```

You'll use these in the `--scope` argument below.

### Example 3: Enhanced Endpoints for SDv1

```bash
echo '{ "enabled": true, "resolveRequestAttributes": true }' > /tmp/ee.json
dtctl create settings -f /tmp/ee.json \
  --schema builtin:enhanced-endpoints-for-sdv1 \
  --scope <example3-ee-on namespace ID>
```

### Examples 4, 5, 10: Enhanced Endpoints, plus a Request Naming Rule for 4

```bash
# EE on each namespace
for ns_id in <example4-rule> <example5-overcollapse> <example10-sdv1-fallback>; do
  dtctl create settings -f /tmp/ee.json \
    --schema builtin:enhanced-endpoints-for-sdv1 \
    --scope "$ns_id"
done

# Example 4: SDv1 Request Naming Rule (legacy /api/config/v1, needs ReadConfig + WriteConfig scopes)
curl -s -X POST "$DT_ENV/api/config/v1/service/requestNaming" \
  -H "Authorization: Api-Token $DT_TOKEN_CFG" \
  -H "Content-Type: application/json" \
  -d '{
    "namingPattern": "{URL:Path-Clean}",
    "enabled": true,
    "managementZones": [],
    "conditions": [{
      "attribute": "SERVICE_TAG",
      "comparisonInfo": {
        "type": "TAG",
        "comparison": "EQUALS",
        "value": { "context": "CONTEXTLESS", "key": "k8s.namespace.name", "value": "example4-rule" },
        "negate": false
      }
    }]
  }'

# Example 4b: SDv1 Request Naming Rule with a custom placeholder.
# The placeholder uses a regex extraction that captures the first two
# segments of /shop/... URLs (e.g. /shop/products, /shop/carts, /shop/orders,
# /shop/checkout) and drops everything after.
# Note: until the SDv1 naming flag (sdv1-url-and-http-route-naming) is on
# for the tenant, the placeholder renders as a literal `{ItemPath}` token
# in endpoint.name. Once the flag is on, the rule resolves to the captured
# value, alongside the heuristic-derived endpoint names.
# Also note: the recommended setup path is the per-service "Web request
# naming" Settings page (Services app → ⋮ → Settings → Web request naming
# → Add rule). The legacy global API surface shown below puts the rule in
# the tenant-level "Global request naming rules" table with a SERVICE_TAG
# condition, functionally equivalent but the per-service flow is cleaner.
curl -s -X POST "$DT_ENV/api/config/v1/service/requestNaming" \
  -H "Authorization: Api-Token $DT_TOKEN_CFG" \
  -H "Content-Type: application/json" \
  -d '{
    "namingPattern": "{ItemPath}",
    "enabled": true,
    "managementZones": [],
    "conditions": [{
      "attribute": "SERVICE_TAG",
      "comparisonInfo": {
        "type": "TAG",
        "comparison": "EQUALS",
        "value": { "context": "CONTEXTLESS", "key": "k8s.namespace.name", "value": "example4b-custom-placeholder" },
        "negate": false
      }
    }],
    "placeholders": [
      {
        "name": "ItemPath",
        "attribute": "WEBREQUEST_URL_PATH",
        "kind": "REGEX_EXTRACTION",
        "delimiterOrRegex": "^(/shop/[^/]++)"
      }
    ]
  }'
```

Body shape notes for the legacy Request Naming Rules API:

- The operator field inside `comparisonInfo` is `comparison`, not `operator`.
- There is no method placeholder. Patterns describe the request-name portion only; the HTTP method is implicit on the metric.
- For Nginx services in Kubernetes, condition on `SERVICE_TAG` with the automatic `k8s.namespace.name` tag rather than `SERVICE_NAME` (the latter defaults to `:<port>` for raw HTTP services and isn't namespace-distinguishing).

### Examples 6, 7, 8, 9: SDv2 detection, plus rules for 7, 8, and 9

```bash
# Enable SDv2 detection on each SDv2 example namespace
echo '{ "condition": "", "enableSDV2ForKubernetesWorkloads": true }' > /tmp/sdv2.json
for ns_id in <example6-sdv2> <example7-sdv2-overcollapse> <example8-sdv2-fallback> <example9-sdv2-pattern-rule>; do
  dtctl create settings -f /tmp/sdv2.json \
    --schema builtin:service-detection-v2-for-oneagent \
    --scope "$ns_id"
done

# Example 7: namespace-scoped SDv2 opt-out rule.
# Pre-provisioned, enabled by default on every existing tenant; preserves the old
# GET /* shape when the SDv2 heuristic activates. Disabling the rule
# adopts the new behavior.
cat > /tmp/optout-rule.json <<'JSON'
{
  "enabled": true,
  "rule": {
    "condition": "isNotNull(http.route) and supportability.is_http_route_derived == true",
    "description": "SDv2 opt-out: preserves GET /* for heuristic-derived routes",
    "endpointNameTemplate": "{http.request.method} /*",
    "ifConditionMatches": "DETECT_REQUEST_ON_ENDPOINT",
    "ruleName": "SDv2 opt-out (heuristic-derived to GET /*)"
  }
}
JSON
dtctl create settings -f /tmp/optout-rule.json \
  --schema builtin:endpoint-detection-rules \
  --scope <example7-sdv2-overcollapse namespace ID>

# Example 8: namespace-scoped Fallback endpoint-detection rule (forces GET /*)
cat > /tmp/fallback.json <<'JSON'
{
  "enabled": true,
  "rule": {
    "condition": "span.kind == \"server\" and isNotNull(http.request.method)",
    "description": "Demonstrates the textbook GET /* over-collapse on this namespace",
    "endpointNameTemplate": "{http.request.method} /*",
    "ifConditionMatches": "DETECT_REQUEST_ON_ENDPOINT",
    "ruleName": "Demo Fallback HTTP endpoint"
  }
}
JSON
dtctl create settings -f /tmp/fallback.json \
  --schema builtin:endpoint-detection-rules \
  --scope <example8-sdv2-fallback namespace ID>

# Example 9: namespace-scoped URL path pattern matching rule (clean templated names)
cat > /tmp/url-patterns.json <<'JSON'
{
  "enabled": true,
  "rule": {
    "ruleName": "Demo Shop URL patterns",
    "description": "Maps volatile /shop/* paths to stable url.path.pattern values",
    "urlPathPatterns": [
      "/shop/products/{id}",
      "/shop/carts/{cartId}/items/{itemId}",
      "/shop/orders/{id}",
      "/shop/checkout"
    ]
  }
}
JSON
dtctl create settings -f /tmp/url-patterns.json \
  --schema builtin:url-path-pattern-matching-rules \
  --scope <example9-sdv2-pattern-rule namespace ID>
```

URL path pattern syntax: `{placeholder}` matches one segment and templates the value; `_` matches one segment and keeps the original value; `*` is a trailing catch-all and must be the last token.

### Example 2: Key Request

```bash
# Find the example2-app OrderController service ID after it surfaces:
EX2_SVC=$(dtctl query 'fetch dt.entity.service
| filter contains(entity.name, "OrderController")
  and not contains(entity.name, "example*")
| fields id, entity.name | limit 20' --plain -o json \
  | jq -r '.records[] | select(.entity.name | contains("OrderController")) | .id' \
  | head -1)  # adjust if multiple match; the right one is in the example2-keyreq namespace

echo '{ "keyRequestNames": ["search"] }' > /tmp/kr.json
dtctl create settings -f /tmp/kr.json \
  --schema builtin:settings.subscriptions.service \
  --scope "$EX2_SVC"
```

Availability of the Key Request settings schema depends on the Dynatrace platform version of the tenant. If `dtctl create` returns an authorization error and Classic API requests return *"Creating new key requests is not supported"*, mark the request as key through the Services UI instead. The result is the same Settings 2.0 object.

## SDv1 Spring service split (one-time tenant tweak)

If you run the Spring Boot examples (1, 2, 3) on a single host group, SDv1's default detection groups them all into one merged service entity because they share the same Java class signature. To split them into per-namespace service entities, update the tenant's "Spring" service detection rule to add `serverName` as an additional ID contributor:

```bash
# Find the existing Spring rule (Framework = SPRING)
dtctl get settings --schema builtin:service-detection.full-web-service -o json --plain \
  | jq '.[] | select(.value.conditions[]?.framework[]? == "SPRING") | {objectId, value}'

# Recreate with serverName added as ID contributor
# (delete the existing rule, then create with the body below)
cat > /tmp/spring-split.json <<'JSON'
{
  "conditions": [
    { "attribute": "Framework", "compareOperationType": "FrameworkEquals", "framework": ["SPRING"] }
  ],
  "enabled": true,
  "idContributors": {
    "applicationId": { "enableIdContributor": false },
    "contextRoot": { "enableIdContributor": false },
    "detectAsWebRequestService": false,
    "serverName": {
      "enableIdContributor": true,
      "serviceIdContributor": { "contributionType": "OriginalValue" }
    },
    "webServiceName": {
      "enableIdContributor": true,
      "serviceIdContributor": {
        "contributionType": "TransformValue",
        "transformations": [{ "prefix": "Spring", "transformationType": "AFTER" }]
      }
    },
    "webServiceNamespace": { "enableIdContributor": false }
  },
  "name": "Spring Prefix with serverName"
}
JSON
dtctl create settings -f /tmp/spring-split.json \
  --schema builtin:service-detection.full-web-service \
  --scope environment
```

After the change, new Spring service entities surface per `serverName`, which in Kubernetes maps to the Service DNS name (`example1-app`, `example2-app`, `example3-app`). Existing merged entities will go stale.

## Verify

Once everything is in place, the new Services app should show different endpoint shapes per example. To audit from DQL:

```dql
// Per-service endpoint distribution
timeseries count = sum(dt.service.request.count),
  by:{dt.entity.service, endpoint.name}, from: now()-15m
| filter contains(dt.entity.service, "<SERVICE-ID>")
| sort arrayLast(count) desc
| limit 10
```

```dql
// Where is GET /* over-collapse hiding in this tenant?
timeseries c = sum(dt.service.request.count),
  by:{dt.entity.service, endpoint.name}, from: now()-1h
| filter endpoint.name == "GET /*" or endpoint.name == "POST /*"
| summarize total = sum(arrayLast(c)), by:{dt.entity.service}
| sort total desc
| limit 20
```

```dql
// What did the spans actually contain (useful when an endpoint is over-collapsed)
fetch spans, from: now()-15m
| filter dt.entity.service == "<SERVICE-ID>"
| filter endpoint.name == "GET /*"
| fields timestamp, http.request.method, url.path, http.route
| limit 30
```

## Companion guide

The customer-facing guide that walks these examples and the upcoming endpoint-naming heuristic is being developed alongside this repo. Each numbered example corresponds to one or two screenshots in that guide; the configurations here are designed to make those screenshots reproducible against any tenant where you stand up the demo.

## Teardown

```bash
kubectl delete namespace \
  example1-empty example2-keyreq example3-ee-on \
  example4-rule example5-overcollapse \
  example6-sdv2 example7-sdv2-overcollapse \
  example8-sdv2-fallback example9-sdv2-pattern-rule \
  example10-sdv1-fallback
```

The `orders-sdv1` and `orders-sdv2` namespaces (which host the shared Postgres + Kafka infrastructure) can be torn down with `scripts/down.sh`.
