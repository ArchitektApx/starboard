# starboard

A real terminal, shrunk down to a translucent, rounded bar that lives
directly beside the macOS Dock — literally an extension of it, to
starboard. It's a persistent `zsh` login shell, not a one-shot command
runner: `cd` and shell state carry over between commands, arrow-key history
works, and output streams in live, same as any terminal tab.

## What it does right now

- Frameless, translucent (`NSVisualEffectView`, all four corners rounded)
  panel that tracks the Dock live: same height, left edge touching the
  Dock's right edge, same bottom margin (so they sit on one baseline), and
  that same margin held on the panel's own right edge. Re-checks the Dock's
  actual geometry once a second and resizes/repositions itself to match —
  so it follows along as you resize the Dock or add/remove icons.
- The Dock's geometry is read live via the Accessibility API (its `AXList`
  icon-tray element), not guessed or hardcoded — see `CLAUDE.md` for how
  and why. Requires granting Starboard Accessibility permission once
  (System Settings → Privacy & Security → Accessibility); until granted, it
  falls back to an approximate fixed-width panel in the corner.
  `scripts/install.sh` packages the binary into a minimal `.app`, signed
  with a local self-signed certificate (created on first run) rather than
  ad-hoc, so this grant survives rebuilds — running the raw executable
  directly (e.g. `swift run`) won't have a stable identity and may need
  re-granting each time.
- Floats above normal windows, stays visible across every Space (including
  full-screen apps), and never steals focus from whatever app you're in.
- A full terminal emulator ([SwiftTerm](https://github.com/migueldeicaza/SwiftTerm)'s
  `LocalProcessTerminalView`) backed by a single persistent `/bin/zsh -l`
  process — shell state, working directory, and history persist across
  commands, and the blur shows through behind the text.
- `.menu` material with a faint white border, echoing the Dock's own
  neutral frosted chrome and edge highlight. 8pt padding, Menlo 11pt, tuned
  to fit exactly two rows at a ~57-60pt Dock height and centered in
  whatever vertical slack is left over.
- Runs as an accessory process (`NSApp.setActivationPolicy(.accessory)`) —
  no Dock icon, no Cmd+Tab entry.
- A minimal, never-shown main menu wires up Cmd+C/Cmd+V/Cmd+A (copy, paste,
  select all) — without any menu at all, those key equivalents have nothing
  to route through and silently do nothing.

## Known issue

Some prompt-theme glyphs (e.g. oh-my-zsh's `robbyrussell` arrow/git-dirty
indicators) intermittently render as `?`. This is a confirmed **upstream
bug in SwiftTerm itself**, not Starboard's code — see
[SwiftTerm#231](https://github.com/migueldeicaza/SwiftTerm/issues/231),
where another user reports the same category of corruption with a
different glyph-heavy prompt theme (powerlevel10k), and the maintainer
attributes it to CoreText glyph-positioning calls
(`CTRunGetPositions`/`CTRunGetAdvances`) SwiftTerm likely isn't using
correctly. Ruled out on Starboard's side first: font coverage, locale,
raw glyph rendering, the exact zsh prompt-conditional syntax, line
wrapping, and character-width mismatches — none reproduce it in
isolation, only live prompt redraws do, which points at the renderer
rather than anything upstream of it. No fix available short of patching
SwiftTerm; a prompt theme without these glyphs sidesteps it entirely.

Separately, unrelated and not yet investigated: pasted text briefly
renders in black instead of the correct foreground color, until the next
keypress triggers a redraw.

## Running it

```
swift build
.build/debug/Starboard
```

## Running it at login

`scripts/install.sh` builds the release binary, packages it as
`Starboard.app` (signed with a local self-signed certificate — see
above), and registers it as a per-user
[LaunchAgent](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html) —
macOS's mechanism for starting and supervising background processes. It
starts Starboard immediately and arms it to start at every future login.

On first run it also creates and trusts that certificate, which may
prompt for your macOS login password (to confirm the new trust setting).
The certificate itself is only created once (verified: re-running
`install.sh` doesn't create a duplicate), but whether the password prompt
itself recurs on later rebuilds hasn't been fully pinned down yet — it
showed up again on a subsequent rebuild in testing, source not yet
identified. Not disruptive, just not fully understood yet.

```
scripts/install.sh
```

Turn it off (stops it now, and skips it at future logins):

```
launchctl unload ~/Library/LaunchAgents/com.starboard.app.plist
```

Turn it back on:

```
launchctl load ~/Library/LaunchAgents/com.starboard.app.plist
```

Remove the login item entirely:

```
scripts/uninstall.sh
```

Logs (stdout/stderr from the running process) go to
`~/Library/Logs/Starboard.log`.
