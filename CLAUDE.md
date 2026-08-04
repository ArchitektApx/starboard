# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

- Build: `swift build`
- Run: `.build/debug/Starboard` (or `swift run`, but `swift run` attaches the
  process's stdout/stderr to the terminal and blocks it — running the built
  binary directly and backgrounding it is usually more convenient for a
  persistent GUI app)
- There are no tests, linters, or CI configured.

## Architecture

Plain Swift Package Manager executable target (`Starboard`), no Xcode
project, no Info.plist. Three files in `Sources/Starboard/`:

- `main.swift` — entry point. Creates `NSApplication.shared`, sets the
  delegate, and calls `app.setActivationPolicy(.accessory)` *before*
  `app.run()`. This is what gives the app no Dock icon and no Cmd+Tab entry
  — there is no Info.plist / `LSUIElement` involved, since SPM executables
  don't bundle one.
- `KeyablePanel.swift` — an `NSPanel` subclass that overrides
  `canBecomeKey` to return `true`. Needed because a borderless panel with
  `.nonactivatingPanel` style won't accept keystrokes otherwise, and
  `.nonactivatingPanel` is what lets the terminal view become key *without*
  activating the app or stealing focus from whatever app the user is
  currently in.
- `AppDelegate.swift` — everything else: builds the panel, sizes/positions
  it, and wires up the terminal.
  - `dockHeight()` derives the Dock's height from the gap between
    `NSScreen.main.frame` and `.visibleFrame` (assumes the Dock is on the
    bottom edge; returns `nil` — triggering a 64pt fallback — if the Dock is
    hidden, on a side, or auto-hidden).
  - `panelFrame(height:)` places the panel flush against the bottom-right
    corner of the main screen (`screen.frame.maxX - panelWidth`,
    `screen.frame.minY`) — deliberately not trying to compute the actual
    right edge of the (usually centered) Dock, since that space is already
    unused screen real estate.
  - The panel's `collectionBehavior` includes `.canJoinAllSpaces` and
    `.fullScreenAuxiliary` so it stays visible across every Space, including
    over full-screen apps.
  - The terminal itself is a [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm)
    `LocalProcessTerminalView`, started once via
    `startProcess(executable: "/bin/zsh", args: ["-l"], ...)`. This is a
    real PTY-backed shell process, not a `Process` spawned per command —
    that's what makes `cd`, shell history, and arrow-key line editing work
    across commands instead of resetting each time.
  - `nativeBackgroundColor`/`layer?.backgroundColor` are set to `.clear` on
    the terminal view so the panel's blur shows through behind the text;
    SwiftTerm's Metal renderer is off by default (`useMetalRenderer` starts
    `false`), which is what makes the transparent layer approach work — if
    that ever gets toggled on, the transparency handling would need
    revisiting.

No App Sandbox entitlements are set (SPM executables are unsandboxed by
default), which is required for spawning a shell process at all.
