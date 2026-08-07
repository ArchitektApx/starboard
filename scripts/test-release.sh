#!/bin/bash
# Builds the exact artifact scripts/package.sh produces for a GitHub
# Release, then swaps it into /Applications in place of whatever
# Starboard is running there. A fast way to try a change as if it had
# already shipped, without going through GitHub or scripts/install.sh's
# separate LaunchAgent/certificate identity -- daily use only needs one
# Starboard, and this keeps it that way instead of creating a second,
# differently-signed instance that confuses which Accessibility grant is
# the live one (see CLAUDE.md).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="$REPO_DIR/.build/release-dist/Starboard.app"
INSTALLED_PATH="/Applications/Starboard.app"

echo "Quitting any running Starboard..."
pkill -x Starboard 2>/dev/null || true
sleep 1

"$REPO_DIR/scripts/package.sh"

echo "Replacing $INSTALLED_PATH..."
rm -rf "$INSTALLED_PATH"
cp -R "$APP_PATH" "$INSTALLED_PATH"

# Ad-hoc signing pins TCC's Accessibility grant to the binary's content
# hash, not to the bundle path or identifier -- so replacing the app in
# place leaves a stale record that *looks* granted (same "Starboard" row,
# checkbox still on) but silently fails the trust check against the new
# binary. Confirmed by hand: toggling that existing checkbox off/on does
# NOT fix it, because it just flips the existing (mismatched) record
# rather than replacing it -- only fully removing the row (manually via
# the "-" button, or here) and letting a fresh one get created does.
# `tccutil reset` scoped to this one bundle ID only clears Starboard's
# own record, not any other app's.
echo "Clearing the stale Accessibility grant..."
tccutil reset Accessibility com.starboard.app 2>/dev/null || true

echo "Opening $INSTALLED_PATH..."
open "$INSTALLED_PATH"

echo
echo "Done. macOS will prompt for Accessibility permission again -- grant"
echo "it in System Settings -> Privacy & Security -> Accessibility. This"
echo "run always resets that grant first, so the prompt (and the fix if"
echo "you miss it) is the same every time, not silently stale."
