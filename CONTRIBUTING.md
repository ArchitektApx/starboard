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

## PR guidelines

- **One change per PR.** A PR that bundles a bug fix with an unrelated
  feature (or several unrelated features) won't get approved as one
  unit — split it up, even if it was all written in one sitting.
- **Keep PRs small.** Prefer the smallest diff that does the thing.
  `AppDelegate.swift` is deliberately compact and heavily commented —
  a PR that adds a thousand-plus lines to it is a sign the change
  should be split or scoped down, not a sign the file needed to grow
  that much. Bigger diffs are fine when there's a real reason (e.g. a
  genuine Dock-tracking-wide refactor) — just say what that reason is
  in the PR description.

## Everything else

Open an issue for bugs or ideas. If a change touches the Dock-tracking
or code-signing logic, explain what you tested it against
(Accessibility permission state, Dock tile size, macOS version) since
those are the parts most sensitive to environment differences.
