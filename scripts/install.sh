#!/bin/bash
# Installs Starboard as a per-user LaunchAgent: starts it now, and arms it
# to start at every future login. Safe to re-run (e.g. after a rebuild) —
# it just rebuilds, repackages, and reloads it.
#
# Packages the binary into a minimal .app bundle with a fixed, ad-hoc
# codesigned identity (--identifier), rather than running the raw
# executable directly. This matters specifically for Accessibility
# permission (needed to track the Dock's geometry): a process launched
# by launchd (as this one is, once installed) has no "responsible" parent
# app to inherit trust from the way a process launched from Terminal
# does, so it needs its own stable TCC identity — an unbundled binary
# with the toolchain's default per-build ad-hoc signature doesn't reliably
# keep that grant across rebuilds, but a bundle signed with a fixed
# --identifier does.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LABEL="com.starboard.app"
BUILD_DIR="$REPO_DIR/.build/release"
BIN_PATH="$BUILD_DIR/Starboard"
APP_PATH="$BUILD_DIR/Starboard.app"
APP_BIN_PATH="$APP_PATH/Contents/MacOS/Starboard"
PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG_PATH="$HOME/Library/Logs/Starboard.log"

echo "Building release binary..."
(cd "$REPO_DIR" && swift build -c release)

echo "Packaging $APP_PATH..."
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
cp "$BIN_PATH" "$APP_BIN_PATH"

cat > "$APP_PATH/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>$LABEL</string>
    <key>CFBundleName</key>
    <string>Starboard</string>
    <key>CFBundleExecutable</key>
    <string>Starboard</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

codesign --force --deep --sign - --identifier "$LABEL" "$APP_PATH"

mkdir -p "$HOME/Library/LaunchAgents"

cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$APP_BIN_PATH</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$LOG_PATH</string>
    <key>StandardErrorPath</key>
    <string>$LOG_PATH</string>
</dict>
</plist>
EOF

launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"

echo "Installed and started."
echo
echo "If the panel isn't tracking the Dock, check System Settings ->"
echo "Privacy & Security -> Accessibility for a \"Starboard\" entry and"
echo "make sure it's enabled — it should now persist across rebuilds."
echo
echo "Turn off (stops it now, and skips it at future logins):"
echo "  launchctl unload $PLIST_PATH"
echo
echo "Turn back on:"
echo "  launchctl load $PLIST_PATH"
echo
echo "Uninstall entirely: scripts/uninstall.sh"
