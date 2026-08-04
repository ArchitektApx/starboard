# starboard

A minimal command runner that lives as a translucent, borderless bar in the
bottom-right corner of the screen — an extension of the macOS Dock's empty
space. Type a shell command, press Enter, it runs via `/bin/zsh` and the
field clears. No Dock icon, no app switcher entry, no window chrome.

## What it does right now

- Frameless, translucent (`NSVisualEffectView`) panel, flush to the
  bottom-right corner of the main screen, sized to roughly match the Dock's
  height.
- Floats above normal windows, stays visible across every Space (including
  full-screen apps), and never steals focus from whatever app you're in.
- A single borderless text field. Enter runs the typed string as
  `/bin/zsh -c "<command>"`, discards its output, and clears the field.
- Runs as an accessory process (`NSApp.setActivationPolicy(.accessory)`) —
  no Dock icon, no Cmd+Tab entry.

## Running it

```
swift build
.build/debug/Starboard
```

There's no packaging or auto-launch-at-login yet — it's a plain SPM
executable you start manually.
