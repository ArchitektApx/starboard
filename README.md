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
  falls back to an approximate fixed-width panel in the corner. Because
  this is an unsigned, non-bundled binary rather than a proper `.app`,
  macOS may treat a rebuild as a "new app" and ask you to re-grant it —
  that's expected, not a bug.
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

## Known issue

Some prompt-theme glyphs (e.g. oh-my-zsh's `robbyrussell` arrow/git-dirty
indicators) intermittently render as `?` instead of the correct character.
Ruled out so far: font coverage (Menlo has the relevant glyphs), locale
(`LANG` is correctly `en_US.UTF-8`), and raw glyph rendering (`printf
'➤ ✗\n'` renders correctly outside the prompt). Still
unresolved — likely something in how the theme's `%(?:...:...)` conditional
prompt syntax evaluates in this PTY session specifically.

## Running it

```
swift build
.build/debug/Starboard
```

## Running it at login

`scripts/install.sh` builds the release binary and registers it as a
per-user [LaunchAgent](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html) —
macOS's mechanism for starting and supervising background processes. It
starts Starboard immediately and arms it to start at every future login.

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
