# Changelog

All notable RegardingWork Dictate changes are documented here. The project
follows semantic versioning.

## Unreleased

No user-facing changes yet.

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
