# CLAUDE.md

Guidance for Claude Code working in this repo.

## Commands

- Build: `swift build`
- Run: `.build/debug/Starboard`, backgrounded (`swift run` blocks the
  terminal on stdout/stderr)
- No tests, linters, or CI beyond `.github/workflows/build.yml`.

## Code style

Zero comments in `Sources/Starboard/`, by design — this file is the only
place rationale lives. If you add non-obvious logic, document the *why*
here, not inline.

## Architecture

Plain SPM executable, no Xcode project, no Info.plist — `main.swift` sets
`.accessory` activation policy directly instead. `AppDelegate`'s behavior
is split across `AppDelegate+*.swift` extensions by concern (menu,
Dock-tracking state machine, Dock-relative geometry, screen resolution,
Dock Accessibility reads, debug logging); `DockPresence`, `PanelBuilder`,
`TerminalTheme`, `TerminalLayout`, and `ShellEnvironment` are standalone.
Read the code for how it works — it's small and the names are literal.

## Non-obvious gotchas (not discoverable by reading the code)

- **Dock geometry** comes from the Dock process's Accessibility tree
  (`AXList`), not `CGWindowListCopyWindowInfo` — that window spans the
  whole screen. Requires Accessibility permission; falls back to a fixed
  corner without it. `STARBOARD_DEBUG=1` enables stderr geometry logging.
- **A `launchd`-spawned process doesn't inherit Accessibility trust** the
  way a Terminal- or Login-Items-launched one does, and ad-hoc signing
  pins that trust to the binary's content hash, which changes every
  rebuild. `scripts/install.sh` works around this with a locally
  generated, self-signed certificate so the signing identity — and the
  grant — survives rebuilds. A downloaded release added to Login Items
  doesn't need any of this.
- **Updating an installed build in place** (manual overwrite or `brew
  upgrade`) leaves a stale Accessibility grant that looks enabled in
  System Settings but silently doesn't work. Fix: remove the row and
  re-grant, or `tccutil reset Accessibility com.starboard.app`.
  `scripts/test-release.sh` does this automatically before each local
  test cycle — always test releases through it, not a raw rebuild.
- **SwiftTerm's default child environment omits `SHELL`**, which breaks
  tools that branch on it (e.g. ngrok's zsh completion emitting bash
  syntax). `ShellEnvironment` sets it explicitly — don't pass `nil` for
  `startProcess`'s `environment`.
- The Homebrew tap (`Casks/starboard.rb`) is self-hosted, not submitted to
  `homebrew/cask`, because that tap requires notarization and Starboard is
  ad-hoc signed only. `.github/workflows/release.yml` updates the cask's
  version/sha256 automatically on every tag push.

## Known open items

- Pasted text briefly renders in the wrong foreground color until the
  next keypress (SwiftTerm's own paste path; not investigated further).
- A handful of narrow, deliberately-deferred edge cases in the
  auto-hide-Dock coupling — see PR #7 discussion before touching that
  area.
