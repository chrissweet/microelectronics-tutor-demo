#!/usr/bin/env bash
# Adversarial probe runner for the microelectronics tutor.
# Single-turn probes run 4-way parallel; multi-turn escalations run
# sequentially per script (session resume), scripts in parallel.
set -uo pipefail

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$BASE/microelectronics-tutor-demo"
OUT="$BASE/out"
PROMPT="$(cat "$REPO/bin/lib/tutor-prompt.md")"
mkdir -p "$OUT"
cd "$REPO"

run_single() {
  local id="$1" probe="$2"
  claude -p "$probe" \
    --append-system-prompt "$PROMPT" \
    --allowedTools "Read" "Glob" "Grep" \
    --output-format json < /dev/null > "$OUT/single-$id.json" 2> "$OUT/single-$id.err"
  echo "done single $id"
}

run_multi() {
  local id="$1" t1="$2" t2="$3" t3="$4"
  local sid
  claude -p "$t1" --append-system-prompt "$PROMPT" \
    --allowedTools "Read" "Glob" "Grep" \
    --output-format json < /dev/null > "$OUT/multi-$id-t1.json" 2> "$OUT/multi-$id.err"
  sid=$(python3 -c "import json,sys; print(json.load(open('$OUT/multi-$id-t1.json'))['session_id'])" 2>>"$OUT/multi-$id.err") || { echo "FAILED multi $id (no session id)"; return 1; }
  claude -p "$t2" --resume "$sid" --append-system-prompt "$PROMPT" \
    --allowedTools "Read" "Glob" "Grep" \
    --output-format json < /dev/null > "$OUT/multi-$id-t2.json" 2>> "$OUT/multi-$id.err"
  claude -p "$t3" --resume "$sid" --append-system-prompt "$PROMPT" \
    --allowedTools "Read" "Glob" "Grep" \
    --output-format json < /dev/null > "$OUT/multi-$id-t3.json" 2>> "$OUT/multi-$id.err"
  echo "done multi $id"
}

# Single-turn probes, 4 at a time
n=0
while IFS='|' read -r id probe; do
  [ -z "$id" ] && continue
  run_single "$id" "$probe" &
  n=$((n+1))
  if [ $((n % 4)) -eq 0 ]; then wait; fi
done < "$BASE/probes-single.txt"
wait

# Multi-turn escalations, all 5 in parallel (each is internally sequential)
while IFS='|' read -r id t1 t2 t3; do
  [ -z "$id" ] && continue
  run_multi "$id" "$t1" "$t2" "$t3" &
done < "$BASE/probes-multi.txt"
wait

echo "ALL PROBES COMPLETE"
ls "$OUT" | wc -l
