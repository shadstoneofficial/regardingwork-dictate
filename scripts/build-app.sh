#!/usr/bin/env bash

set -euo pipefail
umask 077

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:-0.1.1-dev}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
ARCH="${ARCH:-arm64}"
DIST="${DIST:-${ROOT}/dist}"
APP="${DIST}/RegardingWork Dictate.app"
BINARY="${ROOT}/.build/${ARCH}-apple-macosx/release/regardingwork-dictate"

if ! [[ "$VERSION" =~ ^[0-9]+(\.[0-9]+){2}([.-][A-Za-z0-9.-]+)?$ ]]; then
    echo "invalid VERSION: ${VERSION}" >&2
    exit 64
fi
if ! [[ "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
    echo "BUILD_NUMBER must contain digits only" >&2
    exit 64
fi

swift build --package-path "$ROOT" -c release --arch "$ARCH"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
install -m 0755 "$BINARY" "$APP/Contents/MacOS/regardingwork-dictate"
install -m 0644 "$ROOT/Packaging/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
sed \
    -e "s/__VERSION__/${VERSION}/g" \
    -e "s/__BUILD_NUMBER__/${BUILD_NUMBER}/g" \
    "$ROOT/Packaging/Info.plist" > "$APP/Contents/Info.plist"
chmod 0644 "$APP/Contents/Info.plist"

plutil -lint "$APP/Contents/Info.plist"
test "$(defaults read "$APP/Contents/Info" CFBundleIdentifier)" = "com.regardingwork.dictate"
test "$(defaults read "$APP/Contents/Info" CFBundleIconFile)" = "AppIcon.icns"
test -s "$APP/Contents/Resources/AppIcon.icns"
file "$APP/Contents/MacOS/regardingwork-dictate"

echo "built unsigned app: $APP"
echo "Developer ID signing and notarization are required before distribution."
