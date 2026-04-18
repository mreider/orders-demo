---
marp: true
theme: uncover
class: invert
paginate: true
style: |
  section {
    background: linear-gradient(180deg, #0a0a14 0%, #0d0d1a 100%);
    font-family: 'Segoe UI', 'Arial', sans-serif;
    padding: 50px 70px 40px 70px;
    color: #ffffff;
    text-align: left;
    overflow: hidden;
  }
  section.title {
    text-align: center;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
  }
  section.title h1 {
    text-align: center;
    border-bottom: 4px solid;
    border-image: linear-gradient(90deg, #00a1e0, #b455b6) 1;
    padding-bottom: 16px;
    margin-bottom: 0;
    font-size: 1.8em;
  }
  h1 {
    color: #ffffff;
    font-size: 1.6em;
    font-weight: 700;
    text-align: left;
    border-bottom: 3px solid;
    border-image: linear-gradient(90deg, #00a1e0, #b455b6) 1;
    padding-bottom: 10px;
    margin-bottom: 20px;
    margin-top: 0;
  }
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
  .avail { font-size: 0.7em; margin-top: 16px; padding: 8px 12px; background: rgba(255,255,255,0.05); border-radius: 4px; }
---

<!-- _class: title -->

# Module 2.1 — Where Names Come From

**Unit 2: Naming and identity**

---

# The Question

Open the Services app. Pick a cleanly-named service (e.g. `payments`).

Now pick an ugly one (e.g. `:8080`, `/`, or a Java class path).

> *Why does one have a clean name and the other doesn't?*

The answer is a chain of span resource attributes. Whichever Dynatrace finds first, wins.

---

# The Naming Fallback Chain

Under Latest, names are produced from span resource attributes in this order:

1. **`service.name`** (OpenTelemetry convention) — used directly if set
2. **`k8s.workload.name`** — used in Kubernetes when no `service.name`
3. **Cloud-native fallbacks** — `faas.name` for Lambda, ECS task family, etc.
4. **Classic detection residue** — process-group fingerprinting (ports, paths, class names)

You see option 4 when nothing above fires.

---

# Every Step Is Something You Control

Every step above the last is something you can set by emitting the right resource attribute:

- **OneAgent** auto-injects K8s attributes for you
- **OTel instrumentation** sets `service.name` if you do
- **Manual env var** — `OTEL_SERVICE_NAME=<name>` works on any container

Module 2.3 walks through the workaround for legacy services.

---

# Why This Matters

- **Clean names are the default you earn by instrumenting.** Latest's best-case naming depends on your spans, not on a UI rule overlay.
- **Naming rules are deprecated.** The Classic UI overlay that turned `:8080` into `checkout-service` is going away.
- **Environment is a dimension, not a name.** Don't stuff `prod`/`staging` into the name — use `k8s.namespace.name` or `deployment.environment`.

---

# What the Lab Does

Open the companion notebook in your tenant: **Curriculum / Module 2.1**.

Three queries:

1. **Span audit.** What resource attributes actually arrive on the spans?
2. **Which attribute won?** Correlate span attributes with the entity name.
3. **Compare two workloads.** Same `k8s.workload.name`, one with `service.name` set and one without — see the entity names diverge.

---

# What You Should See

| Workload type | Resulting name source |
|---|---|
| K8s + OneAgent, no OTel | `k8s.workload.name` (Deployment name) |
| OTel-instrumented with `OTEL_SERVICE_NAME` | `service.name` |
| Classic-detected legacy app | Detection residue (ugly) |

Module 2.3 covers what to do about that last row.

---

<!-- _class: screenshot -->

# What to Look For in the UI

![placeholder](assets/placeholder-service-properties.png)

**SCREENSHOT:** Services app — service detail page, Properties side-panel
- Show a service row with a clean name in the list
- Open Properties — highlight `k8s.workload.name`, `k8s.namespace.name`, and `service.name` (if set)
- Compare with an ugly-named row (port-only or class path) where `service.name` is empty
- **Key point:** The name in the list maps directly back to the resource attributes shown in Properties

---

<!-- _class: title -->

# Next: Module 2.2

**Metric-first queries — skip the entity table**

The second benefit of good naming: `dt.service.name` is a queryable metric dimension, which makes your DQL dramatically shorter.
