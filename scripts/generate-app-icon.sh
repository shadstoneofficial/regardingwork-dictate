#!/usr/bin/env bash

set -euo pipefail
umask 077

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="${1:-$ROOT/Assets/AppIcon.png}"
OUTPUT="${2:-$ROOT/Packaging/AppIcon.icns}"
WORK_DIR="$(mktemp -d -t regardingwork-dictate-icon)"
ICONSET="$WORK_DIR/AppIcon.iconset"
trap 'rm -rf "$WORK_DIR"' EXIT

test -f "$SOURCE"
test "$(sips -g pixelWidth "$SOURCE" | awk '/pixelWidth/ {print $2}')" = "1024"
test "$(sips -g pixelHeight "$SOURCE" | awk '/pixelHeight/ {print $2}')" = "1024"
test "$(sips -g hasAlpha "$SOURCE" | awk '/hasAlpha/ {print $2}')" = "yes"

mkdir -p "$ICONSET"
sips -z 16 16 "$SOURCE" --out "$ICONSET/icon_16x16.png" >/dev/null
sips -z 32 32 "$SOURCE" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$SOURCE" --out "$ICONSET/icon_32x32.png" >/dev/null
sips -z 64 64 "$SOURCE" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$SOURCE" --out "$ICONSET/icon_128x128.png" >/dev/null
sips -z 256 256 "$SOURCE" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$SOURCE" --out "$ICONSET/icon_256x256.png" >/dev/null
sips -z 512 512 "$SOURCE" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$SOURCE" --out "$ICONSET/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$SOURCE" --out "$ICONSET/icon_512x512@2x.png" >/dev/null

mkdir -p "$(dirname "$OUTPUT")"
iconutil -c icns "$ICONSET" -o "$OUTPUT"
chmod 0644 "$OUTPUT"
test -s "$OUTPUT"
echo "generated app icon: $OUTPUT"
