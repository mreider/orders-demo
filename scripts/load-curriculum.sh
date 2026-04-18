#!/usr/bin/env bash
# Load curriculum notebooks into a Dynatrace tenant, make each one
# environment-shared with isPrivate=false. Works with any upstream dtctl
# version. Once dtctl PR #165 is merged and released, `dtctl apply -f
# <file> --share-environment --write-id` alone replaces this wrapper.
#
# Per-notebook steps:
#   1. dtctl apply -f <yaml> --write-id    (creates + stamps id into file)
#   2. curl POST  /environment-shares      (creates a read-access share)
#   3. curl PATCH /documents/<id>          (flips isPrivate=false)
#
# Required env vars:
#   DT_ENV              e.g. https://abc12345.apps.dynatrace.com
#   DT_PLATFORM_TOKEN   dt0s16.* token with scopes:
#                       document:documents:read, document:documents:write,
#                       document:environment-shares:read,
#                       document:environment-shares:write
#
# dtctl must already be authenticated (`dtctl auth login`).

set -euo pipefail

: "${DT_ENV:?DT_ENV is required (e.g. https://abc12345.apps.dynatrace.com)}"
: "${DT_PLATFORM_TOKEN:?DT_PLATFORM_TOKEN is required — see SETUP.md step 1c}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

log() { printf '\n\033[1;36m[load] %s\033[0m\n' "$*"; }
warn() { printf '\n\033[1;33m[warn] %s\033[0m\n' "$*" >&2; }

for bin in jq dtctl curl; do
  command -v "$bin" >/dev/null || { echo "missing dependency: $bin"; exit 1; }
done

# Collect every notebook YAML: the 11 curriculum labs + the home notebook.
# Portable (POSIX sh arrays — bash 3.2 compatible on macOS).
FILES_TMP=$(mktemp)
find "$ROOT/curriculum" -name '*.yaml' -not -name '*.slides.md' | sort > "$FILES_TMP"
[ -f "$ROOT/notebooks/home.yaml" ] && echo "$ROOT/notebooks/home.yaml" >> "$FILES_TMP"

count=$(wc -l < "$FILES_TMP" | tr -d ' ')
if [ "$count" -eq 0 ]; then
  rm -f "$FILES_TMP"
  echo "no notebook YAMLs found under curriculum/ or notebooks/"
  exit 1
fi

log "loading $count notebooks into $DT_ENV"

while read -r f; do
  name=$(basename "$f")
  printf '  %-60s ' "$name"

  # 1. Apply via dtctl. --write-id stamps the generated ID into the YAML
  # so re-runs update in place. -o json gives us the id cleanly.
  if ! out=$(dtctl apply -f "$f" --write-id -o json 2>&1); then
    echo "FAIL (apply)"
    echo "$out" >&2
    continue
  fi
  id=$(echo "$out" | jq -r '.result.id // empty' 2>/dev/null || true)
  if [ -z "$id" ]; then
    echo "FAIL (no id in apply output)"
    continue
  fi

  # 2. Create environment share (idempotent: 409 means a share already exists).
  share_resp=$(curl -sS -o /tmp/share.body -w '%{http_code}' \
    -X POST \
    -H "Authorization: Bearer $DT_PLATFORM_TOKEN" \
    -H "Content-Type: application/json" \
    "$DT_ENV/platform/document/v1/environment-shares" \
    -d "{\"documentId\":\"$id\",\"access\":\"read\"}" || true)
  case "$share_resp" in
    201|200|409) : ;;
    *)
      warn "env-share failed for $id (HTTP $share_resp): $(cat /tmp/share.body)"
      ;;
  esac

  # 3. Flip isPrivate=false via PATCH to /documents/{id}. Needs the current
  # version for optimistic locking.
  version=$(curl -sS \
    -H "Authorization: Bearer $DT_PLATFORM_TOKEN" \
    "$DT_ENV/platform/document/v1/documents/$id/metadata" \
    | jq -r '.version // 1')

  patch_resp=$(curl -sS -o /tmp/patch.body -w '%{http_code}' \
    -X PATCH \
    -H "Authorization: Bearer $DT_PLATFORM_TOKEN" \
    "$DT_ENV/platform/document/v1/documents/$id?optimistic-locking-version=$version" \
    -F "isPrivate=false" || true)
  case "$patch_resp" in
    200|204) : ;;
    409)
      warn "isPrivate PATCH 409 for $id — concurrent update; rerun to retry"
      ;;
    *)
      warn "isPrivate PATCH failed for $id (HTTP $patch_resp): $(cat /tmp/patch.body)"
      ;;
  esac

  echo "OK ($id)"
done < "$FILES_TMP"
rm -f "$FILES_TMP"

log "done. Open the Notebooks app and filter by 'Curriculum /'."
