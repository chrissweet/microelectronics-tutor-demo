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
#   >wiki|Page-Name       — print an inline GitHub URL pointing at the wiki page;
#                           the tutor's prose has already quoted the relevant
#                           section, so this is a reference, not a takeover.
#                           Override base URL via WIKI_URL_BASE env var.
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
  local raw="$1" delay="$2" text i
  # Expand literal \n in the body to actual newlines so captured multi-paragraph
  # responses (from real Claude sessions) render correctly. Authors can also
  # use \n in scripted dialog files to force a line break inside one directive.
  text="${raw//\\n/$'\n'}"
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
  # Inline reference, not a full-screen takeover. Earlier versions of this
  # script cleared the screen and rendered the whole page via glow, but
  # that wiped the tutor's question mid-conversation and made the recording
  # feel jarring. Now we just print a GitHub wiki URL beneath the tutor's
  # turn — the page content was already quoted inline by the tutor, so the
  # URL is a pointer for "more if you want it" rather than a takeover.
  # Hardcoded 1s pause so the audience can register the URL; tune via
  # WIKI_URL_PAUSE if needed.
  local page="$1"
  local url="${WIKI_URL_BASE:-https://github.com/chrissweet/microelectronics-tutor-demo/wiki}/$page"
  printf "${C_DIM}    → %s${C_RESET}\n" "$url"
  sleep "${WIKI_URL_PAUSE:-1}"
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
