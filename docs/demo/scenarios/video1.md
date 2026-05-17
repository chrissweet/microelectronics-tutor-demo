# Video 1 — The Shortcut

**Runtime target:** ~90 seconds
**What it shows:** student outsources the assignment to a generic LLM, submits, demonstrably does not understand the underlying concept.
**Recording surface:** browser window with Claude.ai or ChatGPT, side-panel with the assignment text visible. No course context, no wiki.

---

## Setup overlay (5 seconds, before the dialog begins)

> **Lab 1 — Introduction to Engineering with Microelectronics (Purdue SCALE)**
>
> *Wire an LED to your Arduino UNO with appropriate current-limiting protection. Submit your Arduino sketch, a photo of your circuit, and a one-paragraph explanation of how you chose your resistor value.*

---

## Scene 1 — The shortcut question (15 seconds)

`[on screen: student opens a new chat tab in Claude.ai or ChatGPT, no system prompt, no project context]`

**Student** (typing):

> Lab 1 for my microelectronics class. Wire an LED to an Arduino UNO with current-limiting protection. Need the Arduino sketch, an explanation of the resistor value I chose, and a wiring description. Just give me a complete solution please, I'm short on time.

`[student hits Send]`

---

## Scene 2 — The generic LLM response (40 seconds)

`[on screen: the LLM's response renders. Audio: light scrolling, no commentary]`

**Generic LLM** (response paraphrase — shown on screen, narrated quickly or shown in time-lapse):

> Here is a complete solution for Lab 1:
>
> **Arduino sketch:**
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
>
> **Wiring:** Connect an LED's long leg (anode) through a 220Ω resistor to pin 13. Connect the short leg (cathode) to GND.
>
> **Resistor choice:** Using Ohm's law (V = IR), with the LED's forward voltage of ~2V and a target current of ~15 mA, R = (5 − 2) / 0.015 ≈ 200Ω. A 220Ω resistor is a safe, common choice.

`[student selects all, copies, switches to a Google Doc or assignment template, pastes. Total elapsed: maybe 90 seconds since the question was sent.]`

---

## Scene 3 — Submission (10 seconds)

`[on screen: student pastes the LLM response into an assignment-submission template, clicks Submit]`

**Caption overlay:**

> Total time invested: 2 minutes. Code, wiring, explanation — all submitted.

---

## Scene 4 — The diagnostic moment (20 seconds)

`[on screen: cut to a chat or email, instructor follows up]`

**Instructor** (text):

> Quick question before I grade this — if you'd used a blue LED instead of a red one, would 220Ω still be the right resistor? Why or why not?

`[student hesitates — visible pause of ~3 seconds — then types]`

**Student** (typing — choose ONE of these to land the failure-to-understand point; record whichever feels most natural):

> *Option A (vague answer):* "Yes I think so, it's the standard value. Ohm's law works the same way."
>
> *Option B (deflection):* "Hm, I'd have to check. It should be similar I think."
>
> *Option C (admission):* "Honestly I'm not sure — Claude said 220 was fine."

`[hold on the message for 3-4 seconds]`

---

## Closing card (10 seconds)

**Caption overlay (full screen):**

> Assignment: submitted.
> Resistor calculation: correct.
> Understanding of *why*: absent.
>
> Same assignment, with the wiki-llm tutor →

---

## Production notes

- **Voice:** no narration over Scene 2 (the LLM's response). Let the visual speak. Optionally light typing sounds, no commentary.
- **Pacing:** Scene 1 quick (the rush implied by *"short on time"* is part of the point), Scene 2 time-lapsed or scrolled fast, Scene 3 brief, Scene 4 deliberate — the diagnostic question is the demo's payoff and should breathe.
- **Don't villainize the student.** The framing is *"the cheating path is easy and tempting, and the harm is invisible until the diagnostic moment."* Sympathetic, not judgmental.
- **Don't villainize Claude/ChatGPT.** The generic LLM did a fine technical job. The problem is the use case (assignment outsourcing), not the tool.
- **The diagnostic question** is the same in both videos so the contrast is direct.
- **Branded LLM matters:** if recording with Claude.ai specifically, the audience sees that the contrast in Video 2 is *another Claude session, just with course context*. That's the point — same underlying model, different surrounding architecture. If using ChatGPT in Video 1, the point still lands but is less sharp.

## Total runtime budget

| Scene | Time |
|---|---:|
| Setup overlay | 0:05 |
| Scene 1 — question | 0:15 |
| Scene 2 — generic response | 0:40 |
| Scene 3 — submission | 0:10 |
| Scene 4 — diagnostic | 0:20 |
| Closing card | 0:10 |
| **Total** | **~1:40** |
