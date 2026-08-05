# Contributing

## Build

```
swift build
.build/debug/Starboard
```

No tests, linters, or CI beyond a build check — see `CLAUDE.md` for the
full architecture and the reasoning behind the current design decisions
before making changes, especially around Dock-tracking geometry and the
code-signing setup in `scripts/install.sh`.

## Wanted: Dock position / multi-monitor support

Right now Starboard assumes a bottom-docked Dock on the main display
(see `dockIconTrayFrame()`/`currentFrame()` in `AppDelegate.swift`).
Left/right Dock placement and multi-monitor setups aren't handled. This
is the area most worth a PR — happy to help scope it in an issue first
if you want to work on it.

## Everything else

Open an issue for bugs or ideas. Small, focused PRs are easiest to
review — if a change touches the Dock-tracking or code-signing logic,
explain what you tested it against (Accessibility permission state,
Dock tile size, macOS version) since those are the parts most sensitive
to environment differences.
