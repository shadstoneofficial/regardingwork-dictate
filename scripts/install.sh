#!/usr/bin/env bash

set -euo pipefail
umask 077

VERSION="${1:?usage: ./scripts/install.sh VERSION (for example 0.1.0)}"
REPOSITORY="shadstoneofficial/regardingwork-dictate"
ARCH="arm64"
ASSET="regardingwork-dictate-v${VERSION}-macos-${ARCH}.zip"
BASE_URL="https://github.com/${REPOSITORY}/releases/download/v${VERSION}"
INSTALL_ROOT="/Applications"
APP_NAME="RegardingWork Dictate.app"
CLI_PATH="/usr/local/bin/regardingwork-dictate"

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.-]+)?$ ]]; then
    echo "invalid version: $VERSION" >&2
    exit 64
fi
if [ "$(uname -s)" != "Darwin" ]; then
    echo "RegardingWork Dictate is macOS-only." >&2
    exit 1
fi
if [ "$(uname -m)" != "$ARCH" ]; then
    echo "RegardingWork Dictate requires Apple Silicon." >&2
    exit 1
fi
for command in curl ditto shasum codesign spctl defaults unzip; do
    command -v "$command" >/dev/null || {
        echo "missing dependency: $command" >&2
        exit 1
    }
done

TEMP_DIRECTORY="$(mktemp -d -t com.regardingwork.dictate.install)"
trap 'rm -rf "$TEMP_DIRECTORY"' EXIT

curl --fail --location --proto '=https' --tlsv1.2 \
    "$BASE_URL/$ASSET" -o "$TEMP_DIRECTORY/$ASSET"
curl --fail --location --proto '=https' --tlsv1.2 \
    "$BASE_URL/$ASSET.sha256" -o "$TEMP_DIRECTORY/$ASSET.sha256"
if [ "$(wc -l < "$TEMP_DIRECTORY/$ASSET.sha256" | tr -d ' ')" != "1" ]; then
    echo "checksum file must contain exactly one entry" >&2
    exit 1
fi
read -r EXPECTED_DIGEST EXPECTED_NAME < "$TEMP_DIRECTORY/$ASSET.sha256"
if ! [[ "$EXPECTED_DIGEST" =~ ^[0-9A-Fa-f]{64}$ ]] || [ "$EXPECTED_NAME" != "$ASSET" ]; then
    echo "checksum file does not match the expected asset" >&2
    exit 1
fi
printf '%s  %s\n' "$EXPECTED_DIGEST" "$ASSET" > "$TEMP_DIRECTORY/verified.sha256"
(
    cd "$TEMP_DIRECTORY"
    shasum -a 256 -c verified.sha256
)

while IFS= read -r member; do
    case "$member" in
        "$APP_NAME"|"$APP_NAME/"|"$APP_NAME/"*) ;;
        *)
            echo "archive contains an unexpected path: $member" >&2
            exit 1
            ;;
    esac
    case "$member" in
        /*|*"/../"*|../*|*/..) echo "archive contains an unsafe path: $member" >&2; exit 1 ;;
    esac
done < <(unzip -Z1 "$TEMP_DIRECTORY/$ASSET")

ditto -x -k "$TEMP_DIRECTORY/$ASSET" "$TEMP_DIRECTORY/extracted"
APP="$TEMP_DIRECTORY/extracted/$APP_NAME"
test -x "$APP/Contents/MacOS/regardingwork-dictate"
test "$(defaults read "$APP/Contents/Info" CFBundleIdentifier)" = "com.regardingwork.dictate"
codesign --verify --deep --strict --verbose=2 "$APP"
spctl --assess --type execute --verbose=2 "$APP"

SUDO=""
if [ ! -w "$INSTALL_ROOT" ] || [ ! -w "$(dirname "$CLI_PATH")" ]; then
    SUDO="sudo"
fi
if [ -e "$CLI_PATH" ] && [ ! -L "$CLI_PATH" ]; then
    echo "refusing to replace non-symlink: $CLI_PATH" >&2
    exit 1
fi

$SUDO ditto "$APP" "$INSTALL_ROOT/$APP_NAME"
$SUDO mkdir -p "$(dirname "$CLI_PATH")"
$SUDO ln -sfn "$INSTALL_ROOT/$APP_NAME/Contents/MacOS/regardingwork-dictate" "$CLI_PATH"
codesign --verify --deep --strict --verbose=2 "$INSTALL_ROOT/$APP_NAME"
spctl --assess --type execute --verbose=2 "$INSTALL_ROOT/$APP_NAME"

echo "Installed signed and Gatekeeper-accepted app: $INSTALL_ROOT/$APP_NAME"
echo "Run: regardingwork-dictate setup"
