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

## Build and run

```sh
swift build -c release
.build/release/regardingwork-dictate --help
.build/release/regardingwork-dictate setup
.build/release/regardingwork-dictate
```

For a local unsigned app bundle:

```sh
VERSION=0.1.0-dev ./scripts/build-app.sh
open "dist/RegardingWork Dictate.app"
```

Unsigned development bundles are for testing only. Do not strip quarantine or
bypass Gatekeeper. Distribution requires Developer ID signing, notarization,
stapling, and the verification gates in [SECURITY.md](SECURITY.md).

## Install a signed release

Download and inspect `scripts/install.sh`; do not pipe a remote script into a
shell. The installer downloads a versioned app archive and its checksum,
verifies SHA-256, the bundle identifier, code signature, and Gatekeeper
acceptance, then installs the app.

```sh
./scripts/install.sh 0.1.0
regardingwork-dictate setup
regardingwork-dictate install --launch-at-login
```

No release is published by this repository's preparation workflow. The command
above becomes usable only after an explicitly approved, signed release exists.

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
written to stdout, stderr, or LaunchAgent logs.

Configuration defaults to:

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
VERSION=0.1.0-dev ./scripts/build-app.sh
```

Manual microphone, hotkey, Accessibility, overlay, and text-injection checks
are documented in [PILOT.md](PILOT.md).

## Origin and license

This repository preserves the complete history of the MIT-licensed
[Digimata Parrot project](https://github.com/digimata/parrot). The original
license and copyright remain unchanged in [LICENSE](LICENSE). See
[UPSTREAM.md](UPSTREAM.md) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)
for attribution and dependency notices.
