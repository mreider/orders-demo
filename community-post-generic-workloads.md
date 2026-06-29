---
title: "Service Detection v2 for generic workloads (Preview)"
audience: Dynatrace Community / Feedback channel / product documentation
status: Preview
---

# Service Detection v2 for generic workloads (Preview)

Service Detection v2 (SDv2) is now Generally Available for **Kubernetes and AWS Lambda**
workloads monitored by OneAgent. Alongside that GA, we're opening a **Preview** that
extends SDv2 to **generic workloads** — OneAgent-monitored processes that aren't
Kubernetes or Lambda.

This page explains what the Preview covers, what to opt in (and what not to), and what
changes when you do. SDv2 is a different service model, not a version bump, so please read
the Preview notice before enabling anything.

> **Note**: This is a Preview. Behavior, naming, and the opt-in mechanism may change
> before general availability. Timelines for anything marked "coming" are estimates and
> subject to change.

## Preview — read this first

Enabling SDv2 for a workload **changes how that workload is detected, named, and
identified**. The service entity IDs change. That is a breaking change for anything built on
the old IDs:

- **Dashboards, SLOs, alerting profiles, and Monaco/config-as-code** that reference a
  service by its SDv1 entity ID stop resolving when that service is re-detected under
  SDv2. There is no automatic migration for most of these.
- **Rollback is a second migration, not an undo.** Turning the opt-in back off re-detects
  the workload under SDv1 — IDs change back, baselines reset, and anything you built on
  the SDv2 IDs breaks in turn. Plan the move; don't toggle it to "try it."
- **Opt in deliberately and narrowly.** Start in a non-production environment, scope to a
  single workload, validate, then expand.

**Only opt in workloads the Preview supports:** web servers and single-service processes
(one service per process). Check the supported-workloads list linked on the toggle before
enabling. Do **not** opt in monoliths or multi-service processes (see *What "generic
workloads" means* below).

## What "generic workloads" means

The Preview targets OneAgent-monitored workloads outside Kubernetes and Lambda that
map cleanly to **one service per process**:

- **Cloud-native and on-host 1:1 workloads** — a process that hosts a single application
  service.
- **Web servers and reverse proxies running outside containers** — Nginx, Apache, IIS.

**What's explicitly out of scope for the Preview:**

- **Monoliths and multi-service processes** — more than one service per process. Examples:
  IIS with multiple application pools, J2EE/JVM servers hosting multiple web contexts.
  SDv2 collapses to one service per process, so these lose the per-application separation
  SDv1 gave them. Leave them on SDv1.
- **Background / scheduled work without an inbound request** — timer-, cron-, or
  thread-triggered services. SDv2 detection is built around request-rooted (inbound
  HTTP/RPC) spans, so background workloads aren't detected as SDv2 services yet and
  continue to be served by SDv1. (More on this in the translations section.)

## The opt-in is yours to define

There is a toggle for **SDv2 for generic workloads (Preview)**. Two things make it
different from the Kubernetes and Lambda experience:

- **No built-in condition and no default match.** For Kubernetes and Lambda, SDv2 knows
  how to scope itself (namespace + cluster, region + account). For generic workloads there
  is no hardcoded condition — **you define the matching condition** that selects which
  workloads opt in, using resource attributes.
- **It's not all-or-nothing.** You opt in at the granularity you choose — per workload, per
  host group, per namespace, per cluster — by writing the condition to match only those
  workloads.

Practical guidance:

- Match as **narrowly** as possible to start. One web server or one single-service process
  is enough to validate the change end to end.
- Confirm the workload is in scope (web server or single-service process) **before** you
  write the condition.
- Expect re-detection to take effect on new traffic after the condition is applied.

## What changes when you opt in

The workload is re-detected under the SDv2 model:

- **One service per deployment, clean by default.** The service is named from
  `service.name` (set `OTEL_SERVICE_NAME` to control it) or the platform/workload name,
  instead of SDv1's process-group–derived names.
- **Downstream dependencies move onto the calling service.** Databases, messaging, and
  external calls are tabs on the service (Database Queries, Message Processing, Outbound
  Calls) rather than separate entities. This matches the Latest Services app model.
- **Entity IDs change** — the breaking change covered in the Preview notice above.

## What keeps working

Switching a generic workload to SDv2 preserves the configuration that matters:

- **Request attributes** defined on SDv1 services or service calls **continue to work** with
  no reconfiguration — the same request attributes populate on the SDv2 services and
  endpoints.
- **SDv1 custom services are ignored**, and their spans/nodes are **grouped into SDv2
  services** by SDv2 detection rules. Your custom-service logic doesn't disappear; the data
  lands on the parent service. If you need metrics from specific spans, extract them via
  OpenPipeline.
- **Baselining and anomaly detection continue** on the SDv2 services and endpoints.
  Endpoints that contribute a meaningful share of a service's load are baselined
  automatically — no key-request lists to maintain.

## Endpoints on web servers

How endpoint names are determined depends on whether the workload provides
`http.route`:

- **Application frameworks** (Spring, Express, Django, ASP.NET Core, Flask, …) provide
  `http.route`, so each route gets its own endpoint and its own metrics automatically.
- **Web servers and reverse proxies** (Nginx, Apache, IIS) **don't** provide `http.route`, so
  all traffic for a given HTTP method collapses into a single endpoint like `GET /*` or
  `POST /*`.

To get per-route endpoints on web servers, use **URL path pattern matching** to normalize
high-cardinality segments, and **request naming rules** that split `GET /*` into `GET /books`,
`GET /orders`, and so on. Each named endpoint then gets its own metrics. A URL-path
normalization heuristic that reduces "over-flattening" to `/` is part of the Preview — if your
environment is web-server-heavy, factor that into your timing.

## Coming from SDv1

**"Will my request attributes still work?"** Yes. Request attributes configured on SDv1
services/service calls keep working after opt-in, with no changes.

**"Where did my custom services go?"** SDv1 custom services are ignored under SDv2. The
spans that fed them are grouped into the SDv2 service by SDv2 detection rules — the data
is on the parent service, not a separate entity. Extract span metrics via OpenPipeline if you
need golden signals for specific spans.

**"My background/cron service still shows 'Requests executed in the Background of …'"** —
expected. SDv2 detection is built around inbound request-rooted spans, so background and
scheduled workloads stay on the SDv1 path for now, where they remain captured,
monitored, and baselined. If you want SDv2-style attribute-driven naming on such a
workload sooner, instrumenting it with the OpenTelemetry SDK directly (OTLP) routes it
through the attribute-first SDv2 OTel path.

**"Can I undo it?"** Disabling the opt-in re-detects the workload under SDv1, but that's a
second migration — IDs change back and baselines reset. Treat enabling and disabling as
deliberate migrations, not a quick experiment.

## Summary: what's in the Preview

| Capability | Status |
|---|---|
| SDv2 for Kubernetes and Lambda (OneAgent) | Generally Available |
| SDv2 for generic workloads (web servers, single-service processes) | **Preview** |
| Customer-defined opt-in condition (resource-attribute matching) | Preview |
| Per-workload / namespace / cluster opt-in granularity | Preview |
| Request attributes preserved after opt-in | Preview |
| SDv1 custom services ignored; spans grouped into SDv2 services | Preview |
| Baselining / anomaly detection on SDv2 services and endpoints | Preview |
| URL path normalization heuristic for web-server endpoints | Preview |
| Monoliths / multi-service processes | Not supported — stay on SDv1 |
| Background / scheduled workloads (no inbound request) | Not supported — stay on SDv1 |

## Try it, carefully

1. Identify a candidate workload that's in scope (web server or single-service process) in a
   **non-production** environment.
2. Check the supported-workloads list linked on the **SDv2 for generic workloads (Preview)**
   toggle.
3. Write a matching condition scoped to just that workload and enable the opt-in.
4. Validate: service name, endpoints, request attributes, downstream tabs, and baselines.
5. Rebuild any dashboards/SLOs/alerts that referenced the old service IDs before you
   expand the scope.

This is a Preview, and your feedback shapes it. If something is detected, named, or scoped
in a way you didn't expect — especially on web-server endpoints — please tell us in the
thread.
