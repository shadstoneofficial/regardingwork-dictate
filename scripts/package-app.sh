#!/usr/bin/env bash

set -euo pipefail
umask 077

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:?set VERSION, for example VERSION=0.1.0}"
ARCH="${ARCH:-arm64}"
DIST="${DIST:-${ROOT}/dist}"
APP="${DIST}/RegardingWork Dictate.app"
ASSET="regardingwork-dictate-v${VERSION}-macos-${ARCH}.zip"

VERSION="$VERSION" ARCH="$ARCH" DIST="$DIST" "$ROOT/scripts/build-app.sh"

rm -f "$DIST/$ASSET" "$DIST/$ASSET.sha256"
ditto -c -k --norsrc --keepParent "$APP" "$DIST/$ASSET"
(
    cd "$DIST"
    shasum -a 256 "$ASSET" > "$ASSET.sha256"
    shasum -a 256 -c "$ASSET.sha256"
)

echo "packaged unsigned review artifacts:"
echo "  $DIST/$ASSET"
echo "  $DIST/$ASSET.sha256"
