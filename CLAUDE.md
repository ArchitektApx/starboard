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
  `.nonactivatingPanel` is what lets the text field become key *without*
  activating the app or stealing focus from whatever app the user is
  currently in.
- `AppDelegate.swift` — everything else: builds the panel, sizes/positions
  it, and handles command execution.
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
  - `runCommand(_:)` is wired as the text field's action (fires on Enter).
    It shells out via `Process` to `/bin/zsh -c "<command>"` with all
    stdio redirected to `/dev/null` — execution is fire-and-forget by
    design, there is no output or success/failure feedback in the UI.

No App Sandbox entitlements are set (SPM executables are unsandboxed by
default), which is required for `Process` to be able to spawn arbitrary
shell commands.
