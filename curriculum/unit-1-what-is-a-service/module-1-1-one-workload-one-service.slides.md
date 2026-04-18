---
marp: true
theme: uncover
class: invert
paginate: true
style: |
  /* ===== OVERFLOW PREVENTION ===== */
  section {
    background: linear-gradient(180deg, #0a0a14 0%, #0d0d1a 100%);
    font-family: 'Segoe UI', 'Arial', sans-serif;
    padding: 50px 70px 40px 70px;
    color: #ffffff;
    text-align: left;
    overflow: hidden;
  }

  /* ===== TITLE SLIDE ===== */
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

  /* ===== HEADERS ===== */
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

  /* ===== BODY TEXT ===== */
  p {
    font-size: 0.78em;
    line-height: 1.5;
    margin: 10px 0;
  }

  /* ===== LISTS ===== */
  ul, ol {
    font-size: 0.78em;
    line-height: 1.5;
    margin: 8px 0;
    padding-left: 24px;
  }

  li {
    margin-bottom: 6px;
  }

  /* ===== EMPHASIS ===== */
  strong {
    color: #00a1e0;
  }

  code {
    font-size: 0.75em;
    background: rgba(255,255,255,0.1);
    padding: 2px 6px;
    border-radius: 3px;
  }

  /* ===== CODE BLOCKS ===== */
  pre {
    font-size: 0.6em;
    margin: 12px 0;
    background: rgba(0,0,0,0.3);
    padding: 15px;
    border-radius: 5px;
  }

  /* ===== TABLES ===== */
  table {
    font-size: 0.68em;
    margin: 12px 0;
    border-collapse: collapse;
    width: 100%;
  }

  th {
    background: rgba(0,161,224,0.25);
    padding: 6px 10px;
    text-align: left;
    border-bottom: 2px solid #00a1e0;
  }

  td {
    padding: 6px 10px;
    border-bottom: 1px solid rgba(255,255,255,0.15);
  }

  /* ===== IMAGES ===== */
  img {
    max-width: 90%;
    max-height: 280px;
    border-radius: 6px;
  }

  /* ===== AVAILABILITY LEGEND ===== */
  .avail {
    font-size: 0.7em;
    margin-top: 16px;
    padding: 8px 12px;
    background: rgba(255,255,255,0.05);
    border-radius: 4px;
  }
---

<!-- _class: title -->

# Module 1.1 — One Workload, One Service

**Unit 1: What is a service?**

---

# The Question

Open the Services app. Pick one of your Kubernetes-deployed services.

> *How many service entities does Dynatrace show for this one workload?*

Most people's gut answer is **one**.

That's true under **Latest Dynatrace**. It is not true under **Classic**.

---

# The Claim

In **Latest Dynatrace**, one Kubernetes workload equals one service entity.

One Deployment, one StatefulSet — **one row** in the Services app, no matter how many controllers, listeners, or client libraries live in the pod.

---

# What Classic Does Instead

The same Spring Boot app — two REST controllers and a Kafka listener — fragments into **four entities** under Classic:

- A `WEB_REQUEST_SERVICE` for the workload aggregate
- Two `WEB_SERVICE` entities, one per controller class
- A `MESSAGING_SERVICE` for the Kafka consumer

Each entity has its own health, name, baseline, and alert.

---

# The Real Shift

The change from Classic to Latest is not a rename. It is a change in the **unit of slicing**.

- **Classic**: slice by **entity**. New controller, new entity.
- **Latest**: slice by **attribute**. New controller, new dimension value on the same entity.

Every other module in this curriculum builds on this.

---

# Why This Matters First

Nothing else in the Latest Services app makes sense without this shift:

- **Baselines** attach to dimension values, not to entities
- **Endpoint health** rolls up into the workload, not a separate WEB_SERVICE
- **Ownership** is assigned to the workload, not to each controller
- **Alerts** cover the workload by default

When Latest UI behavior surprises you, the mismatch starts here.

---

# What the Lab Does

Open the companion notebook in your tenant: **Curriculum / Module 1.1**.

Three queries on a workload you pick:

1. **Count.** How many SERVICE entities does this workload produce?
2. **Classify.** Which detection model is this namespace on?
3. **Compare.** What are the entity names, and what does each represent?

Falls back to the `orders-demo` companion app if you have no workload with both modes observed.

---

# What You Should See

- **Latest workload**: one row. Name from `k8s.workload.name`, or from `service.name` if your app sets it.
- **Classic workload**: 4–10 rows for a non-trivial app. Names like `my-app - UserController`, `my-app`, `OrderEventsListener`.

If both: keep the picture. Module 1.4 uses the contrast directly.

---

<!-- _class: screenshot -->

# What to Look For in the UI

![placeholder](assets/placeholder-services-list-one-row.png)

**SCREENSHOT:** Services app — Services list filtered to one workload
- Show one row for a Latest-detected workload
- Compare with a Classic-detected workload showing 4+ rows for the same app
- Highlight the count difference at the top of the list
- **Key point:** The detection model decides whether you see one row or many

---

<!-- _class: title -->

# Next: Module 1.2

**The three transport families**

Whether your workload is one entity or ten, its activity is counted as one of three things — requests, message processing, or function invocations.
