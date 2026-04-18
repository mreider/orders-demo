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
---

<!-- _class: title -->

# Module 0 — Lab setup

**Get your tenant ready to run every lab in 3 minutes**

---

# Prereqs

- Dynatrace SaaS tenant you can log into
- A Kubernetes workload under monitoring (or `orders-demo` deployed to any cluster)
- **`dtctl`** installed: `brew install dynatrace-oss/tap/dtctl`
- Platform token with **four scopes**:
  - `document:documents:read`
  - `document:documents:write`
  - `document:environment-shares:read`
  - `document:environment-shares:write`

---

# Load the Labs

One-time auth, then apply every notebook in the tree:

```bash
dtctl auth login

for f in curriculum/**/*.yaml; do
  dtctl apply -f "$f" --write-id --share-environment
done
```

- `--write-id` stamps the notebook ID back so future applies update in place
- `--share-environment` makes the notebook visible tenant-wide

---

# Sanity Check

1. Open the **Notebooks** app in your tenant
2. Filter by name `Curriculum /`
3. Open **Module 1.1** and run its first query

If results come back, you're ready for Unit 1.

---

<!-- _class: title -->

# Next: Module 1.1

**One workload, one service.**
