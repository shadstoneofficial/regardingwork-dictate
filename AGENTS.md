# Repository conventions

- Preserve `LICENSE`, complete Git history, tags, and the `upstream` remote.
- Keep runtime identity centralized in `AppIdentity`.
- Never log or persist transcript text. Debug audio must remain opt-in, private,
  temporary, and uncommitted.
- Add no cloud transcription, telemetry, Railway, or server dependency.
- Do not commit models, recordings, transcripts, certificates, secrets,
  notarization files, `dist/`, or machine-specific configuration.
- Do not strip quarantine, bypass Gatekeeper, publish releases, or merge the
  default branch without explicit approval.
- Work on `agent/*` branches and keep commits reviewable.

Verify every functional change:

```sh
swift build -c release
swift test
.build/release/regardingwork-dictate --help
VERSION=0.1.0-dev ./scripts/build-app.sh
rg -n -i 'parrot|digimata|com\.digimata\.parrot' \
  Sources Tests Packaging scripts .github README.md docs AGENTS.md
git status --short
```

Document microphone, hotkey, Accessibility, overlay, and text-injection checks
as manual macOS verification.
