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
ARM64_SCRATCH="$REPO_DIR/.build-arm64"
X86_64_SCRATCH="$REPO_DIR/.build-x86_64"
APP_PATH="$REPO_DIR/.build/release/Starboard.app"
APP_BIN_PATH="$APP_PATH/Contents/MacOS/Starboard"
ZIP_PATH="$REPO_DIR/Starboard.zip"

# Two single-arch builds + lipo, not `swift build --arch arm64 --arch
# x86_64` in one invocation: that form hands the universal-binary step to
# xcbuild, which needs a full Xcode install and isn't available with just
# Command Line Tools. Each --arch build also needs its own --scratch-path:
# sharing one .build/ across arches corrupts SwiftPM's build database
# (confirmed by hand -- a plain second `swift build --arch x86_64` after
# an `--arch arm64` build in the same .build/ fails with "command ...
# not registered", even though the first build's binary is still fine on
# disk). Isolated scratch dirs sidestep that entirely.
echo "Building release binary (arm64)..."
(cd "$REPO_DIR" && swift build -c release --arch arm64 --scratch-path "$ARM64_SCRATCH")

echo "Building release binary (x86_64)..."
(cd "$REPO_DIR" && swift build -c release --arch x86_64 --scratch-path "$X86_64_SCRATCH")

echo "Packaging $APP_PATH..."
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
lipo -create -output "$APP_BIN_PATH" \
    "$ARM64_SCRATCH/arm64-apple-macosx/release/Starboard" \
    "$X86_64_SCRATCH/x86_64-apple-macosx/release/Starboard"

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
