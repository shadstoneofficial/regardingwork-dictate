#!/usr/bin/env bash

set -euo pipefail
umask 077

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="${1:?usage: sign-and-notarize.sh APP_PATH DEVELOPER_IDENTITY NOTARY_PROFILE}"
IDENTITY="${2:?usage: sign-and-notarize.sh APP_PATH DEVELOPER_IDENTITY NOTARY_PROFILE}"
NOTARY_PROFILE="${3:?usage: sign-and-notarize.sh APP_PATH DEVELOPER_IDENTITY NOTARY_PROFILE}"
APP="$(cd "$(dirname "$APP")" && pwd)/$(basename "$APP")"

test -d "$APP"
test -x "$APP/Contents/MacOS/regardingwork-dictate"
test "$(defaults read "$APP/Contents/Info" CFBundleIdentifier)" = "com.regardingwork.dictate"

codesign --force --options runtime --timestamp \
    --entitlements "$ROOT/Packaging/RegardingWorkDictate.entitlements" \
    --sign "$IDENTITY" "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"

SUBMISSION_ZIP="$(mktemp -t regardingwork-dictate-notary).zip"
SUBMISSION_JSON="$(mktemp -t regardingwork-dictate-submit).json"
INFO_JSON="$(mktemp -t regardingwork-dictate-info).json"
trap 'rm -f "$SUBMISSION_ZIP" "$SUBMISSION_JSON" "$INFO_JSON"' EXIT
ditto -c -k --norsrc --keepParent "$APP" "$SUBMISSION_ZIP"

xcrun notarytool submit "$SUBMISSION_ZIP" \
    --keychain-profile "$NOTARY_PROFILE" \
    --output-format json > "$SUBMISSION_JSON"
SUBMISSION_ID="$(plutil -extract id raw -o - "$SUBMISSION_JSON")"
echo "notarization submission: $SUBMISSION_ID"

STATUS="In Progress"
for _ in $(seq 1 40); do
    xcrun notarytool info "$SUBMISSION_ID" \
        --keychain-profile "$NOTARY_PROFILE" \
        --output-format json > "$INFO_JSON"
    STATUS="$(plutil -extract status raw -o - "$INFO_JSON")"
    case "$STATUS" in
        Accepted) break ;;
        Invalid|Rejected)
            xcrun notarytool log "$SUBMISSION_ID" --keychain-profile "$NOTARY_PROFILE"
            exit 1
            ;;
    esac
    sleep 15
done

if [ "$STATUS" != "Accepted" ]; then
    echo "notarization did not complete within 10 minutes; submission: $SUBMISSION_ID" >&2
    exit 1
fi

xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"
spctl --assess --type execute --verbose=2 "$APP"
echo "signed, notarized, stapled, and Gatekeeper-accepted: $APP"
