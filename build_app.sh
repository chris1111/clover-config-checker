#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/dist/Clover Config Checker.app"

swift build --package-path "$ROOT/macOS" -c release
BIN_DIR="$(swift build --package-path "$ROOT/macOS" -c release --show-bin-path)"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/Backend/clover_config_checker"
cp "$BIN_DIR/CloverConfigCheckerApp" "$APP/Contents/MacOS/CloverConfigChecker"
cp "$ROOT"/clover_config_checker/*.py "$APP/Contents/Resources/Backend/clover_config_checker/"
cp "$ROOT/macOS/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/macOS/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
cp "$ROOT/LICENSE" "$APP/Contents/Resources/LICENSE"
codesign --force --sign - "$APP"
codesign --verify --deep --strict "$APP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ROOT/dist/Clover-Config-Checker-macOS.zip"
printf '\nAplicativo criado em: %s\nAbra com: open "%s"\n' "$APP" "$APP"
