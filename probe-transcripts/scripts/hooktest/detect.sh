#!/usr/bin/env bash
# Detect whether the project SessionStart hook fires in headless claude -p.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/microelectronics-tutor-demo"
SENTINEL="/tmp/hookfired-$$"
rm -f "$SENTINEL"
# Temporarily make the hook drop a sentinel, run, restore
cp "$REPO/.claude/hooks/session-start.sh" "$REPO/.claude/hooks/session-start.sh.bak"
printf '\ntouch %s\n' "$SENTINEL" >> "$REPO/.claude/hooks/session-start.sh"
( cd "$REPO" && claude -p "say hi" --model claude-sonnet-5 --dangerously-skip-permissions --output-format json >/dev/null 2>&1 )
mv "$REPO/.claude/hooks/session-start.sh.bak" "$REPO/.claude/hooks/session-start.sh"
if [ -f "$SENTINEL" ]; then echo "HOOK FIRED (real hook works headless)"; rm -f "$SENTINEL"; else echo "HOOK DID NOT FIRE (need prompt-injection fallback)"; fi
