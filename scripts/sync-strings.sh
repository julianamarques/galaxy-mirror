#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

CATALOG="Resources/Localizable.xcstrings"
SCRATCH=".build/strings"

[ -f "$CATALOG" ] || echo '{"sourceLanguage":"pt-BR","strings":{},"version":"1.0"}' > "$CATALOG"
rm -rf "$SCRATCH"
mkdir -p "$SCRATCH/stringsdata"
swift build --scratch-path "$SCRATCH" -Xswiftc -emit-localized-strings -Xswiftc -emit-localized-strings-path -Xswiftc "$PWD/$SCRATCH/stringsdata" >/dev/null
find "$SCRATCH/stringsdata" -name '*.stringsdata' -print0 | xargs -0 xcrun xcstringstool sync "$CATALOG" --stringsdata
echo "Pronto: $CATALOG ($(xcrun xcstringstool print "$CATALOG" | wc -l | tr -d ' ') textos)"
