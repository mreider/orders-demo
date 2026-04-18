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

# Module 0 — Lab Setup

**Get your tenant ready to run the curriculum**

---

# What This Module Does

Every lab in this curriculum runs against **your own Dynatrace tenant**, not a shared sandbox.

By the end of this module, your environment is ready and you've verified it by loading and running one notebook end-to-end.

---

# What You Need

- A **Dynatrace SaaS tenant** you can log into
- A **Kubernetes workload** under monitoring (or use the `orders-demo` companion app)
- **`dtctl`** installed locally — `brew install dynatrace-oss/tap/dtctl`
- A **platform access token** with document read/write/share scopes

---

# Required Token Scopes

If your token has a `readwrite-all` profile, you're covered. Otherwise:

- `document:documents:read`
- `document:documents:write`
- `document:environment-shares:read`
- `document:environment-shares:write`

These let `dtctl` create, update, and share lab notebooks across your tenant.

---

# First-Time Login

One-time authentication — opens a browser for SSO, then caches the token in your OS keychain:

```bash
dtctl auth login
```

Re-run this if you ever see `access denied to document` — it usually means a scope was added after your last login.

---

# Load the Lab Notebooks

Clone the curriculum repo, then from the repo root:

```bash
for f in curriculum/**/*.yaml; do
  dtctl apply -f "$f" --write-id --share-environment
done
```

- **`--write-id`** stamps the new notebook ID into the YAML so future applies update in place
- **`--share-environment`** makes each notebook visible to everyone in your tenant — no manual UI sharing needed

---

# Sanity Check

Open the **Notebooks** app in your tenant, filter by name `Curriculum /`, and run the **Module 1.1** notebook.

If you see a table of DQL results, your setup works.

If not — re-run `dtctl auth login`, check your token scopes, confirm `dtctl` is on your PATH.

---

# A Note on Terminology

This curriculum uses customer-facing terms:

- **Latest Dynatrace** — the new detection model
- **Classic Dynatrace** — the legacy model

Some DQL queries use the internal identifiers `SDv2`, `UNIFIED`, `WEB_REQUEST_SERVICE`, `WEB_SERVICE` because the data layer requires them. That's the only place you'll see internal labels.

---

<!-- _class: title -->

# Next: Module 1.1

**One workload, one service**

The first concept the rest of the curriculum builds on.
