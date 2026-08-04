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
- `AppDelegate.swift` — everything else: builds the panel, tracks the Dock
  to size/position it, and wires up the terminal.
  - The panel's `collectionBehavior` includes `.canJoinAllSpaces` and
    `.fullScreenAuxiliary` so it stays visible across every Space, including
    over full-screen apps. `effectView.layer?.masksToBounds = true` clips
    the (edge-to-edge) terminal view to the panel's rounded corners —
    without it, square corners get painted over the rounded blur.
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
  - `setUpMainMenu()` builds a minimal `NSMenu` (Quit + Edit: Copy/Paste/
    Select All) and sets it as `NSApp.mainMenu`. This menu is never
    visibly shown — the nonactivating panel never makes Starboard the
    frontmost app — but Cmd+C/Cmd+V/Cmd+A only resolve to a view's
    `copy(_:)`/`paste(_:)`/`selectAll(_:)` via AppKit's menu-key-equivalent
    system, so without *some* main menu those keystrokes go nowhere,
    silently, regardless of whether it's ever drawn on screen.

### Dock tracking

The panel positions itself as a companion to the Dock — same height, left
edge touching the Dock's right edge, same bottom margin as the Dock (so
they share a baseline), and that same margin held on the panel's own right
edge. A repeating `Timer` (`dockTrackingInterval`, 1s) recomputes this and
calls `panel.setFrame` whenever it changes, so it follows the Dock live as
it's resized or gains/loses icons — there's no notification to observe for
this, so it's polled.

The Dock's geometry comes from `dockIconTrayFrame()`, which reads the
`AXList` element (the icon row) from the Dock process's accessibility tree
via `AXUIElementCreateApplication` / `AXUIElementCopyAttributeValue`. This
is deliberately **not** `CGWindowListCopyWindowInfo`: on modern macOS the
Dock's own window frame spans the entire screen (the Dock process also
hosts desktop wallpaper/icon interaction — see the sibling "Wallpaper"
window owned by the same process), which is useless for positioning. The
`AXList` box is close but not exact: its bottom edge sits above the Dock's
real bottom margin, and its top edge overshoots above the Dock's real top
edge by a smaller amount — Apple doesn't expose the actual painted chrome
rectangle through Accessibility at all. `dockBottomCorrection` (6pt) and
`dockTopCorrection` (5pt) are empirical fixes for that gap, tuned pixel by
pixel against one real Dock; nudge them if the panel's edges visibly drift
from the Dock's, e.g. at a very different tile size.

Reading another process's accessibility tree requires the user to grant
Starboard Accessibility permission (`AXIsProcessTrustedWithOptions` is
called with the prompt option at launch to trigger the system dialog).
Until granted — or if the Dock's AX tree is ever unreadable —
`fallbackFrame(on:)` is used instead: a fixed-width panel in the
bottom-right corner, with height read from the gap between
`NSScreen.main.frame` and `.visibleFrame` (which doesn't need any special
permission, but also can't reveal the Dock's *width*).

No App Sandbox entitlements are set (SPM executables are unsandboxed by
default), which is required for spawning a shell process at all.

### Why `scripts/install.sh` packages a `.app` bundle

Confirmed by direct debugging (temporary `FileHandle.standardError` calls
around `AXIsProcessTrusted()` and the `AXError` from
`AXUIElementCopyAttributeValue`, logged via the LaunchAgent's
`StandardErrorPath`): a process launched by `launchctl` gets
`AXIsProcessTrusted() == false` and `AXError -25211` (`kAXErrorAPIDisabled`)
even when Accessibility looks granted in System Settings — while the exact
same binary launched directly from a Terminal/Bash shell reports
`trusted == true`. The difference is TCC's "responsible process"
attribution: a process launched interactively from Terminal can inherit
Terminal's own Accessibility trust, but a `launchd`-spawned process has no
such parent to inherit from and needs its own standalone grant. That grant
didn't reliably stick for the raw, unbundled executable — its ad-hoc code
signature (assigned automatically by the toolchain) is content-derived and
changes on every rebuild, giving TCC nothing stable to track.

The fix: `install.sh` copies the built binary into a minimal
`Starboard.app` (`Contents/Info.plist` + `Contents/MacOS/Starboard`) and
signs it with `codesign --sign - --identifier com.starboard.app` — an
explicit, fixed identifier rather than the toolchain's default hash-based
one. That gives TCC a stable identity to key the grant against, so it
survives rebuilds. The LaunchAgent's `ProgramArguments` points at
`Starboard.app/Contents/MacOS/Starboard`, not the bare `.build/release/Starboard`.
Running the raw executable directly (`swift run`, or the debug build) still
works for local iteration since it inherits trust from its Terminal parent
— it's specifically the persistent, `launchd`-launched instance that needs
the bundle.

### Terminal styling and layout

The terminal uses Menlo, not `NSFont.monospacedSystemFont` (SF Mono) —
verified programmatically (`CTFontGetGlyphsForCharacters`) that SF Mono is
missing glyphs common shell prompt themes use, e.g. `➤` (U+27A4), which
Menlo has. `terminalFont` is computed once in `AppDelegate.init()` rather
than per-launch, since it's reused by both the initial layout and every
subsequent resize.

`terminalContentFrame(in:)` insets by `terminalPadding` (8pt) and then
vertically centers the content within that padding. This exists because
SwiftTerm derives its row count as `Int(height / cellHeight)` — a floor
operation — which almost never divides the available height evenly; a
plain edge inset leaves the leftover slack stuck at the bottom, reading as
content pinned to the top. `estimatedCellHeight(for:)` mirrors SwiftTerm's
own internal calculation (`AppleTerminalView.computeFontDimensions`:
ascent + descent + leading at 1.0 line spacing) so the padding can predict
the row count before SwiftTerm lays out. `terminalFontSize` (11pt) and
`terminalPadding` (8pt) are chosen together so a ~57-60pt Dock height
lands on exactly two visible rows.

Because centering depends on the panel's live height, the terminal's
`autoresizingMask` is `[.width]` only — height is NOT auto-flexible.
`syncFrameToDock()` explicitly recomputes `terminalView.frame` via
`terminalContentFrame(in:)` every time it resizes the panel, rather than
letting AppKit's autoresizing stretch the terminal to fill the new size
(which would rewiden the padding asymmetrically as the panel resizes).

### Known issue: prompt glyphs occasionally render as `?` (confirmed upstream SwiftTerm bug)

Some prompt-theme glyphs (oh-my-zsh's `robbyrussell` theme specifically —
`➜` U+27A4 and `✗` U+2717) intermittently render as `?`. Confirmed to be
a bug in SwiftTerm's own glyph rendering, not Starboard's code — see
[SwiftTerm#231](https://github.com/migueldeicaza/SwiftTerm/issues/231),
where a different glyph-heavy prompt theme (powerlevel10k) shows the same
category of corruption, and the maintainer attributes it to CoreText
glyph-positioning calls (`CTRunGetPositions`/`CTRunGetAdvances`) that
SwiftTerm likely isn't using correctly.

Ruled out on Starboard's side, each confirmed by direct testing rather
than assumption, before concluding it was upstream:
- **Font coverage**: Menlo has both glyphs (`CTFontGetGlyphsForCharacters`
  confirmed it; SF Mono, tried first, did not).
- **Locale**: `LANG=en_US.UTF-8` is set (`Terminal.getEnvironmentVariables`
  in SwiftTerm sets this by default regardless of caller environment).
- **Raw glyph rendering**: `printf '➤ ✗\n'` renders correctly.
- **Raw ANSI color immediately before the glyph**: `printf
  '\033[1;32m➜\033[0m test\n'` renders correctly — rules out an
  SGR-then-multibyte-character parsing bug.
- **The theme's exact zsh syntax** (`%(?:...:...)` conditional and
  `%1{...%}` width-override hint): `print -P` with the theme's literal
  fragment renders correctly in isolation.
- **Line wrapping**: forcing the arrow onto a wrapped line
  (`printf '%*s' "$COLUMNS" '' | tr ' ' '.'` filler + the glyph) still
  rendered clean.
- **Character-width mismatch**: checked `UnicodeWidthData.swift`'s
  `eastAsianWide` table directly — neither U+27A4 nor U+2717 is
  classified as double-width, so there's no width disagreement with
  zsh's own `%1{...%}` single-column assumption.

The common thread: every *static* reproduction (a single `print`/`printf`)
renders correctly; it only appears during a *live* prompt redraw — ZLE
(zsh's line editor) erasing and repainting an existing prompt line with
new content, e.g. after `cd`-ing into a git repo changes the prompt's
git-status segment. That points at SwiftTerm's redraw/overwrite path
specifically, consistent with the upstream issue above. No fix available
short of patching SwiftTerm.
