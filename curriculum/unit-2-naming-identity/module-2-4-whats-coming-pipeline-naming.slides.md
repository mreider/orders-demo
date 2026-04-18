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

# Module 2.4 — What's coming

**Pipeline-side name control**

---

# Today's workaround

Module 2.3's `service.name` fix requires touching every workload.

At enterprise scale that's friction:

- Thousands of workloads
- Teams that don't own every deployment
- Third-party images
- Every rename = another deploy

---

# The direction

Naming moves into **OpenPipeline** — the server-side processing layer spans already flow through.

- Tenant admin writes a processing rule
- Rule sets `dt.service.name` on incoming spans before entity and metric extraction
- Same central-control UX as the old Classic naming-rules overlay
- Operates on resource attributes; composable with other pipeline processing

---

# Why it's not here yet

Three platform prerequisites:

1. Pipeline rules need permission to modify `dt.*` attributes (today read-only)
2. Entity creation must move **after** processing so rules can affect the entity graph
3. Batched topology updates — to avoid storms from tenant-wide renames

No committed external timeline. Watch the Dynatrace community for 2026 milestones.

---

# What to do today

- Use the **service.name workaround** (Module 2.3) for Classic services you own
- Don't invest new effort in Services Classic naming-rules — being retired
- Pick a `service.name` that will survive both the SDv2 move and the pipeline-naming move

---

<!-- _class: title -->

# Next: Unit 3

**Endpoints, dependencies, scale.**
