#!/usr/bin/env bash
# capture-two-agent-tutor.sh — drive a real, two-agent Claude conversation.
#
# Both sides are live `claude -p` sessions:
#   - TUTOR: reads the course wiki via Read/Glob/Grep; tightened Socratic prompt
#   - STUDENT: a persona-driven undergrad who just tried to outsource Lab 1;
#              no tool access; gets the tutor's last message + occasional
#              [meta: ...] stage hints at turn boundaries to pivot between
#              scenarios (Lab 1 → RGB LED → ESP32 → stay in scope).
#
# Output: docs/demo/scenarios/video2-real.dialog (overwrites)
# Cost: ~$2 (24 model calls, mostly cache-hits after turn 1)
# Wall time: ~6-10 min, depending on tool latency on tutor side
#
# Re-run for a fresh take — responses vary.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

OUTPUT="${OUTPUT:-docs/demo/scenarios/video2-real.dialog}"
TUTOR_SESSION="${TUTOR_SESSION:-$(uuidgen | tr 'A-F' 'a-f')}"
STUDENT_SESSION="${STUDENT_SESSION:-$(uuidgen | tr 'A-F' 'a-f')}"
MODEL="${MODEL:-sonnet}"
MAX_TURNS="${MAX_TURNS:-13}"

echo "two-agent capture:" >&2
echo "  tutor session:   $TUTOR_SESSION" >&2
echo "  student session: $STUDENT_SESSION" >&2
echo "  model:           $MODEL" >&2
echo "  max turns:       $MAX_TURNS" >&2
echo "  output:          $OUTPUT" >&2

# ─── Persona prompts ───────────────────────────────────────────────────────
# macOS ships bash 3.2 which mis-parses single quotes inside $(cat <<'EOF' …)
# heredocs (the apostrophes in contractions confuse the outer command sub),
# so write each prompt to a temp file via a stand-alone heredoc and load it
# at call time with $(cat …). Cleaned up on EXIT.

TUTOR_PROMPT_FILE="$(mktemp -t tutor-prompt.XXXXXX)"
STUDENT_PROMPT_FILE="$(mktemp -t student-prompt.XXXXXX)"
trap 'rm -f "$TUTOR_PROMPT_FILE" "$STUDENT_PROMPT_FILE"' EXIT

cat > "$TUTOR_PROMPT_FILE" <<'EOF'
You are a course-aware microelectronics tutor for an undergraduate working on Lab 1 of the Purdue SCALE "Introduction to Engineering with Microelectronics" curriculum.

The course wiki lives at wiki/microelectronics-tutor-demo.wiki/. Start at index_microelectronics-tutor-demo.md. Read the wiki proactively whenever a student question maps to a concept page (LED-Basics, Current-Limiting-Resistor, Forward-Voltage, RGB-LED, Common-Anode-vs-Common-Cathode, Pulse-Width-Modulation, pinMode-Setup, Pushbutton-Switch, Floating-Input-and-Pull-Up-Resistors, analogWrite-for-PWM, digitalRead-with-Pullup, Arduino-Sketch-Structure, Blink-Pattern, Serial-Monitor-Debugging).

PEDAGOGY — most important section:

Open every new topic with the conceptual gap, not with value recall. For an Ohm's law / LED question, your first probe must be conceptual: "why does the LED need a resistor at all?", "what happens if you connect the LED directly to 5 V?", "what's special about an LED compared to a normal resistor?". DO NOT open by asking the student to recite the supply voltage — that's fact retrieval, not reasoning, and the student already knows it from the board silkscreen.

Once a student answers a question, accept their answer and move forward. Don't loop on the same question — if they pivot or get sidetracked, gently follow them rather than refusing to advance. Socratic tutors lead, they don't trap.

For diagnostic questions ("my X isn't working"), walk the typed-edge graph one concept at a time, naming each page you consult.

Honest about scope: if asked about hardware outside the wiki (ESP32, Raspberry Pi, other boards), say the wiki is scoped to Arduino UNO + ELEGOO Super Starter Kit, offer either a web search or staying in scope, and follow whichever the student chooses.

FORMAT:
- Keep each response under 150 words.
- Plain text only. No markdown. No double asterisks for bold. No backticks for code or values. No bulleted lists. Write 220 ohms, not bolded. Write analogWrite, not wrapped in backticks. Markdown characters render literally in the terminal recording and look ugly.

WIKI PAGE MARKERS:

Every response that touches a wiki concept must end with at least one marker on its own line:
[[show: Page-Name]]

Err strongly on the side of marking too often — the audience only sees the wiki page that flashes on screen, so EVERY conceptual response needs at least one marker. Multiple pages = multiple marker lines.
EOF

cat > "$STUDENT_PROMPT_FILE" <<'EOF'
You are playing the student in a demonstration of an AI tutoring tool. Stay in character; this is a recorded conversation for an audience.

Background: you are an undergrad in an intro microelectronics class (Purdue SCALE). You opened this chat by trying to outsource Lab 1 — you asked for a complete LED + resistor solution and an explanation paragraph because you were short on time. The tutor pushed back and is now teaching you. You are a bit annoyed at first but you are not malicious; once you start engaging, you actually find it interesting.

Your knowledge level: you have heard of Ohm's law and can do basic algebra. You are shaky on what makes an LED different from a resistor. You do not know LED forward voltages by heart. You know an Arduino runs on 5 V because it is silkscreened on the board.

VOICE — read carefully:
- One to three short sentences per reply. You are texting, not writing essays.
- Casual register. Lowercase often. Occasional ellipsis or "uh" or "hmm" is fine. Contractions are fine in the visible text.
- Answer the tutor's specific question. If they ask "what happens if X?", actually speculate even if you are not sure. If they ask you to calculate, do the math (and feel free to be slightly wrong at first). If they ask a fact you do not know, say "I don't know" or "I'm not sure" rather than making it up.
- DO NOT roleplay-narrate ("I think for a moment" / "I scratch my head"). Just say what the student says.
- DO NOT over-perform earnestness. You are a student doing a lab, not a Hallmark protagonist.
- Plain text only — no markdown, no asterisks, no bold, no code fences.
- Do not end your turn with a follow-up question that invites a lecture. If you have a question, make it a specific one.

META INSTRUCTIONS:
The tutor's message you receive may contain text in [meta: ...] brackets at the end. THIS IS NOT FROM THE TUTOR — it is a stage direction for you, the student. Incorporate the directive naturally as your next reply (do not quote the bracket text back, do not acknowledge it exists). Examples:
- [meta: pivot to the RGB LED problem from Lesson 2] → your reply should naturally transition to mentioning your RGB LED is showing wrong colors
- [meta: ask about ESP32 as a tangent] → casually bring up "btw is ESP32 better than UNO?"
- [meta: agree to stay in scope] → say something like "ok let's stay on the lab"

When responding to a tutor message, IGNORE the part inside [meta: ...] when judging what the tutor said — that is a director note, not a real tutor question.
EOF

# ─── Stage hints ───────────────────────────────────────────────────────────
# Keyed by turn number (1-indexed). The hint is appended to the tutor's
# response before it's passed to the student session. Bash 3.2 (the macOS
# default) does not support associative arrays, so this is a case statement.

stage_hint_for_turn() {
  case "$1" in
    5)  echo "meta: at this point you've successfully worked through Lab 1 and the tutor has confirmed your solution. Your next reply should pivot — naturally bring up that you started Lesson 2 and your RGB LED isn't showing the right color. You're calling analogWrite(redPin, 255) but the color is muddy/dim instead of red. Mention it casually like a side question." ;;
    10) echo "meta: the RGB LED diagnostic chain is wrapping up. Your next reply should pivot to a tangent — casually ask whether ESP32 would be better than Arduino UNO, since your friend has one." ;;
    12) echo "meta: tutor just admitted ESP32 is outside the wiki's scope and offered options. Tell the tutor you'll stay in scope and ask your professor about ESP32 later." ;;
    *)  echo "" ;;
  esac
}

FIRST_STUDENT="Lab 1 for my microelectronics class. Wire an LED to an Arduino UNO with current-limiting protection. Need the Arduino sketch, an explanation of the resistor value I chose, and a wiring description. Just give me a complete solution please, I'm short on time."

# ─── Helpers ───────────────────────────────────────────────────────────────

call_tutor() {
  local prompt="$1" first="$2"
  local args=(
    -p "$prompt"
    --output-format json
    --model "$MODEL"
    --allowedTools "Read" "Glob" "Grep"
    --dangerously-skip-permissions
  )
  if [[ "$first" == "1" ]]; then
    args+=(--session-id "$TUTOR_SESSION" --append-system-prompt "$(cat "$TUTOR_PROMPT_FILE")")
  else
    args+=(--resume "$TUTOR_SESSION")
  fi
  claude "${args[@]}"
}

call_student() {
  local prompt="$1" first="$2"
  local args=(
    -p "$prompt"
    --output-format json
    --model "$MODEL"
    --tools ""
    --dangerously-skip-permissions
  )
  if [[ "$first" == "1" ]]; then
    args+=(--session-id "$STUDENT_SESSION" --append-system-prompt "$(cat "$STUDENT_PROMPT_FILE")")
  else
    args+=(--resume "$STUDENT_SESSION")
  fi
  claude "${args[@]}"
}

extract_result() { jq -r '.result'; }

extract_pages() {
  grep -oE '\[\[show:[[:space:]]*[A-Za-z0-9_-]+\]\]' \
    | sed -E 's/\[\[show:[[:space:]]*([A-Za-z0-9_-]+)\]\]/\1/' \
    || true
}

strip_meta() {
  # Strip [meta: ...] director notes before showing tutor text to anyone
  # other than the student session.
  sed -E 's/\[meta:[^]]*\]//g'
}

clean_for_dialog() {
  # 1. drop [[show: PAGE]] tokens
  # 2. drop **bold** and `code` markdown wrappers
  # 3. drop [meta: ...] director notes (only relevant for tutor side but
  #    cheap to apply to both)
  # 4. collapse blank lines
  # 5. join into single line with literal \n separators
  sed -E 's/\[\[show:[[:space:]]*[A-Za-z0-9_-]+\]\]//g' \
    | sed -E 's/\*\*([^*]+)\*\*/\1/g' \
    | sed -E 's/`([^`]+)`/\1/g' \
    | sed -E 's/\[meta:[^]]*\]//g' \
    | sed -E '/^[[:space:]]*$/d' \
    | awk '{printf "%s\\n", $0}' \
    | sed 's/\\n$//'
}

# ─── Header ────────────────────────────────────────────────────────────────

cat > "$OUTPUT" <<EOF
; Video 2 (REAL, two-agent) — captured live $(date +%Y-%m-%d).
; Tutor session:   $TUTOR_SESSION
; Student session: $STUDENT_SESSION
; Model: $MODEL  |  Both sides are live claude -p, with the tutor reading
; the course wiki via Read/Glob/Grep and the student running tool-less with
; a persona prompt. Stage hints inserted at turns 5, 10, 12 to pivot between
; scenarios. Generated by bin/capture-two-agent-tutor.sh.

>system|── Lab 1: Introduction to Engineering with Microelectronics — Purdue SCALE ──
>system|
>system|Assignment: Wire an LED to your Arduino UNO with current-limiting protection.
>system|Submit your sketch, a photo of your circuit, and a paragraph on your resistor choice.
>pause|2.5

>clear
>system|── live two-agent claude code session, course wiki indexed ──
>pause|1
EOF

# ─── Turn loop ─────────────────────────────────────────────────────────────

current_student_msg="$FIRST_STUDENT"

for ((i=1; i<=MAX_TURNS; i++)); do
  echo "" >&2
  echo "[turn $i/$MAX_TURNS]" >&2
  echo "  student ($(printf '%s' "$current_student_msg" | wc -c | tr -d ' ') chars): ${current_student_msg:0:90}..." >&2

  # Write student turn to dialog
  student_for_dialog=$(printf '%s\n' "$current_student_msg" | clean_for_dialog)
  {
    echo ""
    echo ">student|$student_for_dialog"
    echo ">pause|1"
  } >> "$OUTPUT"

  # Tutor responds
  if [[ $i -eq 1 ]]; then
    tutor_json=$(call_tutor "$current_student_msg" 1)
  else
    tutor_json=$(call_tutor "$current_student_msg" 0)
  fi
  tutor_raw=$(printf '%s' "$tutor_json" | extract_result)
  tutor_pages=$(printf '%s\n' "$tutor_raw" | extract_pages)
  tutor_for_dialog=$(printf '%s\n' "$tutor_raw" | clean_for_dialog)

  echo "  tutor ($(printf '%s' "$tutor_raw" | wc -c | tr -d ' ') chars, $(printf '%s' "$tutor_pages" | grep -c . || true) wiki pages)" >&2

  # Write tutor turn to dialog
  {
    echo ""
    echo ">tutor|$tutor_for_dialog"
    echo ">pause|2"
    while IFS= read -r page; do
      [[ -z "$page" ]] && continue
      echo ">wiki|$page"
    done <<< "$tutor_pages"
  } >> "$OUTPUT"

  # If this was the final turn, don't generate a student reply
  if [[ $i -eq $MAX_TURNS ]]; then
    echo "  (final turn, stopping student loop)" >&2
    break
  fi

  # Build student input — tutor text + optional stage hint
  student_input="$tutor_raw"
  hint="$(stage_hint_for_turn "$i")"
  if [[ -n "$hint" ]]; then
    student_input="$tutor_raw

[$hint]"
    echo "  >> stage hint @ turn $i" >&2
  fi

  # For the very first student turn, also prefix with what they previously said
  # so the student session has context about its own opening shortcut request.
  if [[ $i -eq 1 ]]; then
    student_input="[Earlier you sent this opening message to the tutor, trying to outsource Lab 1: \"$FIRST_STUDENT\"]

The tutor replied:

$student_input

Reply as the student — staying in character per your system prompt."
    student_json=$(call_student "$student_input" 1)
  else
    student_json=$(call_student "$student_input" 0)
  fi

  student_raw=$(printf '%s' "$student_json" | extract_result)
  # For next iteration's tutor input, flatten newlines so the message is one line
  current_student_msg=$(printf '%s' "$student_raw" | tr '\n' ' ' | sed -E 's/  +/ /g')
done

# ─── Closing scenes ────────────────────────────────────────────────────────

cat >> "$OUTPUT" <<'EOF'

>clear
>caption|Total time: about 4 minutes. Code, explanation, and reasoning — the student's.
>pause|3

>clear
>system|── instructor follow-up, same question Video 1 student fumbled ──
>pause|1
>instructor|Quick question before I grade this — if you'd used a blue LED instead of a red one, would 220 Ω still be the right resistor? Why or why not?
>pause|2

>student|Blue LEDs have a higher forward voltage — about 3 V instead of 2 V for red. So with a 5 V supply, the resistor only has to drop 2 V instead of 3 V. At the same 15 mA target, 2 / 0.015 ≈ 133 Ω, so 150 Ω is the closest standard value.\n220 Ω still works — it's safe — but it'd give a dimmer LED than the spec wants. If I needed the same brightness as the red, I'd use 150 Ω.
>pause|3

>clear
>caption|Same assignment. Same submitted answer. Different understanding.
>pause|2
>caption|The wiki-llm tutor isn't anti-AI — it's AI that knows the course.
>pause|3
EOF

echo "" >&2
echo "wrote $OUTPUT" >&2
echo "preview: docs/demo/scenarios/lib/play-dialog.sh $OUTPUT" >&2
echo "render:  vhs docs/demo/scenarios/video2-real.tape" >&2
