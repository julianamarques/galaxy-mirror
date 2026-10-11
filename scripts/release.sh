#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-}"
DRY_RUN="${DRY_RUN:-0}"
PLIST="Resources/Info.plist"
DMG="build/Galaxy-Mirror.dmg"
TAG="v$VERSION"

fail() { echo "Erro: $1" >&2; exit 1; }

[[ "$VERSION" =~ ^([0-9]+\.[0-9]+\.[0-9]+)(-(alpha|beta|rc)\.[0-9]+)?$ ]] || fail "informe a versão como X.Y.Z ou X.Y.Z-beta.N (ex.: ./scripts/release.sh 0.2.0-beta.1)"
APP_VERSION="${BASH_REMATCH[1]}"
STAGE="${BASH_REMATCH[3]}"
command -v gh >/dev/null || fail "instale o GitHub CLI: brew install gh"
gh auth status >/dev/null 2>&1 || fail "faça login no GitHub: gh auth login"
[ -z "$(git status --porcelain)" ] || fail "há alterações não commitadas"
[ "$(git branch --show-current)" = "main" ] || fail "o release deve ser feito a partir do main"
git fetch -q origin main --tags
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || fail "o main local está diferente do origin/main"
! git rev-parse -q --verify "refs/tags/$TAG" >/dev/null || fail "a tag $TAG já existe"

PREVIOUS="$(git describe --tags --abbrev=0 2>/dev/null || true)"
BUILD=$(( $(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST") + 1 ))
CHANGES="$(git log ${PREVIOUS:+$PREVIOUS..}HEAD --pretty='- %s' --no-merges)"
NOTICE=""
if [ -n "$STAGE" ]; then
    NOTICE="> **$STAGE release.** This is a test version and may have bugs. If you find one, open an issue with the phone model, the Android and macOS versions and what happened.
"
fi
NOTES="$(cat <<NOTES
$NOTICE
## Installation

Download \`Galaxy-Mirror.dmg\`, open it and drag **Galaxy Mirror** to **Applications**. Requires macOS 14 or later. If macOS blocks the first launch, allow it in **System Settings › Privacy & Security › Open Anyway**.

## Changes

$CHANGES
NOTES
)"

echo "Release $TAG (app $APP_VERSION, build $BUILD)${STAGE:+, pré-lançamento}${PREVIOUS:+ desde $PREVIOUS}"
if [ "$DRY_RUN" = "1" ]; then
    echo "$NOTES"
    echo "(ensaio: nada foi alterado)"
    exit 0
fi

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $APP_VERSION" -c "Set :CFBundleVersion $BUILD" -c "Set :GalaxyMirrorReleaseVersion $VERSION" "$PLIST"
git commit -q -m "chore: release $TAG" "$PLIST"
git push -q origin main

./scripts/make-dmg.sh
cp "build/Galaxy Mirror.dmg" "$DMG"

gh release create "$TAG" "$DMG" --target main --title "Galaxy Mirror $VERSION" --notes "$NOTES" ${STAGE:+--prerelease}
