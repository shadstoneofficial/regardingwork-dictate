# Contributing

Thanks for helping improve RegardingWork Dictate.

## Before starting

- Search existing issues and pull requests before opening a duplicate.
- Open an issue before beginning a large feature or behavior change.
- Keep cloud transcription, telemetry, accounts, meeting capture, and server
  dependencies out of scope.
- Never attach real recordings, transcripts, credentials, models, signing
  material, or machine-specific configuration.
- Report security problems privately through the process in
  [SECURITY.md](SECURITY.md).

## Development

Create a focused branch from `master` and keep commits reviewable. Preserve the
original MIT license, copyright, upstream history, and attribution.

Run the automated checks before opening a pull request:

```sh
swift build -c release
swift test
.build/release/regardingwork-dictate --help
VERSION=0.1.1-dev ./scripts/build-app.sh
```

Also inspect the diff for stale runtime branding:

```sh
rg -n -i 'parrot|digimata|com\.digimata\.parrot' \
  Sources Tests Packaging scripts .github README.md docs AGENTS.md
```

Original names may remain only for licensing, copyright, attribution,
migration notes, or upstream-development documentation.

## Pull requests

Explain what changed, why it changed, how it was verified, and which manual
macOS checks remain. Code that touches microphone capture, Accessibility,
hotkeys, text injection, logging, debug files, signing, or installation should
include a focused security and privacy review.

By contributing, you agree that your contribution may be distributed under
the repository's MIT license.
