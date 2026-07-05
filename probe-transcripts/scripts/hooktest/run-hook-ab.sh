#!/usr/bin/env bash
# A/B test: does the SessionStart hook's session-start priming raise Sonnet's
# visible-use rate? Matched pair — both conditions use --dangerously-skip-
# permissions (required for the hook to fire headless); the ONLY difference is
# whether the hook body is active. 20 single-turn probes per condition.
set -uo pipefail
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="$BASE/microelectronics-tutor-demo"
PROMPT="$(cat "$REPO/bin/lib/tutor-prompt.md")"
HOOK="$REPO/.claude/hooks/session-start.sh"
MODEL=claude-sonnet-5

cp "$HOOK" "$HOOK.orig"

run_condition() {
  local cond="$1"; local out="$BASE/out/hooktest/$cond"; mkdir -p "$out"
  cd "$REPO"
  local n=0
  while IFS='|' read -r id probe; do
    [ -z "$id" ] && continue
    claude -p "$probe" --model "$MODEL" \
      --append-system-prompt "$PROMPT" \
      --allowedTools "Read" "Glob" "Grep" \
      --dangerously-skip-permissions \
      --output-format json < /dev/null > "$out/single-$id.json" 2>/dev/null &
    n=$((n+1)); [ $((n % 4)) -eq 0 ] && wait
  done < "$BASE/probes-single.txt"
  wait
  echo "done condition $cond ($(ls "$out"/*.json | wc -l | tr -d ' ') files)"
}

# ON: hook as shipped
cp "$HOOK.orig" "$HOOK"
run_condition on

# OFF: hook body neutralized (fires but emits nothing)
printf '#!/usr/bin/env bash\nexit 0\n' > "$HOOK"
run_condition off

# restore
mv "$HOOK.orig" "$HOOK"
echo "HOOK A/B COMPLETE"
