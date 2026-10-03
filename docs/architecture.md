# RegardingWork Dictate architecture

## Product boundary

RegardingWork Dictate is a macOS menu-bar application and CLI. It captures
microphone audio only while the push-to-talk modifier is held, transcribes the
captured buffer locally with WhisperKit/Core ML, and injects the sanitized text
at the original focused field after verifying its identity and selection.

It intentionally has no server, telemetry, transcript history, meeting
recording, cloud transcription, or post-processing service.

## Runtime flow

```text
hotkey down → destination snapshot → AudioCapture → in-memory PCM → Listening overlay
hotkey up   → gesture/signal assessment → WhisperKitTranscriber → TranscriptSanitizer
              → original destination unchanged/editable → TextInjector
              → destination blocked/changed → temporary recovery → explicit Copy
```

`HotkeyMonitor` installs a listen-only Accessibility event tap for
`flagsChanged` events. It does not subscribe to normal key-down or key-up
events. `AudioCapture` uses `AVAudioEngine`. `RecordingOverlay` and
`MenuBarController` are AppKit/SwiftUI surfaces. `TextInjector` posts Unicode
keyboard events with Core Graphics.

`HotkeyKey` identifies Fn or a side-specific Option/Command/Control/Shift key.
`Gesture` cancels sub-0.3-second taps and modifier chords without transcribing.
The menu saves the selected key in `AppConfig`; CLI can override the initial
selection without saving. Key changes are disabled during a recording or
transcription. Modifier-only monitoring cannot inspect letter shortcuts.

`DictationSession` accepts one recording/transcription at a time and rejects
stale completions. `TextDestination` reads Accessibility identity, editability,
and selection metadata, never existing field contents. A blocked result uses
`PendingDictation` and `RecoveryWindowController` for a maximum of 60 seconds in
memory; it clears on copy, close, expiry, another recording, language change, or
quit. Successful results are not cached. Keyboard-event posting cannot prove
that another app accepted the text.

`PracticeWindowController` provides a local editable field for the same runtime
path; closing it clears practice text. Optional start/stop sounds use system
sounds and are off by default. The overlay remains nonactivating and
click-through so it does not take the destination's focus.

The default model is selected from `ModelRegistry`. `AppConfig` can override
the model and privacy-safe UI/debug defaults. Command-line options take
precedence over stored configuration.

## Identity and paths

`AppIdentity` is the source of truth:

- executable: `regardingwork-dictate`
- Swift module/target: `RegardingWorkDictate`
- bundle and LaunchAgent: `com.regardingwork.dictate`
- application support:
  `~/Library/Application Support/RegardingWork Dictate/`
- logs: `~/Library/Logs/RegardingWork Dictate/`
- temporary debug audio: a `com.regardingwork.dictate` subdirectory of the
  macOS temporary directory

Transcript text is never logged. LaunchAgent and debug files use a `0077` umask
or explicit `0600` permissions, with private directories at `0700`.

## Application bundle and permissions

`scripts/build-app.sh` places the release executable in:

```text
RegardingWork Dictate.app/
  Contents/
    Info.plist
    MacOS/regardingwork-dictate
    Resources/
```

The `LSUIElement` app has no Dock icon. Its Info.plist carries the stable bundle
identifier and microphone purpose string. Developer ID signing with hardened
runtime plus notarization and stapling provide a stable TCC/Gatekeeper identity.
Accessibility has no purpose-string key; the user grants it in System Settings.

Development terminal launches may receive permissions under the terminal host
instead. Pilot and release testing must use the installed, signed app at a
stable path.

## Distribution boundary

The GitHub workflow is manual and produces an unsigned, checksummed handoff
artifact. It does not use Apple credentials, create tags, or publish releases.
An authorized operator signs and notarizes on the trusted signing machine,
repackages the stapled app, regenerates the checksum, and runs all verification
gates in [../SECURITY.md](../SECURITY.md).

The installer accepts only a versioned archive whose checksum, bundle
identifier, code signature, and Gatekeeper assessment pass. It never removes
quarantine.

## Testing boundary

Swift tests cover platform-independent behavior: transcript sanitization,
configuration parsing/defaults, model selection, branded paths, session guards,
destination changes, audio signal checks, recovery expiry, and Unicode event
chunking. AppKit tests also check practice/recovery actions and clearing. Release
build, CLI help, bundle construction, plist validation, shell syntax, and stale
identifier searches are automated separately.

Microphone permission, Accessibility permission, a physical hotkey, overlay
behavior, transcription latency, and cross-application text injection require
manual macOS testing documented in [../PILOT.md](../PILOT.md).
