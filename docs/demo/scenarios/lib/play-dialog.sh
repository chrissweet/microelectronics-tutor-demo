#!/usr/bin/env bash
# play-dialog.sh — replay a dialog script with streamed terminal output.
#
# Designed to be driven by VHS for the conference demo videos. Single-pane:
# student/agent lines stream like real typing, and `wiki` directives clear
# the screen and render a wiki page via glow for the audience to read.
#
# Dialog file format (one directive per line; `|` is the separator):
#   ;comment              — ignored
#   >system|Message       — magenta system text (setup overlays, scene labels)
#   >student|Message      — cyan, char-by-char (simulates a student typing)
#   >assistant|Message    — green, char-by-char (Video 1: generic LLM reply)
#   >tutor|Message        — yellow, char-by-char (Video 2: course-aware tutor)
#   >instructor|Message   — bold red (the diagnostic question)
#   >caption|Message      — boxed centered caption
#   >code|line            — monospaced code line (literal, no streaming)
#   >code-block|...~~...  — multiple code lines separated by `~~`
#   >pause|N              — sleep N seconds (decimals allowed)
#   >clear                — clear the screen
#   >wiki|Page-Name       — clear screen, render wiki/Page-Name.md via glow,
#                           then sleep $WIKI_HOLD seconds (default 6)
#   >bell                 — terminal bell (audio cue for editing markers)
#
# Speeds can be overridden via env:
#   STUDENT_DELAY=0.025 TUTOR_DELAY=0.012 ASSISTANT_DELAY=0.010 WIKI_HOLD=6

set -euo pipefail

dialog_file="${1:-}"
if [[ -z "$dialog_file" ]]; then
  echo "usage: $0 <dialog-file>" >&2
  exit 1
fi

STUDENT_DELAY="${STUDENT_DELAY:-0.022}"
TUTOR_DELAY="${TUTOR_DELAY:-0.012}"
ASSISTANT_DELAY="${ASSISTANT_DELAY:-0.010}"
INSTRUCTOR_DELAY="${INSTRUCTOR_DELAY:-0.020}"
WIKI_HOLD="${WIKI_HOLD:-6}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIKI_DIR="${WIKI_DIR:-$script_dir/../../../../wiki/microelectronics-tutor-demo.wiki}"

C_RESET=$'\033[0m'
C_DIM=$'\033[2m'
C_BOLD=$'\033[1m'
C_STUDENT=$'\033[1;36m'
C_TUTOR=$'\033[1;33m'
C_ASSISTANT=$'\033[1;32m'
C_SYSTEM=$'\033[1;35m'
C_INSTRUCTOR=$'\033[1;31m'
C_CAPTION=$'\033[1;37m'

stream() {
  local text="$1" delay="$2" i
  for (( i=0; i<${#text}; i++ )); do
    printf "%s" "${text:$i:1}"
    sleep "$delay"
  done
  printf "\n"
}

play_caption() {
  local body="$1"
  local len=${#body}
  local pad
  pad=$(printf '─%.0s' $(seq 1 $(( len + 4 ))))
  printf "\n${C_CAPTION}┌%s┐${C_RESET}\n" "$pad"
  printf "${C_CAPTION}│  %s  │${C_RESET}\n" "$body"
  printf "${C_CAPTION}└%s┘${C_RESET}\n\n" "$pad"
}

play_wiki() {
  local page="$1"
  local path="$WIKI_DIR/$page.md"
  clear
  if [[ -f "$path" ]]; then
    printf "${C_DIM}── wiki: %s ──────────────────────────────${C_RESET}\n\n" "$page"
    # Strip [Display](Page-Name) link targets so glow doesn't expand
    # them to ugly absolute file paths in the rendered output.
    sed -E 's/\[([^]]+)\]\([^)]+\)/\1/g' "$path" \
      | glow -s dark -w 100 - 2>/dev/null \
      || cat "$path"
  else
    printf "${C_INSTRUCTOR}[wiki page not found: %s]${C_RESET}\n" "$path"
  fi
  sleep "$WIKI_HOLD"
  clear
}

play_line() {
  local kind="$1" body="${2-}"
  case "$kind" in
    system)
      printf "${C_SYSTEM}%s${C_RESET}\n" "$body"
      ;;
    student)
      if [[ -z "$body" ]]; then printf "\n"; else
        printf "${C_STUDENT}student${C_DIM} ❯${C_RESET} "
        stream "$body" "$STUDENT_DELAY"
        printf "\n"
      fi
      ;;
    assistant)
      if [[ -z "$body" ]]; then printf "\n"; else
        printf "${C_ASSISTANT}assistant${C_DIM} ❯${C_RESET} "
        stream "$body" "$ASSISTANT_DELAY"
        printf "\n"
      fi
      ;;
    tutor)
      if [[ -z "$body" ]]; then printf "\n"; else
        printf "${C_TUTOR}tutor${C_DIM} ❯${C_RESET} "
        stream "$body" "$TUTOR_DELAY"
        printf "\n"
      fi
      ;;
    instructor)
      if [[ -z "$body" ]]; then printf "\n"; else
        printf "${C_INSTRUCTOR}instructor${C_DIM} ❯${C_RESET} "
        stream "$body" "$INSTRUCTOR_DELAY"
        printf "\n"
      fi
      ;;
    code)
      printf "${C_DIM}  %s${C_RESET}\n" "$body"
      ;;
    code-block)
      local expanded="${body//~~/$'\n'}"
      while IFS= read -r part; do
        printf "${C_DIM}  %s${C_RESET}\n" "$part"
      done <<< "$expanded"
      ;;
    caption)
      play_caption "$body"
      ;;
    pause)
      sleep "$body"
      ;;
    clear)
      clear
      ;;
    wiki)
      play_wiki "$body"
      ;;
    bell)
      printf '\a'
      ;;
    *)
      printf "${C_INSTRUCTOR}[unknown directive: %s]${C_RESET}\n" "$kind"
      ;;
  esac
}

while IFS= read -r line <&9 || [[ -n "$line" ]]; do
  [[ -z "$line" || "$line" =~ ^[[:space:]]*\; ]] && continue
  if [[ "$line" =~ ^\>([a-z-]+)\|(.*)$ ]]; then
    play_line "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
  elif [[ "$line" =~ ^\>([a-z-]+)$ ]]; then
    play_line "${BASH_REMATCH[1]}"
  fi
done 9< "$dialog_file"
