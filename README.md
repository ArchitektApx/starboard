# Starboard

[![Latest release](https://img.shields.io/github/v/release/palamim/starboard)](https://github.com/palamim/starboard/releases/latest)

A terminal that's just always there — not summoned, not dismissed.

Starboard lives permanently beside your macOS Dock: on screen, on every
desktop, all the time. There's no hotkey to call it up and no window to
find, resize, or alt-tab back to, because it never goes away in the
first place.

![Starboard demo](assets/demo.gif)

## What it does

- Sits directly beside the Dock, tracking its height and position live.
- Visible on every Space, including over full-screen apps — never steals
  focus from whatever app you're in.
- A real, persistent shell (`zsh -l`) — `cd`, history, and state carry
  over between commands, not a one-shot command runner.
- Its own dark look and a muted, nautical ANSI color palette.
- Cmd+E expands it to full screen height for when Dock-height isn't
  enough, then Cmd+E again to snap back.

## Download

Grab the latest build from [Releases](https://github.com/palamim/starboard/releases/latest), then:

```
unzip Starboard.zip
mv Starboard.app /Applications/
open /Applications/Starboard.app
```

The build is ad-hoc signed, not notarized, so the first launch takes a
few extra clicks:

1. Opening it is blocked outright ("Starboard" Not Opened) — click Done.
2. System Settings → Privacy & Security → **Open Anyway** next to the
   Starboard entry.
3. Confirm **Open Anyway** again, then enter your password.
4. Starboard launches, but an Accessibility prompt appears — click
   **Open System Settings** and enable Starboard, so it can track the
   Dock.

To have it launch automatically at login: **System Settings → General →
Login Items & Extensions → + → select Starboard.app**. That's it — no
script needed for a downloaded build.

Updating to a new release may ask you to re-grant Accessibility, since
each release is signed differently. See `CLAUDE.md` for the full
permission/signing model, and for what to do if you also have a
build-from-source copy installed via `scripts/install.sh`.

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

See `CLAUDE.md` for why building from source needs this script (rather
than Login Items) to keep Accessibility permission across rebuilds.

## How this differs from Quake-style terminals

Guake, Yakuake, tilda, iTerm2's hotkey window, Ghostty's quick terminal —
these summon a terminal with a hotkey, hand it focus, and dismiss it
again when you're done. Starboard has no hotkey, never takes focus, and
has no summon/dismiss cycle — it's just sitting there, the way the Dock
itself is. That's the point: run a command in whatever project you're
in, then go straight back to the editor, without switching apps or
losing your place.

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
sit next to it.

## Known issues

- Pasted text briefly renders in the wrong color until the next keypress.
- (Previously) some prompt glyphs rendered as `?` during live redraws —
  hasn't recurred recently.

See `CLAUDE.md` for architecture, design decisions, and the full
write-up on both issues above.

## License

MIT — see `LICENSE`.
