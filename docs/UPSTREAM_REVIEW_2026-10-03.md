# Upstream review — 2026-10-03

## Snapshot and scope

- Original upstream `digimata/parrot` now redirects to
  [humanitas-labs/parrot](https://github.com/humanitas-labs/parrot).
- Reviewed default-branch tip: `0eb4708`; latest published release: v0.2.3.
- There are 123 upstream commits since our preserved fork point `62f8d98`.
- No wholesale merge, default-branch merge, production install or release is
  authorized by this integration work. Product PRs remain drafts for review.
- `agent/upstream-hotkeys` is stacked on `agent/dictation-confidence` (PR #6),
  so it preserves that branch's single-session, focus-safety and recovery work.

## Adopted in this review

Adapted upstream `a67e7f3`'s side-specific modifier choices, matching by keycode,
and pure short-tap/chord gesture filtering. The app menu saves a `hotkey`
preference in the existing private configuration; missing values default to Fn.
Instructions follow the selected key and CLI offers a non-persistent initial
override. Our adaptation counts Fn as another modifier when a different key is
selected and rejects invalid preference names. It retains our identity, model
selection, launch-at-login, configuration paths and privacy policy.

The event tap remains listen-only and modifier-only. No ordinary characters,
passwords, recordings or transcripts are added to logs or persistent storage.
No dependency versions, signing credentials, release workflow, update feed,
server, telemetry or installer defaults change. Original MIT licensing remains
untouched; the current upstream Humanitas Labs MIT notice is also preserved and
bundled with the app.

## Deferred, not silently imported

| Upstream capability | Follow-up needed |
| --- | --- |
| Local dictionary and vocabulary prompts | Upstream uses the newer Argmax package; benchmark Thai/English examples and review migration/config storage. Check existing dictionary PR #59 before duplicating editor work. |
| Automatic multilingual detection | Keep explicit Thai/English selection for now; evaluate accuracy and latency before expanding language behavior. |
| Sparkle updates | Requires our own feed and signing key, dependency notices, artifact verification, network disclosure and signing-agent/release review. Never point our app at Parrot's feed. |
| HAL audio capture, benchmarks and trimming | Measure before replacing AVAudioEngine; test device changes and quiet Thai speech. |
| Microphone selection | Still an open upstream feature request (#44); do not describe it as completed. |
| Toggle recording | Not adopted. Upstream intentionally uses hold-to-talk; our toggle needs its own bounded-recording safety design. |

## Contribution back

The first upstream contribution is deliberately limited to cursor/selection
drift within the same focused field. Upstream already detects app/field changes,
but a moved cursor or changed selection previously remained eligible for
insertion. Snapshot capture now also reads selected-range metadata, not field
text, and secure fields skip that query. When both ranges are known and differ,
the existing upstream clipboard fallback applies. Unknown ranges retain its
existing compatibility policy. Edits that leave the same range are not detected.

This patch is based directly on upstream, not our branded branch. It contains
no RegardingWork runtime strings, unrelated privacy policy changes, product
packaging, signing material, recordings, models or user transcripts. A dedicated
contribution fork is used because our product repository is not a GitHub-network
fork. The memory-only recovery UI is a later maintainer discussion, not part of
this small fix.

## Verification

- RegardingWork: `swift test --jobs 2` passed 58 tests; release build and root/run
  CLI help passed. Unsigned arm64 app-bundle packaging also passed, including
  the stable bundle ID, icon and both bundled MIT notices. No production
  credentials are used.
- Upstream: 247 tests passed (five new regression cases); release build and
  root/run CLI help passed. An initial disk-space failure was resolved by a
  clean rebuild/retry in the isolated contribution checkout.
- Both diffs pass whitespace checks. No dependency pins or original licenses
  changed, and new commits use GitHub's noreply author address.
- Upstream draft: [cursor/selection safety PR #61](https://github.com/humanitas-labs/parrot/pull/61),
  contributed via `shadstoneofficial/parrot-upstream-contributions`, not our
  product repository.

Physical microphone/key operation, cross-application Accessibility, real Thai
speech, disconnect/reconnect, sleep/wake and closed-lid testing remain manual
pilot gates. Upstream issues #56 (clamshell) and #60 (Electron Accessibility)
remain open; this work does not claim to solve either.

Signed/notarized distribution requires a new reviewed release after merges and
manual pilot checks. The supported installer remains RegardingWork v0.1.4.
