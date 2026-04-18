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

# Module 2.1 — Where names come from

**Span resource attributes, first-match-wins**

---

# The question

Pick two services:

- One well-named — `payments`
- One badly-named — `:8080`, a class path

> *Why does one have a clean name and the other doesn't?*

The answer is a chain of span resource attributes.

---

# The fallback chain

Under Latest, service names come from span resource attributes **in this order**:

1. **`service.name`** (OpenTelemetry) — used directly if present
2. **`k8s.workload.name`** — used if no `service.name`
3. **Cloud-native fallbacks** — `faas.name` for Lambda, task family for ECS
4. **Classic detection residue** — process-group fingerprinting (ports, paths, class names)

---

# What you control

Steps 1–3 are controllable. Emit the right attribute on spans and Latest picks it up.

- OneAgent auto-injects K8s attributes in K8s environments
- OTel instrumentation sets `service.name` if you do (`OTEL_SERVICE_NAME`)
- Step 4 is what you see when nothing above fires

---

# The lab

- Audit raw resource attributes arriving on spans
- Correlate span attributes with the resulting `dt.service.name`
- Compare two workloads — one with `OTEL_SERVICE_NAME` set, one without

---

# What you should see

- **K8s Spring Boot, no OTel**: `service.name` empty → falls back to `k8s.workload.name`
- **OTel app** with `OTEL_SERVICE_NAME=foo`: entity named `foo`
- **Classic service**: ugly detected name (Module 2.3 covers the fix)

---

# In the Dynatrace UI

Compare the row name to the span attributes from the lab:

- Match `service.name` → OTel won
- Match K8s workload → K8s fallback
- Composite `<your-name> (<detected>)` → Classic prefix fix active (Module 2.3)
- Ugly detected string → fallback to Classic residue

---

<!-- _class: title -->

# Next: Module 2.2

**Metric-first queries.**
