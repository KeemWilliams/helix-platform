#!/usr/bin/env bash
set -euo pipefail

# Lints .mmd files for required YAML-like headers
# Example required headers:
# %% id: service-map
# %% owner: @platform-owner
# %% description: High-level service and network map
# %% last_updated: 2026-02-23T00:00:00Z

ERRORS=0

echo "Linting Mermaid diagram headers..."

for f in docs/diagrams/*.mmd; do
  [ -f "$f" ] || continue
  
  MISSING=0
  if ! grep -q "^%% id:" "$f"; then echo "  Error: Missing '%% id:' in $f"; MISSING=1; fi
  if ! grep -q "^%% owner:" "$f"; then echo "  Error: Missing '%% owner:' in $f"; MISSING=1; fi
  if ! grep -q "^%% description:" "$f"; then echo "  Error: Missing '%% description:' in $f"; MISSING=1; fi
  if ! grep -q "^%% last_updated:" "$f"; then echo "  Error: Missing '%% last_updated:' in $f"; MISSING=1; fi
  
  if [ "$MISSING" -eq 1 ]; then
    ERRORS=1
  else
    echo "  $f is valid."
  fi
done

if [ "$ERRORS" -eq 1 ]; then
  echo "Mermaid header linting failed! Please add the required metadata headers to your .mmd files."
  exit 1
else
  echo "All Mermaid diagram headers are valid."
fi
