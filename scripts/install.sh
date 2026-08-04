#!/bin/bash
# Installs Starboard as a per-user LaunchAgent: starts it now, and arms it
# to start at every future login. Safe to re-run (e.g. after a rebuild) —
# it just regenerates the plist and reloads it.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_PATH="$REPO_DIR/.build/release/Starboard"
LABEL="com.starboard.app"
PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG_PATH="$HOME/Library/Logs/Starboard.log"

if [ ! -x "$BIN_PATH" ]; then
    echo "Building release binary..."
    (cd "$REPO_DIR" && swift build -c release)
fi

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
        <string>$BIN_PATH</string>
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
echo "Turn off (stops it now, and skips it at future logins):"
echo "  launchctl unload $PLIST_PATH"
echo
echo "Turn back on:"
echo "  launchctl load $PLIST_PATH"
echo
echo "Uninstall entirely: scripts/uninstall.sh"
