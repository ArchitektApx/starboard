# Starboard

Talk to your machine, quick.

Starboard is a floating terminal that lives beside your macOS Dock —
always on screen, on every desktop, one keystroke away. No window to
find, resize, or alt-tab back to.

![Starboard demo](assets/demo.gif)

## What it does

- Sits directly beside the Dock, tracking its height and position live.
- Visible on every Space, including over full-screen apps — never steals
  focus from whatever app you're in.
- A real, persistent shell (`zsh -l`): `cd`, history, and state carry over
  between commands, same as any terminal tab — not a one-shot command
  runner.
- Its own dark look and a muted, nautical ANSI color palette — not a
  system lookalike.

## Requirements

- macOS 13+
- Accessibility permission (prompted on first launch) — used to read the
  Dock's live position. Starboard still works without it, just pinned to
  a fixed corner instead of hugging the Dock.

## Install

Run it once:

```
swift build
.build/debug/Starboard
```

Run at login (packages and code-signs a `.app`, registers it as a
LaunchAgent):

```
scripts/install.sh
```

Stop / start / remove:

```
launchctl unload ~/Library/LaunchAgents/com.starboard.app.plist   # stop
launchctl load ~/Library/LaunchAgents/com.starboard.app.plist     # start
scripts/uninstall.sh                                              # remove entirely
```

Logs: `~/Library/Logs/Starboard.log`

## Known issues

- Pasted text briefly renders in the wrong color until the next keypress.
- (Previously) some prompt glyphs rendered as `?` during live redraws —
  hasn't recurred recently.

See `CLAUDE.md` for architecture, design decisions, and the full
write-up on both issues above.
