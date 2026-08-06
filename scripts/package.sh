#!/bin/bash
# Builds a release .app bundle and zips it for distribution (GitHub
# Releases, or a by-hand download). Used both by hand and by
# .github/workflows/release.yml on a version-tag push.
#
# Unlike scripts/install.sh, this does NOT touch LaunchAgents, the login
# keychain, or a local signing certificate -- it ad-hoc signs
# (`codesign --sign -`) instead. install.sh's cert-based signing exists
# specifically so a launchd-launched process keeps a stable TCC identity
# for Accessibility across rebuilds; a downloaded .app is launched
# interactively (Finder/`open`), which doesn't have that requirement, so
# plain ad-hoc signing -- enough to satisfy Gatekeeper's "is this signed
# at all" check and let the binary run once approved -- is sufficient
# here. No entitlements file is applied, matching install.sh: Starboard
# is unsandboxed and needs no entitlements either way.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LABEL="com.starboard.app"
BUILD_DIR="$REPO_DIR/.build/release"
BIN_PATH="$BUILD_DIR/Starboard"
APP_PATH="$BUILD_DIR/Starboard.app"
APP_BIN_PATH="$APP_PATH/Contents/MacOS/Starboard"
ZIP_PATH="$REPO_DIR/Starboard.zip"

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

echo "Ad-hoc signing $APP_PATH..."
codesign --force --deep --sign - --identifier "$LABEL" "$APP_PATH"

echo "Zipping..."
rm -f "$ZIP_PATH"
# ditto, not zip: preserves the code signature's extended attributes,
# which a plain `zip` can silently drop.
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo
echo "Done: $ZIP_PATH"
