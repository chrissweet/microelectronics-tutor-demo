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

## Scene 5 — Submission (15 seconds)

`[on screen: student paste their code + the resistor reasoning + a wiring photo into the assignment template, clicks Submit]`

**Caption overlay:**

> Total time invested: ~4 minutes.
> Code: written by the student.
> Explanation paragraph: written by the student.
> Reasoning: the student's own.

---

## Scene 6 — The same diagnostic moment (30 seconds)

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
| Scene 2 — soft redirect | 0:30 |
| Scene 3 — concept walk | 0:50 |
| Scene 4 — code scaffold | 0:50 |
| Scene 5 — submission | 0:15 |
| Scene 6 — diagnostic | 0:30 |
| Closing card | 0:15 |
| **Total** | **~3:30** |

## Dialog adjustments before recording

The dialog above is a *first pass*. Before recording, the next Claude session (or you) should:

1. Make sure the wiki page titles in Scene 2 match the actual page names that get authored.
2. Tighten student lines so they sound natural for the speaker (length, vocabulary, register).
3. Verify the calculation arithmetic — the script uses red LED 2V / blue LED 3V as standard values; double-check against the SCALE curriculum's framing if it specifies values.
4. If the recording person is more comfortable with a different specific lab (the RGB-LED color-mixing question, the pushbutton-with-pullup question, etc.), the same scenario shape can be adapted using a different concept page set.
