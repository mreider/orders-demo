#!/usr/bin/env bash
# Rebuild every curriculum PPTX from its .slides.md source.
#
# Each module under curriculum/ has:
#   module-<n>-<slug>.md          (learner-facing narrative)
#   module-<n>-<slug>.yaml        (executable lab notebook)
#   module-<n>-<slug>.slides.md   (Marp source for the slide deck)
#   module-<n>-<slug>.pptx        (editable PowerPoint, committed to the repo)
#
# build-slides.sh regenerates every .pptx from its .slides.md sibling.
# Use it after editing any .slides.md, or to pick up changes in the
# md-to-pptx theme/CSS.
#
# Requires:
#   - Node.js 18+
#   - md-to-pptx repo cloned somewhere (default: ../md-to-pptx, override
#     with MDTPPX_DIR env var or clone the Bitbucket repo referenced in
#     README.md).
#   - md-to-pptx's `npm install` has been run (PptxGenJS dependency).

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
MDTPPX_DIR="${MDTPPX_DIR:-$(cd "$ROOT/.." && pwd)/md-to-pptx}"

if [ ! -f "$MDTPPX_DIR/build-pptx.cjs" ]; then
  echo "error: md-to-pptx not found at $MDTPPX_DIR" >&2
  echo "       clone https://bitbucket.lab.dynatrace.org/scm/~matthew.reider/md-to-dt-pptx.git" >&2
  echo "       and run 'npm install' in it, or set MDTPPX_DIR to its location." >&2
  exit 1
fi

log() { printf '\n\033[1;36m[build] %s\033[0m\n' "$*"; }

count=$(find "$ROOT/curriculum" -name '*.slides.md' | wc -l | tr -d ' ')
if [ "$count" -eq 0 ]; then
  echo "no .slides.md files found under curriculum/"
  exit 1
fi

log "rebuilding $count decks"

find "$ROOT/curriculum" -name '*.slides.md' | sort | while read -r src; do
  out="${src%.slides.md}.pptx"
  name="$(basename "$src")"
  printf '  %-60s ' "$name"
  if node "$MDTPPX_DIR/build-pptx.cjs" "$src" "$out" >/tmp/build-slides.log 2>&1; then
    size=$(stat -f %z "$out" 2>/dev/null || stat -c %s "$out")
    printf 'OK (%s bytes)\n' "$size"
  else
    echo "FAIL"
    cat /tmp/build-slides.log
  fi
done

log "done. Review PPTX files under curriculum/, open any in PowerPoint to eyeball."
