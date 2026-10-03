# Changelog

All notable RegardingWork Dictate changes are documented here. The project
follows semantic versioning.

## Unreleased

### Added

- Adapt selected upstream modifier-key/gesture improvements: configurable
  left/right Option, Command, Control and Shift push-to-talk keys, short-tap and
  modifier-chord cancellation, saved menu preferences, selected-key instructions
  and an initial CLI override. Fn remains the default.
- Document the upstream transfer, selective integration/contribution process,
  deferred capabilities and manual acceptance checks. Preserve and bundle both
  the original and additional upstream MIT notices without changing `LICENSE`.

- Language-labelled Listening/Processing overlay and menu-bar feedback.
- Optional recording start/stop sounds, off by default and saved locally.
- Built-in practice text field from setup and the waveform menu.
- Visible notices for very brief captures, very low audio signal, and empty
  recognition results.
- A 60-second, memory-only recovery window for text that cannot be safely sent
  to its original field; copying is explicit.
- Improvement roadmap covering the agreed next-release scope and later work.

### Fixed

- Overlapping Fn interactions cannot start multiple transcription sessions.
- Changed applications, fields, or cursor selections block automatic insertion.
- Cancelled or stale session completions cannot insert text.
- Emoji surrogate pairs are kept together across keyboard-event chunks.

### Privacy

- Recovery and practice text never create disk history or transcript logs.
- Recovery clears on expiry, close, copy, next recording, language change, or
  quit. Clipboard retention after an explicit copy is outside the app's control.

## 0.1.4 - 2026-10-02

### Added

- Persistent **English / Thai** dictation selector in the waveform menu.
- Explicit Thai decoding through the on-device multilingual Whisper model,
  including secure configuration persistence and Thai Unicode tests.

## 0.1.3 - 2026-09-07

### Added

- Visible **Start RegardingWork Dictate at Login** checkbox in the waveform
  menu, backed by macOS's native login-item service.
- Automatic migration away from the app's obsolete per-user LaunchAgent file
  when the native login item is enabled or disabled.

## 0.1.2 - 2026-07-31

### Added

- Custom RegardingWork Dictate application icon for Finder, Applications, and
  packaged macOS app bundles.
- Reproducible icon-generation script for the committed 1024-pixel source
  artwork and multi-resolution `.icns` asset.
- Signed DMG packaging path for user-friendly manual installation, alongside
  the existing installer-compatible ZIP archive.

## 0.1.1 - 2026-07-30

### Added

- Visible first-launch and recovery window for permissions, on-device model
  preparation, readiness, and startup failures.
- Menu-bar **Setup & Diagnostics…** action available from the beginning of
  startup.

### Changed

- AppKit and the menu-bar item now start before permissions and model loading,
  so Finder launches always produce visible state.
- The Fn/Globe system action is advisory at runtime instead of terminating the
  application.
- Reopening the app brings setup or current diagnostics forward.

### Fixed

- Finder launches no longer appear to do nothing while permissions or the
  on-device model are being prepared.

## 0.1.0 - 2026-07-30

### Added

- Proper macOS application bundle with stable bundle and permission identity.
- Developer ID signing and notarization handoff scripts.
- Configuration, identity, path, model-selection, and transcript-sanitization
  tests.
- Privacy, security, pilot, upstream, and third-party documentation.

### Changed

- Rebranded the package, executable, UI, paths, LaunchAgent, installer, and
  artifact names for RegardingWork Dictate / RegardingWork Voice.
- Release automation now prepares an unsigned review artifact only and never
  creates a release.
- Installer requires checksum, signature, bundle-identity, and Gatekeeper
  verification.

### Security

- Dictated transcript content is no longer logged.
- Audio dumping remains opt-in and uses restrictive file permissions.
- LaunchAgent logs moved out of a shared temporary directory.
- Hotkey monitoring observes modifier-state changes only.
- Removed quarantine-stripping and remote `curl | sh` guidance.
