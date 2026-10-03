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
**Try Dictation…** opens a practice text field. The recording overlay names the
language and shows **Listening** or **Processing**. Optional **Recording Feedback
Sounds** in the menu provides start/stop cues and is off by default.
Select **Start RegardingWork Dictate at Login** in the same menu to make the
app available automatically after signing in or restarting. A checkmark shows
that auto-start is enabled. Normal use does not require Terminal.

### English and Thai dictation

Open the waveform menu and choose **Dictation Language → English** or
**Dictation Language → Thai**. The choice is saved for future launches.

English uses the smaller English model by default. Thai automatically uses the
multilingual Whisper Large v3 Turbo model and transcribes Thai speech as Thai
text. The first switch to Thai downloads approximately 1.6 GB of on-device
model data, so preparation can take a few minutes. Audio and transcripts still
remain on the Mac; only the model is downloaded.

### Safer text insertion (next release)

Finish one sentence before starting another. Dictate checks that the original
text field and cursor selection are still selected before sending text. If they
changed, or the field cannot be verified as editable, a recovery window offers
**Copy Text**. That blocked result exists only in memory and clears after 60
seconds, when you close or copy it, or when you start a new dictation. Clipboard
contents may be retained or synced by macOS or other apps. Successful results
are not kept for recovery; apps that silently reject keyboard events still need
manual compatibility testing.

Practice text clears when its window closes. These improvements are in source
for the next release; the published v0.1.4 installer does not include them yet.
See [the improvement roadmap](docs/IMPROVEMENT_ROADMAP.md) for implemented scope,
future work, and acceptance checks.

## Build and run

```sh
swift build -c release
.build/release/regardingwork-dictate --help
.build/release/regardingwork-dictate setup
.build/release/regardingwork-dictate
```

For a local unsigned app bundle:

```sh
VERSION=0.1.4-dev ./scripts/build-app.sh
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
[v0.1.4](https://github.com/shadstoneofficial/regardingwork-dictate/releases/tag/v0.1.4).
Release v0.1.3 remains available for rollback. Release v0.1.0 is retained for
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
./scripts/install.sh 0.1.4
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
  "language": "en",
  "overlay": true,
  "debug_hotkey": false,
  "dump_wav": false,
  "feedback_sounds": false,
  "hotkey": "fn"
}
```

Command-line flags take precedence over matching configuration values.

### Choose a push-to-talk key (next release)

The waveform menu's **Push-to-Talk Key** offers **fn / Globe** (default), or
the left/right Option, Command, Control, and Shift keys. The choice applies
without restarting and is saved for next launch. Setup and practice instructions
show the selected key. This is under review, not included in the v0.1.4 installer.

For external keyboards that do not send Fn to macOS, try **Right Option**.
Hold the key alone for at least 0.3 seconds while speaking, then release.
Short taps and holds with another modifier are cancelled without recognition.
The app observes modifier changes only, not ordinary typed keys; it cannot
detect every shortcut using a letter. Choose a key you do not normally hold
while typing. This is not a fix for unavailable microphones in clamshell mode.

Developers can use `regardingwork-dictate run --hotkey right-option` as an
initial, non-persistent override. An explicit menu choice replaces the override
and saves that choice. Missing `hotkey` values in old configurations use Fn;
invalid names produce a visible configuration error instead of a silent change.

## Verification

```sh
swift build -c release
swift test
.build/release/regardingwork-dictate --help
VERSION=0.1.4-dev ./scripts/build-app.sh
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
