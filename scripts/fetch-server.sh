#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="$(sed -n 's/.*static let serverVersion = "\(.*\)"/\1/p' Sources/GalaxyMirror/Services/Mirror/ScrcpyProtocol.swift)"
SHA256="26cbc9ad0aced6c2282455bef4fb43462605c1f8758c74b4ab1dbf818c229daa"
TARGET="Resources/scrcpy-server"

if [ -f "$TARGET" ] && echo "$SHA256  $TARGET" | shasum -a 256 -c --status; then
    exit 0
fi

curl -sSfL -o "$TARGET.download" "https://github.com/Genymobile/scrcpy/releases/download/v$VERSION/scrcpy-server-v$VERSION"
echo "$SHA256  $TARGET.download" | shasum -a 256 -c --status || { rm -f "$TARGET.download"; echo "Checksum inválido para o scrcpy-server" >&2; exit 1; }
mv "$TARGET.download" "$TARGET"
