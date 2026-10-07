#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

APP="build/Galaxy Mirror.app"
DMG="build/Galaxy Mirror.dmg"
STAGE="build/dmg"

./scripts/build-app.sh

rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Aplicativos"
hdiutil create -quiet -volname "Galaxy Mirror" -srcfolder "$STAGE" -ov -format UDZO "$DMG"
rm -rf "$STAGE"

echo "Pronto: $DMG"
