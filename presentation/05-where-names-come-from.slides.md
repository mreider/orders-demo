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

# Where names come from

**Every service name traces back to a single span attribute.**

---

# The point

Service names are not arbitrary. They are the output of a deterministic fallback chain on span resource attributes.

- Know the chain and ugly names stop being mysterious
- The first 3 steps are controllable; step 4 is what you see when nothing else fires
- SDv1 runs the same chain, then fragments the result

---

# The fallback chain (SDv2)

First-match-wins on span resource attributes:

1. **`service.name`** (OpenTelemetry). Used directly if present.
2. **`k8s.workload.name`**. Used when `service.name` is absent.
3. **Cloud-native fallbacks**. `faas.name` for Lambda, task family for ECS.
4. **SDv1 detection residue**. Process-group fingerprinting (ports, paths, class names).

OneAgent auto-injects K8s attributes. OTel instrumentation sets `service.name` if you configure it.

---

# SDv1 does the same, then fragments

SDv1 applies the same chain, then the detection layer slices the result into per-class fragments:

- `<detected> - OrderController`
- `<detected> - InventoryController`
- `OrderEventsListener`

One Spring Boot workload, seven `dt.service.name` values. That is SDv1 on a Grail tenant.

---

# See it in the Services app

**Demo: Where names come from** (`05-where-names-come-from.yaml`)

Match the row name to the span attributes:

- Matches `service.name`: OTel won
- Matches K8s workload: K8s fallback fired
- Composite `<your-name> (<detected>)`: Classic prefix fix is active
- Ugly detected string: fell all the way to SDv1 residue
