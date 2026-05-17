# Conference demo plan — AI tutor for microelectronics

**Audience:** Conference talk, Tuesday 2026-05-19.
**Goal:** Demonstrate the wiki-llm pattern applied to undergraduate microelectronics education, framed as a side-by-side contrast between the "ask AI to do my homework" path and the "ask AI to help me understand" path.

## The framing the audience sees

Two videos, same student, same Lab 1 assignment from the Purdue SCALE *Introduction to Engineering with Microelectronics* module. The contrast is the *outcome on a diagnostic follow-up question* — the cheat-path student can't answer it, the tutor-path student can.

**Video 1 — The Shortcut (~90 seconds):** student opens generic Claude or ChatGPT in a browser, pastes the assignment, gets a complete solution, submits, then is asked a diagnostic question and can't reason through it.

**Video 2 — The Tutor (~3-4 minutes):** same student, same starting question, but directed to a Claude Code session running against the course wiki. Agent soft-redirects, scaffolds through the wiki pages, asks a Socratic question, the student reasons through to their own answer, and successfully fields the diagnostic.

**Closing slide:** *same assignment, same submitted answer, different understanding. The wiki-llm tutor isn't anti-AI — it's AI that knows the course.*

## Source material

The four PDFs in `docs/curriculum/` are the seed corpus, courtesy of the Purdue SCALE program:

- `Scale_Currriculum_Plan_2026_rev_a.pdf` — the curriculum plan (5 sessions, 3 named lessons, learning objectives, KSAs, grading rubric, **instructor troubleshooting Q&A**)
- `Arduino_Lab__Student_Copy-_Purdue_SCALE_Project._M_Riley.pdf` — student lab manual
- `Purdue_SCALE_Lab_Form_Instructor.pdf` — instructor lab form
- `ELEGOO_UNO_Packaging_List_002.pdf` — hardware kit reference (Arduino UNO R3 + Elegoo Super Starter Kit)

The **single most useful asset** is the troubleshooting Q&A inside `Scale_Currriculum_Plan_2026_rev_a.pdf`. It contains real student questions with expert answers — e.g., "Why do I need a resistor on the RGB LED?" → "Overcurrent protection; different colors have different forward voltages." These are essentially pre-written demo dialogs.

## Wiki concept pages to author (~15 pages, three clusters)

Pull terminology and content from the curriculum PDFs. Each page should have proper frontmatter (`type`, `up`, typed edges like `extends:` / `requires:` / `prerequisite:` etc. when relationships are clear).

**Components cluster** — concrete parts students wire on the breadboard:
- `Arduino-Uno-Board`
- `Breadboard-Wiring`
- `LED-Basics`
- `RGB-LED`
- `Current-Limiting-Resistor`
- `Pushbutton-Switch`
- `Active-Buzzer`
- `Passive-Buzzer`
- `Servo-Motor`
- `Photoresistor`

**Concepts cluster** — the electrical / circuit ideas underneath:
- `Digital-vs-Analog`
- `Pulse-Width-Modulation`
- `Common-Anode-vs-Common-Cathode`
- `Forward-Voltage`
- `Floating-Input-and-Pull-Up-Resistors`
- `pinMode-Setup`

**Code patterns cluster** — Arduino sketch idioms:
- `Arduino-Sketch-Structure` (setup / loop)
- `Blink-Pattern`
- `analogWrite-for-PWM`
- `digitalRead-with-Pullup`
- `Serial-Monitor-Debugging`

### Typed-edge map between pages (so the agent's graph traversal works)

Critical edges that make the demo scenarios land:

- `LED-Basics` --requires--> `Current-Limiting-Resistor` --explains--> `Forward-Voltage`
- `RGB-LED` --extends--> `LED-Basics`
- `RGB-LED` --uses--> `Pulse-Width-Modulation`
- `RGB-LED` --requires--> `Common-Anode-vs-Common-Cathode`
- `Pushbutton-Switch` --requires--> `Floating-Input-and-Pull-Up-Resistors`
- `analogWrite-for-PWM` --implements--> `Pulse-Width-Modulation`
- `digitalRead-with-Pullup` --implements--> `Floating-Input-and-Pull-Up-Resistors`

## Demo scenarios (write full dialogs in `docs/demo/scenarios/`)

### Scenario 1 — Resource discovery (Video 1 baseline + Video 2 opening)

**Student question:** *"Why is it important to put a resistor in series with an LED?"*  
(This is verbatim from the curriculum's Lab 1 assessment questions.)

- *Video 1 path*: generic Claude/ChatGPT returns a textbook paragraph about Ohm's law and forward voltage. Student copies, submits, doesn't engage.
- *Video 2 path*: wiki-llm tutor retrieves `LED-Basics`, `Current-Limiting-Resistor`, `Forward-Voltage`. Offers them with a Socratic invitation. Student engages.

### Scenario 2 — Graph traversal (the typed-edge moment)

**Student question:** *"My RGB LED isn't showing the right color."*

This question spans multiple concepts and is a real curriculum troubleshooting Q&A. The tutor walks through:

1. `RGB-LED` page (retrieved)
2. Diagnostic: "common anode vs common cathode? Let me show you" → traverses to `Common-Anode-vs-Common-Cathode`
3. "Are you using PWM-capable pins?" → traverses to `Pulse-Width-Modulation` via `analogWrite-for-PWM`
4. "Did you set pinMode to OUTPUT?" → traverses to `pinMode-Setup`

The agent's navigation through the typed-edge graph is the visible *demonstration* of the wiki-llm pattern.

### Scenario 3 — Graceful off-wiki fallback (Video 2 close)

**Student question:** *"What about ESP32 boards instead of Arduino UNO?"*

The wiki is scoped to Arduino UNO + Elegoo kit. Tutor: *"I don't have ESP32 in the course wiki — want me to search the web? Or stay in scope?"* Lands the "open, not gatekeeping" property.

### The diagnostic question (lands in both videos)

**Question:** *"If you'd used a blue LED instead of a red one, would 220Ω still be the right resistor? Why or why not?"*

- *Video 1 student*: hesitates, says something vague.
- *Video 2 student*: explains that blue LEDs have higher forward voltage (~3V vs ~2V for red), so the current calculation changes — likely needs a smaller resistor.

This is the demo's payoff moment.

## Production plan

1. **Author the ~15 wiki concept pages** by ingesting the four curriculum PDFs via `/wiki-source` + manual authoring where the typed edges need refining. Pages live in `wiki/microelectronics-tutor-demo.wiki/`. Properly cross-reference, update `index_microelectronics-tutor-demo.md`, append a log entry.
2. **Write the two video scripts** in `docs/demo/scenarios/video1.md` and `docs/demo/scenarios/video2.md` with full dialog (student lines, agent lines, expected timing).
3. **Dry run Scenario 2** in a Claude Code session against the wiki to confirm the agent's proactive behavior surfaces the right pages in the right order.
4. **Record both videos** (macOS Cmd+Shift+5 screen recording; for the tutor session, terminal + wiki page open in browser).
5. **Stitch + slide deck** with framing slide + closing slide.

## Acknowledgement to include in the demo

> Curriculum content adapted from the Purdue SCALE program's *Introduction to Engineering with Microelectronics* module (M. Riley et al., 2026 revision a).

## What this demo does NOT try to do

- It is **not** an anti-cheat tool. No detection, no enforcement.
- It does **not** refuse to help. The agent always offers a constructive path.
- It does **not** integrate with an LMS. Standalone tool, runs alongside the course.
- It does **not** track student progress for grading. Per-student memory is opt-in and stays local.

The pitch is: *AI that knows the course, makes exploring the course material the easy path.*

## Where you (this Claude session) come in

Your job, in priority order:

1. Ingest the four curriculum PDFs into the wiki as source-summary pages via the proactive read+write behavior (or explicit `/wiki-source` if it doesn't trigger).
2. Author the 15 concept pages with proper frontmatter and typed edges per the cluster + edge map above.
3. Update `index_microelectronics-tutor-demo.md` and append a log entry.
4. Write the two video scripts in `docs/demo/scenarios/`.
5. Dry-run Scenario 2 to verify the agent's behavior.
6. **Commit and push** at each natural milestone (per the wiki-as-memory rule).

The wiki is the demo. Spend most time on quality wiki content + tight video scripts. The infrastructure is already in place — don't reinvent.
