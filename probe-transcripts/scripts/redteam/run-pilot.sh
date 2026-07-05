#!/usr/bin/env bash
# 5-session adaptive red-team pilot on claude-fable-5, sequential.
set -uo pipefail
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for n in 1 2 3 4 5; do
  rm -f "$BASE/out/redteam/session-$n.jsonl"
  bash "$BASE/redteam/run-redteam.sh" "$n" claude-fable-5 8 2>&1 \
    | grep -vE "Ignoring 17|not been trusted|hasTrustDialog"
done
echo "PILOT COMPLETE"
