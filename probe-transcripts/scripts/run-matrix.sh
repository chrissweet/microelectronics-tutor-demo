#!/usr/bin/env bash
# Prompt x Model visible-use matrix.
# Prompts: demo (weaker [[show:]] rule) vs template (stronger mandatory
# References: rule). Models: fable-5, sonnet-5, opus-4-8.
# 20 single-turn probes per cell, --allowedTools (NO skip-permissions) held
# constant so results are comparable to the existing baseline.
set -uo pipefail
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$BASE/microelectronics-tutor-demo"

# The "template" arm needs the template repo's tutor prompt. It is not vendored
# here (it is the template's content, and pinning a stale copy would drift), so
# fetch it at runtime from llm-wiki-tutor-template if absent. Fail loudly rather
# than run the matrix with an empty prompt, which would silently corrupt results.
TMPL_FILE="$BASE/template-tutor-prompt.md"
if [ ! -s "$TMPL_FILE" ]; then
  echo "fetching template tutor prompt from llm-wiki-tutor-template..." >&2
  if command -v gh >/dev/null 2>&1; then
    gh api repos/chrissweet/llm-wiki-tutor-template/contents/bin/lib/tutor-prompt.md \
      --jq '.content' 2>/dev/null | base64 -d > "$TMPL_FILE" || true
  else
    curl -fsSL "https://raw.githubusercontent.com/chrissweet/llm-wiki-tutor-template/main/bin/lib/tutor-prompt.md" \
      -o "$TMPL_FILE" || true
  fi
fi
if [ ! -s "$TMPL_FILE" ]; then
  echo "ERROR: could not obtain the template tutor prompt ($TMPL_FILE). Fetch it manually from" >&2
  echo "       https://github.com/chrissweet/llm-wiki-tutor-template/blob/main/bin/lib/tutor-prompt.md" >&2
  exit 1
fi

DEMO_PROMPT="$(cat "$REPO/bin/lib/tutor-prompt.md")"
TMPL_PROMPT="$(cat "$TMPL_FILE")"

run_cell() {
  local prompt_name="$1" prompt_text="$2" model="$3"
  local out="$BASE/out/matrix/$prompt_name/$model"; mkdir -p "$out"
  cd "$REPO"
  local n=0
  while IFS='|' read -r id probe; do
    [ -z "$id" ] && continue
    claude -p "$probe" --model "$model" \
      --append-system-prompt "$prompt_text" \
      --allowedTools "Read" "Glob" "Grep" \
      --output-format json < /dev/null > "$out/single-$id.json" 2>/dev/null &
    n=$((n+1)); [ $((n % 4)) -eq 0 ] && wait
  done < "$BASE/probes-single.txt"
  wait
  echo "done $prompt_name / $model ($(ls "$out"/*.json | wc -l | tr -d ' ') files)"
}

for model in claude-fable-5 claude-sonnet-5 claude-opus-4-8; do
  run_cell demo     "$DEMO_PROMPT" "$model"
  run_cell template "$TMPL_PROMPT" "$model"
done
echo "MATRIX COMPLETE"
