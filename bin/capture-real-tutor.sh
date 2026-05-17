#!/usr/bin/env bash
# capture-real-tutor.sh — drive a real `claude -p` multi-turn session as the
# course tutor and emit a play-dialog.sh dialog file ready for VHS rendering.
#
# The student turns mirror docs/demo/scenarios/video2.dialog so the "real" and
# "scripted" videos compare directly. Tutor responses come from a live Sonnet
# session reading the course wiki — they will vary on each run.
#
# Usage:
#   bin/capture-real-tutor.sh                 # writes docs/demo/scenarios/video2-real.dialog
#   OUTPUT=/tmp/test.dialog bin/capture-real-tutor.sh

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

OUTPUT="${OUTPUT:-docs/demo/scenarios/video2-real.dialog}"
SESSION_ID="${SESSION_ID:-$(uuidgen | tr 'A-F' 'a-f')}"
MODEL="${MODEL:-sonnet}"

echo "capture-real-tutor: session=$SESSION_ID model=$MODEL → $OUTPUT" >&2

SYSTEM_PROMPT=$(cat <<'EOF'
You are a course-aware microelectronics tutor for an undergraduate working on Lab 1 of the Purdue SCALE "Introduction to Engineering with Microelectronics" curriculum.

The course wiki lives at wiki/microelectronics-tutor-demo.wiki/. Start at index_microelectronics-tutor-demo.md. Read the wiki proactively whenever a student question maps to a concept page (LED-Basics, Current-Limiting-Resistor, Forward-Voltage, RGB-LED, Common-Anode-vs-Common-Cathode, Pulse-Width-Modulation, pinMode-Setup, Pushbutton-Switch, Floating-Input-and-Pull-Up-Resistors, analogWrite-for-PWM, digitalRead-with-Pullup, Arduino-Sketch-Structure, Blink-Pattern, Serial-Monitor-Debugging, etc.).

PEDAGOGY — read this carefully, it is the most important section:

Open every new topic with the conceptual gap, not with value recall. For an Ohm's law / LED question, your first probe must be conceptual — "why does the LED need a resistor at all?", "what happens if you connect the LED directly to 5 V?", "what's special about an LED compared to a normal resistor?". DO NOT open by asking the student to recite the supply voltage or any other number — that's fact retrieval, not reasoning, and the student probably already knows it from the board silkscreen. Save value recall and calculations for AFTER the conceptual gap is closed and the student can articulate why the resistor exists.

For diagnostic questions ("my X isn't working"), walk the typed-edge graph one concept at a time, naming each page you consult.

Honest about scope: if the student asks about hardware outside the wiki (ESP32, Raspberry Pi, other boards), say the wiki is scoped to Arduino UNO + ELEGOO Super Starter Kit, and offer either a web search or staying in scope.

FORMAT:
- Keep each response under 180 words.
- Plain text only. No markdown. No double asterisks for bold. No backticks for code or values. No bulleted lists with leading dashes or asterisks. Numbers and variable names stand on their own — write 220 ohms, not **220 Ω** or `220Ω`. Write analogWrite, not `analogWrite()`. The response renders in a plain terminal recording; any markdown characters render as literal punctuation and look ugly.

WIKI PAGE MARKERS — this is also load-bearing:

Every time you reference a wiki page OR rely on its content in your reasoning, emit a marker on its own line at the very end of your response:
[[show: Page-Name]]

Multiple pages = multiple marker lines. Err strongly on the side of marking too often rather than too rarely — the audience of this demo cannot see your reasoning, they can only see the page that flashes on screen, so EVERY response that touches a wiki concept should end with at least one [[show: ...]] marker. If you mention Ohm's law sizing → [[show: Current-Limiting-Resistor]]. If you mention forward voltage → [[show: Forward-Voltage]]. If you mention PWM pins → [[show: Pulse-Width-Modulation]]. If you diagnose common-anode/cathode → [[show: Common-Anode-vs-Common-Cathode]]. Markers are stripped before display.
EOF
)

# Student turns — order matches docs/demo/scenarios/video2.dialog so the
# two videos compare cleanly. Edit here, re-run the script to recapture.
declare -a TURNS=(
  "Lab 1 for my microelectronics class. Wire an LED to an Arduino UNO with current-limiting protection. Need the Arduino sketch, an explanation of the resistor value I chose, and a wiring description. Just give me a complete solution please, I'm short on time."
  "Ok yeah let's start there."
  "3 V? 5 minus 2."
  "3 divided by 0.015 = 200. So 200 ohms."
  "Yeah, I think I've got it. setup is where I tell the Arduino the pin is an output. loop turns it on, waits, turns it off, waits. Here's what I wrote: void setup() { pinMode(13, OUTPUT); } void loop() { digitalWrite(13, HIGH); delay(1000); digitalWrite(13, LOW); delay(1000); }"
  "Quick question while we're here. I started Lesson 2 and my RGB LED isn't showing the right color. I'm calling analogWrite(redPin, 255) and getting a dim, muddy color instead of red."
  "The long leg is connected to GND."
  "The three color legs are on pins 9, 10, and 7."
  "Looking at my sketch — I only have pinMode set for red and green, not blue."
  "Yeah, that fixed it. Both bugs — moving blue to D11 and adding the pinMode line."
  "Random tangent — what about using an ESP32 instead of the Arduino UNO? My friend has one and says it's better."
  "Let's stay in scope. I'll ask my professor about the ESP32 later."
)

# ─── Helpers ────────────────────────────────────────────────────────────────

call_claude() {
  local prompt="$1" first="$2"
  local args=(
    -p "$prompt"
    --output-format json
    --model "$MODEL"
    --allowedTools "Read" "Glob" "Grep"
    --dangerously-skip-permissions
  )
  if [[ "$first" == "1" ]]; then
    args+=(--session-id "$SESSION_ID" --append-system-prompt "$SYSTEM_PROMPT")
  else
    args+=(--resume "$SESSION_ID")
  fi
  claude "${args[@]}"
}

extract_response() {
  jq -r '.result'
}

# Pull [[show: PAGE]] markers out, return one per line
extract_pages() {
  grep -oE '\[\[show:[[:space:]]*[A-Za-z0-9_-]+\]\]' \
    | sed -E 's/\[\[show:[[:space:]]*([A-Za-z0-9_-]+)\]\]/\1/' \
    || true
}

strip_markers() {
  # 1. drop [[show: PAGE]] tokens
  # 2. drop **bold** and `code` markdown wrappers — they render as literal
  #    asterisks/backticks in the terminal and add visual noise
  # 3. collapse blank lines
  # 4. join lines into a single line with literal `\n` separators that
  #    play-dialog.sh expands back to newlines at display time
  sed -E 's/\[\[show:[[:space:]]*[A-Za-z0-9_-]+\]\]//g' \
    | sed -E 's/\*\*([^*]+)\*\*/\1/g' \
    | sed -E 's/`([^`]+)`/\1/g' \
    | sed -E '/^[[:space:]]*$/d' \
    | awk '{printf "%s\\n", $0}' \
    | sed 's/\\n$//'
}

# ─── Header (static) ────────────────────────────────────────────────────────

cat > "$OUTPUT" <<EOF
; Video 2 (REAL) — captured live Claude tutor session, $(date +%Y-%m-%d).
; Model: $MODEL — session ID: $SESSION_ID
; Generated by bin/capture-real-tutor.sh — re-run to recapture (responses vary).
; Compare against docs/demo/scenarios/video2.dialog (scripted version).

>system|── Lab 1: Introduction to Engineering with Microelectronics — Purdue SCALE ──
>system|
>system|Assignment: Wire an LED to your Arduino UNO with current-limiting protection.
>system|Submit your sketch, a photo of your circuit, and a paragraph on your resistor choice.
>pause|2.5

>clear
>system|── live claude code session, course wiki indexed ──
>pause|1

EOF

# ─── Capture loop ───────────────────────────────────────────────────────────

for i in "${!TURNS[@]}"; do
  turn="${TURNS[$i]}"
  n=$((i + 1))
  echo "[$n/${#TURNS[@]}] student: ${turn:0:80}..." >&2

  if [[ $i -eq 0 ]]; then
    response_json=$(call_claude "$turn" 1)
  else
    response_json=$(call_claude "$turn" 0)
  fi

  response=$(printf '%s' "$response_json" | extract_response)
  pages=$(printf '%s\n' "$response" | extract_pages)
  cleaned=$(printf '%s\n' "$response" | strip_markers)

  page_count=$(printf '%s' "$pages" | grep -c . || true)
  echo "[$n/${#TURNS[@]}] tutor ($(printf '%s' "$response" | wc -c | tr -d ' ') chars, $page_count wiki pages)" >&2

  {
    echo ""
    echo ">student|$turn"
    echo ">pause|1"
    echo ""
    echo ">tutor|$cleaned"
    echo ">pause|2"
    if [[ -n "$pages" ]]; then
      while IFS= read -r page; do
        [[ -z "$page" ]] && continue
        echo ">wiki|$page"
      done <<< "$pages"
    fi
  } >> "$OUTPUT"
done

# ─── Closing (static, mirrors video2.dialog) ────────────────────────────────

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

echo "wrote $OUTPUT" >&2
echo "preview with: docs/demo/scenarios/lib/play-dialog.sh $OUTPUT" >&2
echo "render with:  vhs docs/demo/scenarios/video2-real.tape" >&2
