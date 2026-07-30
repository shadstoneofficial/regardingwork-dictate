# RegardingWork Dictate architecture

## Product boundary

RegardingWork Dictate is a macOS menu-bar application and CLI. It captures
microphone audio only while the push-to-talk modifier is held, transcribes the
captured buffer locally with WhisperKit/Core ML, and injects the sanitized text
at the active cursor.

It intentionally has no server, telemetry, transcript history, meeting
recording, cloud transcription, or post-processing service.

## Runtime flow

```text
fn down → AudioCapture → in-memory 16 kHz mono PCM → recording overlay
fn up   → WhisperKitTranscriber → TranscriptSanitizer → TextInjector
```

`HotkeyMonitor` installs a listen-only Accessibility event tap for
`flagsChanged` events. It does not subscribe to normal key-down or key-up
events. `AudioCapture` uses `AVAudioEngine`. `RecordingOverlay` and
`MenuBarController` are AppKit/SwiftUI surfaces. `TextInjector` posts Unicode
keyboard events with Core Graphics.

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
configuration parsing/defaults, model selection, and branded paths. Release
build, CLI help, bundle construction, plist validation, shell syntax, and stale
identifier searches are automated separately.

Microphone permission, Accessibility permission, a physical hotkey, overlay
behavior, transcription latency, and cross-application text injection require
manual macOS testing documented in [../PILOT.md](../PILOT.md).
