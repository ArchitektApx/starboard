# starboard

A real terminal, shrunk down to a translucent, borderless bar that lives in
the bottom-right corner of the screen — an extension of the macOS Dock's
empty space. It's a persistent `zsh` login shell, not a one-shot command
runner: `cd` and shell state carry over between commands, arrow-key history
works, and output streams in live, same as any terminal tab.

## What it does right now

- Frameless, translucent (`NSVisualEffectView`) panel, flush to the
  bottom-right corner of the main screen, sized to roughly match the Dock's
  height.
- Floats above normal windows, stays visible across every Space (including
  full-screen apps), and never steals focus from whatever app you're in.
- A full terminal emulator ([SwiftTerm](https://github.com/migueldeicaza/SwiftTerm)'s
  `LocalProcessTerminalView`) backed by a single persistent `/bin/zsh -l`
  process — shell state, working directory, and history persist across
  commands, and the blur shows through behind the text.
- Runs as an accessory process (`NSApp.setActivationPolicy(.accessory)`) —
  no Dock icon, no Cmd+Tab entry.

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
