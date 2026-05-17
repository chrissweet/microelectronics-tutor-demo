# Video 2 (REAL) — captured live Claude tutor session
#
# Render with:
#   bin/capture-real-tutor.sh       # writes/refreshes video2-real.dialog
#   vhs docs/demo/scenarios/video2-real.tape
#
# Output: docs/demo/scenarios/video2-real.mp4
#
# Unlike video2.tape (scripted), this one plays back a transcript captured
# from a real `claude -p` session against the course wiki. Re-running the
# capture produces a different transcript — keep one you like.

Output docs/demo/scenarios/video2-real.mp4

Set Shell "bash"
Set FontSize 18
Set Width 1920
Set Height 1080
Set Padding 40
Set Theme "Dracula"
Set TypingSpeed 0ms
Set PlaybackSpeed 1.0
Set FontFamily "Menlo, Monaco, monospace"

Hide
Type "cd /Users/csweet1/Documents/projects/TCF/microelectronics-tutor-demo"
Enter
Sleep 200ms
Type "clear"
Enter
Sleep 200ms
Show

# Measured runtime: ~4:05 for the two-agent capture of 2026-05-17 (9 turns
# after manual splicing out of late-conversation meta-breaks, 3 wiki
# references, WIKI_HOLD=8). Re-time after each recapture with:
#   { time ./docs/demo/scenarios/lib/play-dialog.sh ... > /dev/null; }
Type "WIKI_HOLD=8 ./docs/demo/scenarios/lib/play-dialog.sh docs/demo/scenarios/video2-real.dialog"
Enter
Sleep 260s
