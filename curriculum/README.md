# Services in Latest Dynatrace — a curriculum

A 90-minute self-paced course for Dynatrace customers on how services work under the Latest detection model and how it differs from Classic. Each module pairs a short concept narrative with a hands-on lab notebook that runs against your own tenant.

| Unit | Focus | Modules |
|---|---|---|
| **1 — What is a service, really?** | Entity-first → attribute-first | 1.1 · 1.2 · 1.3 · 1.4 |
| **2 — Naming and identity** | Where names come from, how queries shorten | 2.1 · 2.2 · 2.3 · *2.4* |
| **3 — Endpoints, dependencies, scale** | Endpoints, downstreams, per-environment views | 3.1 · 3.2 · 3.3 · *3.4* |

Module 0 is lab setup. Modules marked *italic* are forward-looking (no lab).

## Loading the labs

```bash
dtctl auth login
for f in curriculum/**/*.yaml; do dtctl apply -f "$f" --write-id --share-environment; done
```
