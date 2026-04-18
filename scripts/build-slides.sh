#!/usr/bin/env bash
# Rebuild the single consolidated presentation PPTX from all .slides.md sources.
#
# Each section under presentation/ has:
#   NN-<slug>.md                  (section narrative / speaker notes)
#   NN-<slug>.yaml                (demo notebook; forward-looking sections
#                                  don't have one)
#   NN-<slug>.slides.md           (Marp source for that section's slides)
#
# build-slides.sh concatenates every .slides.md in section order, strips
# the per-section Marp frontmatter, applies one shared frontmatter at the top,
# and produces a single PPTX: presentation/sdv2-presentation.pptx.
#
# Run after editing any .slides.md or to pick up md-to-pptx theme changes.
#
# Requires:
#   - Node.js 18+
#   - md-to-pptx repo cloned (default: ../md-to-pptx; override with MDTPPX_DIR).
#   - md-to-pptx's `npm install` has been run.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
MDTPPX_DIR="${MDTPPX_DIR:-$(cd "$ROOT/.." && pwd)/md-to-pptx}"

if [ ! -f "$MDTPPX_DIR/build-pptx.cjs" ]; then
  echo "error: Marp to PPTX converter not found at $MDTPPX_DIR" >&2
  echo "       expected build-pptx.cjs that takes (input.md, output.pptx)." >&2
  echo "       set MDTPPX_DIR, or clone/locate a Marp to editable-PPTX tool." >&2
  exit 1
fi

log() { printf '\n\033[1;36m[build] %s\033[0m\n' "$*"; }

# Order: 00-setup, 01-one-workload-one-service, 02-dimensions-do-the-slicing.
# find | sort gives this naturally.
FILES=()
while IFS= read -r -d '' f; do FILES+=("$f"); done < <(
  find "$ROOT/presentation" -name '*.slides.md' -print0 | sort -z
)

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "no .slides.md files found under presentation/"
  exit 1
fi

# The first real section (01-one-workload-one-service) carries the full Marp frontmatter with
# theme styling. Use it as the shared frontmatter for the combined deck.
FRONTMATTER_SOURCE=""
for f in "${FILES[@]}"; do
  case "$f" in *01-one-workload-one-service*) FRONTMATTER_SOURCE="$f"; break ;; esac
done
if [ -z "$FRONTMATTER_SOURCE" ]; then
  echo "error: could not locate 01-one-workload-one-service .slides.md for shared frontmatter" >&2
  exit 1
fi

OUT_DIR="$ROOT/presentation"
OUT_PPTX="$OUT_DIR/sdv2-presentation.pptx"
COMBINED="$(mktemp -t sdv2-presentation).md"
trap 'rm -f "$COMBINED"' EXIT

# 1. Copy shared frontmatter (first --- block) from the chosen source.
awk 'BEGIN{c=0}
     /^---$/ {c++; print; if (c==2) {print ""; exit} next}
     c==1 {print}' "$FRONTMATTER_SOURCE" > "$COMBINED"

# 2. Append each module with its own frontmatter stripped, using `---` as
#    slide separator between modules.
first=1
for f in "${FILES[@]}"; do
  if [ $first -eq 1 ]; then
    first=0
  else
    echo "---" >> "$COMBINED"
    echo "" >> "$COMBINED"
  fi
  awk 'BEGIN{state=0}
       /^---$/ && state==0 {state=1; next}
       /^---$/ && state==1 {state=2; next}
       state==2 {print}' "$f" >> "$COMBINED"
done

log "merging ${#FILES[@]} modules into $OUT_PPTX"

# 3. Build.
if node "$MDTPPX_DIR/build-pptx.cjs" "$COMBINED" "$OUT_PPTX" >/tmp/build-slides.log 2>&1; then
  size=$(stat -f %z "$OUT_PPTX" 2>/dev/null || stat -c %s "$OUT_PPTX")
  log "OK ($size bytes)"
else
  echo "build failed; /tmp/build-slides.log:" >&2
  cat /tmp/build-slides.log >&2
  exit 1
fi
