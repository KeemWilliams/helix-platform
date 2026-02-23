#!/usr/bin/env bash
set -euo pipefail

# Render all .mmd files in docs/diagrams to SVG using mermaid-cli
# Usage: ./scripts/render-mermaid.sh

# ensure mermaid-cli is installed
if ! command -v mmdc >/dev/null 2>&1; then
  echo "mermaid-cli (mmdc) not found. Install with: npm install -g @mermaid-js/mermaid-cli"
  exit 1
fi

SRC_DIR="docs/diagrams"
mkdir -p "${SRC_DIR}"

for f in "${SRC_DIR}"/*.mmd; do
  [ -f "$f" ] || continue
  base=$(basename "$f" .mmd)
  out="${SRC_DIR}/${base}.svg"
  echo "Rendering $f -> $out"
  mmdc -i "$f" -o "$out"
done

echo "Rendered all Mermaid diagrams."
