#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-release}"
APP="build/Galaxy Mirror.app"

swift build -c "$CONFIG"
BIN=".build/$CONFIG/GalaxyMirror"

[ -f Resources/AppIcon.icns ] || swift scripts/make-icon.swift
./scripts/fetch-server.sh

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/GalaxyMirror"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp Resources/scrcpy-server "$APP/Contents/Resources/scrcpy-server"
codesign --force --sign - "$APP"

echo "Pronto: $APP"
