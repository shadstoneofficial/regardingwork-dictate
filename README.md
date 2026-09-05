# RegardingWork Dictate

RegardingWork Dictate is a private, on-device macOS push-to-talk dictation app
in the RegardingWork Voice product family. Hold `fn`, speak, and release to
insert the transcript at the active cursor.

Audio and transcription stay on the Mac. The app has no telemetry, server,
Railway service, transcript history, or cloud transcription provider. Network
access is used only to download build dependencies and the selected WhisperKit
model. See [PRIVACY.md](PRIVACY.md) and [SECURITY.md](SECURITY.md).

## Requirements

- macOS 14 or later
- Apple Silicon
- Microphone and Accessibility permission
- Swift 5.9 or later for source builds

## Use the Mac app

1. Move `RegardingWork Dictate.app` to `/Applications`.
2. Double-click it.
3. Follow the visible setup window to grant microphone and Accessibility
   permission and prepare the on-device model.
4. When the app says it is ready, click into any text field, hold `fn`, speak,
   and release.

The waveform icon in the menu bar confirms the app is running. Its
**Setup & Diagnostics…** menu item reopens setup or displays any startup error.
Select **Start RegardingWork Dictate at Login** in the same menu to make the
app available automatically after signing in or restarting. A checkmark shows
that auto-start is enabled. Normal use does not require Terminal.

## Build and run

```sh
swift build -c release
.build/release/regardingwork-dictate --help
.build/release/regardingwork-dictate setup
.build/release/regardingwork-dictate
```

For a local unsigned app bundle:

```sh
VERSION=0.1.2-dev ./scripts/build-app.sh
open "dist/RegardingWork Dictate.app"
```

The Finder and application icon is generated from `Assets/AppIcon.png`. To
regenerate the bundled macOS icon after changing the source artwork:

```sh
./scripts/generate-app-icon.sh
```

Unsigned development bundles are for testing only. Do not strip quarantine or
bypass Gatekeeper. Distribution requires Developer ID signing, notarization,
stapling, and the verification gates in [SECURITY.md](SECURITY.md).

## Install the signed release

The current supported pilot release is
[v0.1.2](https://github.com/shadstoneofficial/regardingwork-dictate/releases/tag/v0.1.2).
Release v0.1.1 remains available for rollback. Release v0.1.0 is retained for
history but is superseded because it could launch without showing visible setup
or recovery state.

For normal manual installation, download the signed and notarized DMG, open it,
and drag **RegardingWork Dictate.app** to Applications. The ZIP remains
available for the verified installer script and automation.

Download and inspect `scripts/install.sh`; never pipe a remote script into a
shell. The installer downloads a versioned app archive and its checksum,
verifies SHA-256, the bundle identifier, code signature, and Gatekeeper
acceptance, then installs the app:

```sh
./scripts/install.sh 0.1.2
```

Only install assets attached to an approved GitHub release. The repository's
GitHub Actions workflow produces an unsigned signing-handoff artifact; it
cannot publish a release or access production Apple credentials.

## CLI

```text
regardingwork-dictate
regardingwork-dictate setup
regardingwork-dictate doctor
regardingwork-dictate models list
regardingwork-dictate models download whisper-base.en
regardingwork-dictate run --model whisper-large-v3-turbo
regardingwork-dictate run --no-overlay
regardingwork-dictate run --dump-wav
regardingwork-dictate install --launch-at-login
regardingwork-dictate install --uninstall
```

`--dump-wav` is strictly opt-in. It writes one private temporary debugging file
at `.../com.regardingwork.dictate/last-capture.wav`. Transcript text is never
written to stdout, stderr, or application logs.

The CLI remains available for development and diagnostics. Configuration
defaults to:

```text
~/Library/Application Support/RegardingWork Dictate/config.json
```

Example:

```json
{
  "version": 1,
  "model": "whisper-base.en",
  "overlay": true,
  "debug_hotkey": false,
  "dump_wav": false
}
```

Command-line flags take precedence over matching configuration values.

## Verification

```sh
swift build -c release
swift test
.build/release/regardingwork-dictate --help
VERSION=0.1.2-dev ./scripts/build-app.sh
```

Manual microphone, hotkey, Accessibility, overlay, and text-injection checks
are documented in [PILOT.md](PILOT.md).

## Origin and license

This repository preserves the complete history of the MIT-licensed
[Digimata Parrot project](https://github.com/digimata/parrot). The original
license and copyright remain unchanged in [LICENSE](LICENSE). See
[UPSTREAM.md](UPSTREAM.md) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)
for attribution and dependency notices.

## Community

- Read [CONTRIBUTING.md](CONTRIBUTING.md) before proposing a change.
- Use [SUPPORT.md](SUPPORT.md) for help and bug-report guidance.
- Report vulnerabilities privately as described in
  [SECURITY.md](SECURITY.md).
- See [TRADEMARKS.md](TRADEMARKS.md) before using RegardingWork names or
  branding in a redistributed build.
