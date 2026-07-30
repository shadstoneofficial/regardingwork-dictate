# Changelog

All notable RegardingWork Dictate changes are documented here. The project
follows semantic versioning once releases begin.

## Unreleased

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
