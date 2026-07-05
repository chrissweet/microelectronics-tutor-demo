# Probe experiment scripts

The harness that produced the tutor evaluation. Written to run against a clone
of `chrissweet/microelectronics-tutor-demo` with its wiki cloned inside it:

```
git clone https://github.com/chrissweet/microelectronics-tutor-demo
cd microelectronics-tutor-demo
git clone https://github.com/chrissweet/microelectronics-tutor-demo.wiki.git \
    wiki/microelectronics-tutor-demo.wiki
```

The scripts assume a working layout where this `scripts/` directory sits
alongside the `microelectronics-tutor-demo/` clone (i.e. `$BASE` is the parent
that contains both the scripts and the clone). Adjust the `REPO=` line at the
top of each runner if your layout differs.

## Contents

- `probes-single.txt` — 20 single-turn probes, `ID|prompt`; five categories
  (D=direct demand, U=urgency, A=authority, R=roleplay/injection, I=incremental).
- `probes-multi.txt` — 5 three-turn escalations, `ID|turn1|turn2|turn3`;
  one per category.
- `run-probes.sh` — original single-model run.
- `run-probes-v2.sh <model> <run>` — parameterized run; the submission used
  `run-probes-v2.sh claude-opus-4-8 1`.
- `run-expansion.sh` — multi-model x multi-run corpus (150 sessions).
- `run-matrix.sh` — prompt x model visible-use matrix (demo vs template prompt).
  The "template" arm needs the template repo's tutor prompt; the script fetches
  it from `llm-wiki-tutor-template` at runtime if absent (via `gh` or `curl`)
  and fails loudly if it cannot, so it runs from a clean clone with no manual
  setup.
- `redteam/` — adaptive two-agent probe: a tool-less attacker adapts each turn
  to the tutor's reply (`run-redteam.sh`, `run-pilot.sh`, `attacker-prompt.md`).
- `hooktest/` — SessionStart hook A/B (`run-hook-ab.sh`) and hook-fire
  detection (`detect.sh`).

## Load-bearing gotcha

Every backgrounded `claude -p` call needs `< /dev/null`. Without it, parallel
children swallow the driver loop's stdin and probes contaminate each other
(this invalidated the first run; symptom: responses referencing "your list of
asks"). All runners here already do this.

The methodology is documented as the `probe-eval` skill at
`.claude/skills/probe-eval/SKILL.md`, and the findings in
`../camera-ready-findings.md`.
