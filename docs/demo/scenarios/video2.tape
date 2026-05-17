# Video 2 — The Tutor
#
# Render with:
#   cd <repo root>
#   vhs docs/demo/scenarios/video2.tape
#
# Output: docs/demo/scenarios/video2.mp4 (~4–5 minutes)
#
# Wiki page renders are inline via the `>wiki|Page-Name` directives in
# video2.dialog. glow reads them from wiki/microelectronics-tutor-demo.wiki/.
# Hold time per wiki page is set by WIKI_HOLD (default 6s); raise if you want
# more reading room before voiceover.

Output docs/demo/scenarios/video2.mp4

Set Shell "bash"
Set FontSize 18
Set Width 1920
Set Height 1080
Set Padding 40
Set Theme "Dracula"
Set TypingSpeed 0ms
Set PlaybackSpeed 1.0
Set FontFamily "Menlo, Monaco, monospace"

# Boot — silent setup, then clear.
Hide
Type "cd /Users/csweet1/Documents/projects/TCF/microelectronics-tutor-demo"
Enter
Sleep 200ms
Type "clear"
Enter
Sleep 200ms
Show

# Play the dialog. WIKI_HOLD=8 gives a generous reading beat on each wiki page;
# tune lower (4–6) if the recording feels slow, higher if voiceover needs room.
Type "WIKI_HOLD=8 ./docs/demo/scenarios/lib/play-dialog.sh docs/demo/scenarios/video2.dialog"
Enter
Sleep 360s
