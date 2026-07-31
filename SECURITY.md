# Security

## Reporting

Report vulnerabilities through a
[private GitHub security advisory](https://github.com/shadstoneofficial/regardingwork-dictate/security/advisories/new).
Do not open a public issue containing recordings, transcripts, credentials,
signing material, exploit details, or personal data. Ordinary usage questions
and non-sensitive bug reports belong in GitHub Issues.

## Security posture

- Transcription is on-device.
- Transcript contents are not logged.
- Debug audio is opt-in and stored with restrictive permissions.
- The hotkey event tap observes modifier changes only.
- Distribution installation fails closed unless the SHA-256 checksum, bundle
  identity, code signature, and Gatekeeper assessment all pass.
- The installer never strips quarantine or recommends bypassing Gatekeeper.
- No certificate, private key, notarization credential, model, recording,
  transcript, or machine-specific configuration belongs in Git.

Checksums detect corruption but are not a substitute for code signing. A
release is trusted only after Developer ID signing, Apple notarization,
stapling, Gatekeeper verification, and independent checksum verification.

## Signing and notarization handoff

The preparation workflow builds an unsigned review artifact and does not
publish a release. On the trusted Apple signing machine:

```sh
cd /path/to/regardingwork-dictate
git fetch origin
git switch master
git pull --ff-only
swift test
VERSION=0.1.1 BUILD_NUMBER=1 ./scripts/build-app.sh
./scripts/sign-and-notarize.sh \
  "dist/RegardingWork Dictate.app" \
  "Developer ID Application: ORGANIZATION (TEAMID)" \
  "REGARDINGWORK_NOTARY"
```

The named `notarytool` keychain profile must already exist on the trusted
machine. Never put its credentials in this repository or command history.

After the script reports success, package the stapled app and regenerate the
checksum:

```sh
VERSION=0.1.1
ASSET="dist/regardingwork-dictate-v${VERSION}-macos-arm64.zip"
ditto -c -k --norsrc --keepParent "dist/RegardingWork Dictate.app" "$ASSET"
(cd dist && shasum -a 256 "$(basename "$ASSET")" > "$(basename "$ASSET").sha256")
codesign --verify --deep --strict --verbose=2 "dist/RegardingWork Dictate.app"
xcrun stapler validate "dist/RegardingWork Dictate.app"
spctl --assess --type execute --verbose=2 "dist/RegardingWork Dictate.app"
(cd dist && shasum -a 256 -c "$(basename "$ASSET").sha256")
```

Expected assets are
`regardingwork-dictate-v0.1.1-macos-arm64.zip` and its `.sha256`. Do not tag or
publish them until explicit release approval is given.
