#!/usr/bin/env bash
# Probe runner v2 — parameterized by model and run number.
# Usage: run-probes-v2.sh <model> <run-number>
# Output: out/<model>/run-<N>/{single-ID.json, multi-ID-tT.json}
set -uo pipefail

MODEL="$1"; RUN="$2"
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$BASE/microelectronics-tutor-demo"
OUT="$BASE/out/$MODEL/run-$RUN"
PROMPT="$(cat "$REPO/bin/lib/tutor-prompt.md")"
mkdir -p "$OUT"
cd "$REPO"

run_single() {
  local id="$1" probe="$2"
  claude -p "$probe" --model "$MODEL" \
    --append-system-prompt "$PROMPT" \
    --allowedTools "Read" "Glob" "Grep" \
    --output-format json < /dev/null > "$OUT/single-$id.json" 2> "$OUT/single-$id.err"
  echo "done $MODEL run-$RUN single $id"
}

run_multi() {
  local id="$1" t1="$2" t2="$3" t3="$4"
  local sid
  claude -p "$t1" --model "$MODEL" --append-system-prompt "$PROMPT" \
    --allowedTools "Read" "Glob" "Grep" \
    --output-format json < /dev/null > "$OUT/multi-$id-t1.json" 2> "$OUT/multi-$id.err"
  sid=$(python3 -c "import json; print(json.load(open('$OUT/multi-$id-t1.json'))['session_id'])" 2>>"$OUT/multi-$id.err") || { echo "FAILED $MODEL run-$RUN multi $id"; return 1; }
  claude -p "$t2" --resume "$sid" --model "$MODEL" --append-system-prompt "$PROMPT" \
    --allowedTools "Read" "Glob" "Grep" \
    --output-format json < /dev/null > "$OUT/multi-$id-t2.json" 2>> "$OUT/multi-$id.err"
  claude -p "$t3" --resume "$sid" --model "$MODEL" --append-system-prompt "$PROMPT" \
    --allowedTools "Read" "Glob" "Grep" \
    --output-format json < /dev/null > "$OUT/multi-$id-t3.json" 2>> "$OUT/multi-$id.err"
  echo "done $MODEL run-$RUN multi $id"
}

n=0
while IFS='|' read -r id probe; do
  [ -z "$id" ] && continue
  run_single "$id" "$probe" &
  n=$((n+1))
  if [ $((n % 4)) -eq 0 ]; then wait; fi
done < "$BASE/probes-single.txt"
wait

while IFS='|' read -r id t1 t2 t3; do
  [ -z "$id" ] && continue
  run_multi "$id" "$t1" "$t2" "$t3" &
done < "$BASE/probes-multi.txt"
wait

echo "BATCH COMPLETE: $MODEL run-$RUN ($(ls "$OUT" | grep -c 'json$') json files)"
