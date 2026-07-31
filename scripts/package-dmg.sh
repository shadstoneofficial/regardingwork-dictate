#!/usr/bin/env bash

set -euo pipefail
umask 077

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:?set VERSION, for example VERSION=0.1.2}"
ARCH="${ARCH:-arm64}"
DIST="${DIST:-${ROOT}/dist}"
APP="${APP:-${DIST}/RegardingWork Dictate.app}"
VOLUME_NAME="${VOLUME_NAME:-RegardingWork Dictate}"
ASSET="regardingwork-dictate-v${VERSION}-macos-${ARCH}.dmg"
DMG="${DIST}/${ASSET}"
STAGING="$(mktemp -d -t regardingwork-dictate-dmg)"

cleanup() {
    hdiutil detach "${STAGING}/mount" -quiet >/dev/null 2>&1 || true
    rm -rf "$STAGING"
}
trap cleanup EXIT

test -d "$APP"
test -x "$APP/Contents/MacOS/regardingwork-dictate"
test "$(defaults read "$APP/Contents/Info" CFBundleIdentifier)" = "com.regardingwork.dictate"
test "$(defaults read "$APP/Contents/Info" CFBundleShortVersionString)" = "$VERSION"
test "$(defaults read "$APP/Contents/Info" CFBundleIconFile)" = "AppIcon.icns"
test -s "$APP/Contents/Resources/AppIcon.icns"

mkdir -p "$STAGING/source"
ditto "$APP" "$STAGING/source/RegardingWork Dictate.app"
ln -s /Applications "$STAGING/source/Applications"

rm -f "$DMG" "$DMG.sha256"
hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGING/source" \
    -ov \
    -format UDZO \
    "$DMG"

if [ -n "${SIGNING_IDENTITY:-}" ]; then
    codesign --force --timestamp --sign "$SIGNING_IDENTITY" "$DMG"
    codesign --verify --verbose=2 "$DMG"
fi

hdiutil verify "$DMG"

echo "packaged DMG: $DMG"
