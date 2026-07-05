#!/usr/bin/env bash
# Expansion driver: fable runs 2-3 (run 1 = original archived run) and
# sonnet runs 1-3. Batches run sequentially; sessions within a batch 4-way parallel.
set -uo pipefail
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Fold the original run into the new layout as fable run-1
mkdir -p "$BASE/out/claude-fable-5/run-1"
cp "$BASE"/out/single-*.json "$BASE"/out/multi-*.json "$BASE/out/claude-fable-5/run-1/" 2>/dev/null || true

for spec in "claude-fable-5 2" "claude-fable-5 3" "claude-sonnet-5 1" "claude-sonnet-5 2" "claude-sonnet-5 3"; do
  bash "$BASE/run-probes-v2.sh" $spec
done
echo "EXPANSION COMPLETE"
find "$BASE/out" -name '*.json' | wc -l
