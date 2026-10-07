#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="37.0.1"
SHA256="ee39ad5967e95c2a07f04dbcbde96b1a0c916ba376096db5d2f498b7727a5d1d"
TARGET="Resources/adb"
NOTICE="Resources/adb-NOTICE.txt"
STAMP="Resources/adb.version"

if [ -x "$TARGET" ] && [ -f "$NOTICE" ] && [ "$(cat "$STAMP" 2>/dev/null)" = "$VERSION" ]; then
    exit 0
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
curl -sSfL -o "$WORK/platform-tools.zip" "https://dl.google.com/android/repository/platform-tools_r$VERSION-darwin.zip"
echo "$SHA256  $WORK/platform-tools.zip" | shasum -a 256 -c --status || { echo "Checksum inválido para o platform-tools" >&2; exit 1; }
unzip -q -o "$WORK/platform-tools.zip" platform-tools/adb platform-tools/NOTICE.txt -d "$WORK"
mv "$WORK/platform-tools/adb" "$TARGET"
mv "$WORK/platform-tools/NOTICE.txt" "$NOTICE"
echo "$VERSION" > "$STAMP"
