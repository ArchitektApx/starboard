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
- Cmd+E expands it to full screen height (growing upward from the Dock)
  when you need more room — long output, or running something like Claude
  Code in there — then Cmd+E again to snap back to Dock height.

## Requirements

- macOS 13+
- Accessibility permission (prompted on first launch) — used to read the
  Dock's live position. Starboard still works without it, just pinned to
  a fixed corner instead of hugging the Dock.
- Currently assumes a bottom-docked Dock on the main display. Left/right
  Dock placement and multi-monitor setups aren't handled yet — feedback
  and contributions welcome.

## Security & trust

Starboard makes no network requests and collects no data — there's
nothing in the source that could, since it's under 700 lines across 4
Swift files, worth reading yourself rather than taking on faith. The one
sensitive-looking permission it asks for, Accessibility, is used for
exactly one thing: reading the Dock's on-screen position so the panel can
sit next to it. `scripts/install.sh` only touches your own user-level
LaunchAgents and login keychain (never system-wide, never `sudo`), and
the local code-signing certificate it creates is scoped narrowly to code
signing — it exists purely so macOS remembers the Accessibility grant
across rebuilds, not for anything else.

## Download

Grab the latest build from [Releases](https://github.com/palamim/starboard/releases/latest), then:

```
unzip Starboard.zip
mv Starboard.app /Applications/
open /Applications/Starboard.app
```

The build is ad-hoc signed, not notarized (notarization needs a paid
Apple Developer account), so on first launch Gatekeeper will block it —
open System Settings → Privacy & Security, scroll down, and click **Open
Anyway** next to the Starboard entry. If you'd rather not click through
that warning, the source is under 700 lines across 4 Swift files — worth
reading, and buildable yourself with `swift build` below instead.

Each release is signed ad-hoc, and that signature differs between builds,
so updating to a new version may ask you to re-grant Accessibility
permission (System Settings → Privacy & Security → Accessibility) even if
you'd already granted it for the previous one.

## Build from source

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

## License

MIT — see `LICENSE`.
