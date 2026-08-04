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

There's no packaging or auto-launch-at-login yet — it's a plain SPM
executable you start manually.
