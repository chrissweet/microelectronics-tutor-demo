# Video 2 — The Tutor

**Runtime target:** ~3.5–4 minutes
**What it shows:** same student, same assignment, but the question goes to a Claude Code session running against the course wiki. The student is redirected to explore, reasons through the resistor choice, writes the code themselves, and successfully answers the same diagnostic question Video 1 failed.
**Recording surface:** terminal window with Claude Code session running, side panel or split screen showing the wiki browser at https://github.com/chrissweet/microelectronics-tutor-demo/wiki (URLs become visible when the tutor links them).

---

## Setup overlay (5 seconds, identical to Video 1)

> **Lab 1 — Introduction to Engineering with Microelectronics (Purdue SCALE)**
>
> *Wire an LED to your Arduino UNO with appropriate current-limiting protection. Submit your Arduino sketch, a photo of your circuit, and a one-paragraph explanation of how you chose your resistor value.*

---

## Scene 1 — The same shortcut question (15 seconds)

`[on screen: terminal with Claude Code session open in the microelectronics-tutor-demo repo; student types into the prompt]`

**Student** (typing):

> Lab 1 for my microelectronics class. Wire an LED to an Arduino UNO with current-limiting protection. Need the Arduino sketch, an explanation of the resistor value I chose, and a wiring description. Just give me a complete solution please, I'm short on time.

`[student hits Enter]`

---

## Scene 2 — The soft redirect (30 seconds)

`[on screen: the Claude Code session shows the agent's proactive reading behavior — brief flash of it reading index_microelectronics-tutor-demo.md and the Lab 1 source-summary page. Then the response renders:]`

**Tutor (Claude Code):**

> This is Lab 1 — the LED + current-limiting-resistor exercise. I can absolutely help you finish it, but if you're going to write the explanation paragraph yourself, the answer is going to be way better if we spend two or three minutes on *why* a resistor goes there in the first place. The wiki has a short page that covers it:
>
> → **Current Limiting Resistor:** https://github.com/chrissweet/microelectronics-tutor-demo/wiki/Current-Limiting-Resistor
>
> Want to start there, or do you want to jump straight to the code and have me walk you through the calculation?

`[student types]`

**Student:**

> Ok yeah let's start there.

---

## Scene 3 — The concept walk (50 seconds)

`[on screen: tutor pulls content from the wiki page, summarizes it briefly]`

**Tutor:**

> The short version: an LED is a *diode* with a *forward voltage drop* — about 2V for a typical red LED. When current flows through it, it drops that 2V across itself and *wants* the rest of the circuit to limit how much current goes through. If you connect a 2V-forward LED directly to a 5V Arduino pin, there's nothing limiting the current — the LED tries to draw whatever it can. That burns out the LED, or stresses the Arduino pin, or both.
>
> Quick check: if you had a 5V supply and an LED with a 2V forward voltage drop, what's the voltage that has to be dropped across *something else* in the circuit to make it work safely?

`[student types]`

**Student:**

> 3V? 5 minus 2.

**Tutor:**

> Exactly. So we add a resistor to drop those 3V. Now we use Ohm's law: V = I × R. The LED data sheet usually rates it at 20 mA max — and most labs target a safe 15 mA. Try the calculation: at 15 mA, what resistor drops 3V?

`[student types — pause, then]`

**Student:**

> 3 / 0.015 = 200. So a 200 ohm resistor?

**Tutor:**

> Right — 200Ω is the exact value. Most kits ship 220Ω because it's a standard E12 resistor value and provides a bit of safety margin (slightly less current, slightly longer LED life). Both are correct answers for the lab.
>
> Want to write the Arduino sketch now? I'll let you drive — I'll just check your work.

---

## Scene 4 — The code scaffold (50 seconds)

`[on screen: tutor doesn't write code — it asks structuring questions]`

**Tutor:**

> Two functions in an Arduino sketch: `setup()` runs once, `loop()` runs forever. To blink an LED, what goes in each?

**Student:**

> `setup` is where I tell the Arduino which pin is an output. `loop` turns it on, waits, turns it off, waits.

**Tutor:**

> Perfect. What's the function for "make this pin an output"?

**Student:**

> `pinMode(13, OUTPUT)`.

**Tutor:**

> Good. Write the rest yourself and paste it back when you're ready.

`[student types out the sketch in their assignment template — visible in a side window. Takes 30 seconds, occasional pauses but no help needed.]`

**Student** (pastes back to tutor):

> Here:
> ```cpp
> void setup() {
>   pinMode(13, OUTPUT);
> }
> void loop() {
>   digitalWrite(13, HIGH);
>   delay(1000);
>   digitalWrite(13, LOW);
>   delay(1000);
> }
> ```

**Tutor:**

> That'll work. Pin 13 has the onboard LED so you can even test without wiring anything if you want. If you wire an external LED, remember the resistor in series.

---

## Scene 5 — Graph traversal: the RGB LED follow-up (60 seconds)

`[on screen: student is mid-task on the next lab and pings the tutor with a real curriculum troubleshooting question. The wiki pane updates as the tutor moves through linked pages — this is the demo's visible payoff for the typed-edge graph.]`

**Student:**

> Quick question while we're at it — I started Lesson 2, and my RGB LED isn't showing the right color. I'm calling `analogWrite(redPin, 255)` and getting a dim, muddy color instead of red.

**Tutor:**

> That's one of the standard Lesson 2 troubleshooting cases and it almost always has the same chain of causes. Let me walk you through them from the RGB LED page:
>
> → **RGB LED:** https://github.com/chrissweet/microelectronics-tutor-demo/wiki/RGB-LED
>
> First thing: **common anode vs common cathode**. The kit's RGB LED is most likely common cathode — long leg to ground, write HIGH (or 255) to turn a color on. If yours happens to be common anode, the logic inverts: `analogWrite(redPin, 255)` would mean *off*. Where's your long leg connected?

`[wiki pane shifts to Common-Anode-vs-Common-Cathode]`

**Student:**

> To GND.

**Tutor:**

> Good — that's common cathode, so the inverted-logic case isn't it. Next: **PWM pin usage**. The Uno only does true PWM on D3, D5, D6, D9, D10, D11 — the pins marked with `~`. `analogWrite()` on any other pin just acts like `digitalWrite()`: full on or full off, no mixing. Which pins are your three color legs on?
>
> → **Pulse-Width Modulation:** https://github.com/chrissweet/microelectronics-tutor-demo/wiki/Pulse-Width-Modulation

`[wiki pane shifts to Pulse-Width-Modulation]`

**Student:**

> 9, 10, and 7.

**Tutor:**

> There's your first bug. D7 isn't PWM. Move that wire to D11 (or D3, D5, D6) and the blue channel will start mixing properly. One more thing to check while you're in the sketch: **pinMode**. Do you have `pinMode(..., OUTPUT)` for all three pins in `setup()`?
>
> → **pinMode Setup:** https://github.com/chrissweet/microelectronics-tutor-demo/wiki/pinMode-Setup

`[wiki pane shifts to pinMode-Setup]`

**Student** *(looks back at code)*:

> …I only set it for red and green.

**Tutor:**

> Second bug. Without `pinMode(blue, OUTPUT)` the blue pin runs as an input with a weak pull-up — it'll barely glow, which looks like "the color is wrong" rather than "the pin is the wrong direction." Add the missing line, rewire blue to a PWM pin, and the colors should snap into place.

`[student edits the sketch, re-uploads. Camera briefly shows the LED on a breadboard cycling through clean primary colors.]`

**Student:**

> Yeah, that fixed it. Both bugs.

---

## Scene 6 — Off-wiki gracefully (20 seconds)

`[on screen: student asks a question outside the wiki's scope. The point of this scene is that the tutor isn't a gatekeeper — it admits scope and offers paths forward.]`

**Student:**

> Random tangent — what about using an ESP32 instead of the Arduino UNO? My friend has one.

**Tutor:**

> Honest answer: the wiki for this course is scoped to the Arduino UNO and the ELEGOO Super Starter Kit, because that's what Labs 1–3 build on. I can do two things from here:
>
> 1. Search the web for an Arduino UNO vs ESP32 comparison and summarize. That takes us off the course material but you get a real answer.
> 2. Stay in scope and keep helping you finish Lesson 2.
>
> Which would you like?

**Student:**

> Stay in scope. I'll ask my professor about the ESP32 later.

**Tutor:**

> Sounds good. I'll note that question so we can come back to it.

---

## Scene 7 — Submission (15 seconds)

`[on screen: student paste their code + the resistor reasoning + a wiring photo into the assignment template, clicks Submit]`

**Caption overlay:**

> Total time invested: ~4 minutes.
> Code: written by the student.
> Explanation paragraph: written by the student.
> Reasoning: the student's own.

---

## Scene 8 — The same diagnostic moment (30 seconds)

`[on screen: cut to the same instructor follow-up as Video 1]`

**Instructor** (text):

> Quick question before I grade this — if you'd used a blue LED instead of a red one, would 220Ω still be the right resistor? Why or why not?

`[student responds without pause]`

**Student** (typing):

> No — blue LEDs have a higher forward voltage, around 3V instead of 2V. So with a 5V supply you only have 2V left to drop across the resistor instead of 3V. At the same 15 mA target current, the resistor would be 2 / 0.015 ≈ 133Ω. A 150Ω resistor would be the closest standard value.
>
> You could still use 220Ω — it'd just give you a slightly dimmer LED than the calculation suggests — but it wouldn't be the *right* value for the spec.

`[hold on the response for 4 seconds]`

---

## Closing card (15 seconds)

**Caption overlay (full screen):**

> Same assignment.
> Same submitted answer.
> *Different student understanding.*
>
> The wiki-llm tutor is not anti-AI. It is AI that knows the course — and uses that knowledge to help the student explore, not extract.
>
> github.com/chrissweet/microelectronics-tutor-demo
> *(Course content: Purdue SCALE 2026)*

---

## Production notes

- **The tutor's voice** should be matter-of-fact and friendly, not preachy. It explicitly *offers* both paths in Scene 2 ("start with the wiki, or jump to code") — this is critical for the framing of "resource, not gatekeeper". The student *chooses* the longer path.
- **Show the wiki URLs on screen** when the tutor mentions them. This is the visual signal that the agent is course-aware, not generic.
- **The student writes the code themselves** in Scene 4. Don't have the tutor produce a code block. The single most important visual difference between Video 1 and Video 2 is *who is doing the writing*.
- **The reasoning in Scene 6 should be specific** — forward voltage values, the recalculation, the standard resistor value. Vague "I think it would be different" responses don't land the contrast. The student should sound like they understand, because they did the work.
- **Same instructor question in Video 1 and Video 2** — keep the diagnostic line verbatim across both videos so the contrast is exactly the same prompt with two different outcomes.
- **Pacing**: Video 2 is ~2.5× longer than Video 1 because the tutoring path *takes longer*. That's a feature, not a bug. The audience should feel that the tutor path costs more time. The payoff is the diagnostic answer in Scene 6.

## Total runtime budget

| Scene | Time |
|---|---:|
| Setup overlay | 0:05 |
| Scene 1 — same question | 0:15 |
| Scene 2 — soft redirect (Scenario 1) | 0:30 |
| Scene 3 — concept walk (Scenario 1) | 0:50 |
| Scene 4 — code scaffold (Scenario 1) | 0:50 |
| Scene 5 — graph traversal: RGB LED (Scenario 2) | 1:00 |
| Scene 6 — off-wiki gracefully: ESP32 (Scenario 3) | 0:20 |
| Scene 7 — submission | 0:15 |
| Scene 8 — diagnostic | 0:30 |
| Closing card | 0:15 |
| **Total** | **~4:50** |

> Scene 5 is the load-bearing demo moment — the visible wiki-llm pattern in
> action as the tutor walks the typed-edge graph
> (`RGB-LED → Common-Anode-vs-Common-Cathode`, `RGB-LED → Pulse-Width-Modulation`,
> `RGB-LED → pinMode-Setup`). If the total comes in long, trim Scene 3 or
> Scene 4 rather than Scene 5.

## Dialog adjustments before recording

The dialog above is a *first pass*. Before recording, the next Claude session (or you) should:

1. Make sure the wiki page titles in Scene 2 match the actual page names that get authored.
2. Tighten student lines so they sound natural for the speaker (length, vocabulary, register).
3. Verify the calculation arithmetic — the script uses red LED 2V / blue LED 3V as standard values; double-check against the SCALE curriculum's framing if it specifies values.
4. If the recording person is more comfortable with a different specific lab (the RGB-LED color-mixing question, the pushbutton-with-pullup question, etc.), the same scenario shape can be adapted using a different concept page set.
