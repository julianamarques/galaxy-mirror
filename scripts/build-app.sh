#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="release"
ARCH_FLAGS=()
for arg in "$@"; do
    case "$arg" in
        --universal) ARCH_FLAGS=(--arch arm64 --arch x86_64) ;;
        -*) echo "opção desconhecida: $arg" >&2; exit 1 ;;
        *) CONFIG="$arg" ;;
    esac
done
APP="build/Galaxy Mirror.app"

swift build -c "$CONFIG" ${ARCH_FLAGS[@]+"${ARCH_FLAGS[@]}"}
BIN="$(swift build -c "$CONFIG" --show-bin-path ${ARCH_FLAGS[@]+"${ARCH_FLAGS[@]}"})/GalaxyMirror"

[ -f Resources/AppIcon.icns ] || swift scripts/make-icon.swift
./scripts/fetch-server.sh
./scripts/fetch-adb.sh

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/GalaxyMirror"
MIN_MACOS="$(/usr/libexec/PlistBuddy -c "Print :LSMinimumSystemVersion" Resources/Info.plist)"
xcrun vtool -set-build-version macos "$MIN_MACOS" "$(xcrun --show-sdk-version)" -replace \
    -output "$APP/Contents/MacOS/GalaxyMirror" "$APP/Contents/MacOS/GalaxyMirror" 2>/dev/null
cp Resources/adb "$APP/Contents/MacOS/adb"
cp Resources/adb-NOTICE.txt "$APP/Contents/Resources/adb-NOTICE.txt"
cp LICENSE NOTICE Resources/licenses/scrcpy-LICENSE.txt "$APP/Contents/Resources/"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp Resources/scrcpy-server "$APP/Contents/Resources/scrcpy-server"
for CATALOG in Resources/Localizable.xcstrings Resources/InfoPlist.xcstrings; do
    xcrun xcstringstool compile "$CATALOG" --output-directory "$APP/Contents/Resources"
    swift scripts/make-source-strings.swift "$CATALOG" "$APP/Contents/Resources" >/dev/null
done
codesign --force --sign - "$APP"

echo "Pronto: $APP"
