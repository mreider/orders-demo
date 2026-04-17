---
title: Rung 6 - Where this is going
description: The preview state walked in Rungs 0 through 5 is real today, but several pieces are still moving. What is coming for endpoints, identity, and messaging.
rung: 6
last_updated: 2026-04-17
---

# Rung 6: Where this is going

The five rungs before this are grounded in what the tenant shows
today. A few pieces are in motion; this page names them so the
teaching does not outrun the preview.

## Endpoints: URL path normalization fills the `http.route` gap

This demo is **not** an example of the `http.route` gap. Every Spring
server span carries `http.route` (`/orders/submit`, `/orders/search`,
`/inventory/check`). Endpoints show up as `OrderController.submit`
etc. because OneAgent's Java sensor pre-populates `endpoint.name`
from `code.namespace` + `code.function` at capture time, bypassing
the unified ruleset's `http.route` rule. See Rung 2 for the
mechanism.

The real URL-normalization target is the ~80% of enterprise workloads
behind gateways (Nginx, Kong, Apache, IIS, WebSphere Liberty) where
`http.route` genuinely is not emitted. There the unified ruleset
falls through to `span.name` or `/*`, producing unusable endpoint
names. For those cases the product is shipping four heuristic rules
that truncate URL paths at the first volatile segment:

1. Segment with more than one digit
2. Hex-code segment
3. Mixed-case token (catches base64url-style tokens)
4. All-uppercase segment

Examples:

| URL path | Derived route |
|---|---|
| `/api/orders/12345/items/abc-def-ghi` | `GET /api/orders` |
| `/users/5f2b9a3c/profile` | `GET /users` |
| `/v1/payments/validate` | `POST /v1/payments/validate` |
| `/checkout/cart` | `POST /checkout/cart` |

Coverage: ~70-75% of paths get a meaningful name. Writes to
`http.route` itself with a marker distinguishing derived from
framework-provided. Existing URL-pattern-matching rules (SDv2) and
request-naming rules (SDv1) take precedence and are unchanged.

Rollout:

- **SDv1**: automatic when enhanced endpoints is enabled, with a
  feature flag protecting already-opted-in customers.
- **SDv2**: opt-in checkbox in endpoint detection settings, breaking
  change, on by default for new tenants once the team is confident.

Related long-term direction: pattern detection for endpoints -
analogous to log pattern detection - to replace hand-coded heuristics
with clustering. No timeline.

## Messaging: consumer spans leave the endpoint surface

Today, SDv2 exposes Kafka consumers as peer endpoints on the UNIFIED
service (`order-events process`). The product direction is to stop
detecting endpoints from consumer spans for SDv2 (new tenants first;
existing tenants keep current behavior until opted in).

Why: messaging metrics already live in a dedicated family
(`dt.service.messaging.process.*`) with richer dimensions. Surfacing
consumer spans as endpoints mixes messaging data into HTTP
response-time baselines and failure rates, making per-endpoint
metrics less meaningful.

After the change: messaging still lives on the UNIFIED service. It
just moves to a dedicated **Message Processing tab** rather than
appearing in the endpoint list. The Rung 4 queries against
`dt.service.messaging.process.*` work unchanged; only the
endpoint-named messaging rows in `dt.service.request.*`-style
queries go away.

## Identity: `SERVICE_DEPLOYMENT` separates service from deployment context

The UNIFIED service in this demo is named
`orders-sdv2 -- orders-demo`, because the built-in naming rule
includes `k8s.namespace.name`. Deploy the same workload to a second
namespace and a second UNIFIED entity appears.

Stated direction (PM-led):

- Remove `{k8s.namespace.name}` from the built-in naming rule.
- Remove the built-in splitting-by-namespace rule, or make it opt-in.
- Add `SERVICE_DEPLOYMENT` as an additive entity that carries
  deployment context (namespace, cluster, release version, stage) and
  links back to a single `SERVICE` entity.
- Surface per-environment views as a split-by on charts against
  dimensions of one identity, not as separate entities.

When it ships, "one identity across environments, sliced when you
want to compare" becomes literal. Today, per-environment views still
come from entity splitting.

## Phase 3: classic service types continue to collapse

The SDv1 teachings in Rungs 0, 1, 3, 4 depend on MESSAGING_SERVICE,
WEB_SERVICE, and WEB_REQUEST_SERVICE entities being first-class in
the UI. In Phase 3, those classic entity types are removed entirely:

- Queue Listener -> **Message Processing tab** on calling service
- Database -> **DB Queries tab** on calling service
- External -> **Outbound Calls tab** on calling service
- Key requests -> Enhanced endpoints entirely

Customers migrating to 3rd gen will not see SDv1's `OrderEventsListener`
MESSAGING_SERVICE at all. The messaging metrics still exist but are
surfaced against the calling service, not as an entity. The SDv1
idioms taught in Rungs 3 and 4 are preserved as DQL patterns but
disappear from UI navigation.

## Related

- `context/decisions/endpoint-url-normalization` - URL normalization heuristics
- `context/decisions/enhanced-endpoints-key-requests` - enhanced endpoints migration
- `context/architecture/sdv2-service-detection` - SDv2 identity model and SERVICE_DEPLOYMENT
- `context/architecture/service-metrics-framework` - three metric families and transaction attributes
- `context/gaps/phase3-breaking-changes` - classic service types removal
- PRODUCT-14412 - SDv2 for OneAgent on all workloads (preview)

## Things parked for depth sessions

- `@Scheduled` and `@Async` Spring background work under SDv2
- `faas_invoke.*` family for Lambda triggers
- Webhook endpoints for inbound third-party calls
- `service.version` and `deployment.release_stage` dimensions when
  SERVICE_DEPLOYMENT lands
- Custom services in SDv2 (producing spans on parent service rather
  than separate entities)
