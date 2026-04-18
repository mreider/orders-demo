# Module 0 — Lab setup

> **What you'll know by the end:** your tenant is ready to run every lab in
> this curriculum, and you've verified it by loading and running one
> notebook end-to-end.

Labs run against **your own Dynatrace tenant**, not a shared sandbox. This
module gets your environment ready and sanity-checks the loader.

## What you need

1. **A Dynatrace tenant** you can log into — any SaaS environment works. If
   you have access to multiple, pick the one that matches the workloads you
   want to teach yourself about.
2. **A Kubernetes workload** under monitoring in that tenant, ideally one
   you own or can experiment with. If you don't have one, the companion
   [orders-demo](../../README.md) repo deploys a side-by-side Spring Boot
   workload to any Kubernetes cluster and is used as a fallback in several
   labs.
3. **[`dtctl`](https://github.com/dynatrace-oss/dtctl)** installed locally
   (`brew install dynatrace-oss/tap/dtctl`). This is how you load the lab
   notebooks into your tenant in one command.
4. **A platform access token** (or OAuth login) with these scopes, for
   loading + sharing notebooks:
   - `document:documents:read`
   - `document:documents:write`
   - `document:environment-shares:read`
   - `document:environment-shares:write`
   If your tenant administrator has a "readwrite-all" safety level profile,
   that includes all four.

## First-time login

One-time authentication:

```bash
dtctl auth login
```

Browser opens, you log in via SSO, the token is cached in your OS keychain.

## Load the lab notebooks

Clone the curriculum repo (or this one), then from the repo root:

```bash
for f in curriculum/**/*.yaml; do
  dtctl apply -f "$f" --write-id --share-environment
done
```

What each flag does:

| Flag | Effect |
|---|---|
| `--write-id` | First apply creates the notebook and stamps the new ID back into the YAML so future applies update it in place. |
| `--share-environment` | Creates an environment-wide share. Notebook appears as `isPrivate: false` to everyone in your tenant. Saves manual UI clicking. |

If you see `access denied to document` on a delete or share call, your
OAuth client was issued before the relevant scope was added. Run `dtctl
auth login` again to refresh. For a read/write/share issue, your platform
token needs the scopes listed above.

## Sanity check

Run the **Module 1.1** lab notebook. If you can see a table of DQL results,
your setup works. Proceed to Unit 1.

## Where to find things

| Thing | Location |
|---|---|
| Notebooks in your tenant | Dynatrace UI → **Notebooks** app. Filter by name `Curriculum /`. |
| Module markdown | `curriculum/unit-<n>-<topic>/module-<n>-<m>-<slug>.md` |
| Lab notebook YAML | same directory, `.yaml` sibling of each module's markdown |
| Companion demo (if your tenant lacks a workload) | `../` — see the repo root README. |

## Terminology reminder

This curriculum uses customer-facing terms: **Latest Dynatrace** and
**Classic Dynatrace**. Some technical DQL queries require the internal
identifiers `SDv2` and `UNIFIED` (for the Latest detection model) or
`WEB_REQUEST_SERVICE` / `WEB_SERVICE` (for Classic). Where they appear in
a query, that's why.

## Next

**[Module 1.1 — One workload, one service.](./module-1-1-one-workload-one-service.md)**
Start here.
