# RegardingWork Dictate improvement roadmap

Updated: **2026-10-28**. This is the working backlog and release-gate checklist.
Latest published release verified on GitHub:
[v0.1.5](https://github.com/shadstoneofficial/regardingwork-dictate/releases/tag/v0.1.5),
published 2026-10-03 from `7e4774e`. Published release metadata does not establish
that every hardware/manual case below has been tested.

## Completed and included in v0.1.5

- Language-labelled Listening/Processing feedback and opt-in recording sounds.
- Built-in practice field; practice text clears on close.
- Single-session dictation, stale-completion protection and Unicode event chunks.
- Original app/field/selection checks and explicit, memory-only recovery for
  blocked insertion. Recovery expires after 60 seconds and never becomes history.
- Configurable Fn or side-specific Option/Command/Control/Shift push-to-talk keys,
  short-tap/chord cancellation, saved selection and matching instructions.

These changes were merged through PRs #6 and #7. They are no longer awaiting
merge. English/Thai selection and Start at Login shipped in earlier versions.

## Active work: model preparation progress and control

Implemented for review on `agent/model-preparation-progress`; **not in the
published v0.1.5 installer**:

- Show real, whole-percentage model-file download progress in setup and the menu.
- Keep unknown progress indeterminate instead of inventing a percentage.
- Show a separate loading phase after transfer. Downloaded 100% does not mean
  Core ML has loaded/compiled the model or that dictation is ready.
- Ignore duplicate, backward, invalid and late progress callbacks.
- Offer Cancel, an honest stopping state, and Try Again once the old operation
  finishes. Some model operations cannot stop immediately; no overlapping retry
  starts while they unwind. Late events cannot update a later attempt.
- Keep cached files, existing model selection, explicit English/Thai decoding,
  private paths and dependency versions. Progress updates do not reopen or
  activate a closed setup window. No audio is recorded during preparation.

Adapted from upstream's existing explicit-download progress pattern (`35536e5`),
with product-specific cancellation and progress guards. No automatic retries,
ETA, guaranteed byte-level resume, microphone selector or recognition-accuracy
improvement is claimed by this change.

## Remaining work, in priority order

| Priority | Work item | Acceptance before shipping |
| --- | --- | --- |
| 1 | Model preparation pilot | Exercise interrupted transfer, failure/retry, cancellation during transfer and loading, reopening setup, cold/cache-hit startup and cached offline startup. Verify no late event changes a ready app. |
| 2 | Thai accuracy baseline and local vocabulary | Use Snook's consented, non-sensitive Thai names, numbers, terms and mixed-language examples locally. Measure the baseline before choosing dictionary replacement or optional prompts. Never commit or upload her speech/text. |
| 3 | Microphone selection and diagnostics | Choose and remember a stable device UID; distinguish missing/unavailable input from low signal. Test USB/Bluetooth route changes, unplug/replug and closed-lid use. Never silently switch microphones contrary to the selected policy. |
| 4 | Local vocabulary implementation | Review upstream's dictionary engine and open editor PR #59 first. Specify Thai/English matching, replacement boundaries, invalid-file handling, private storage and removal. Ship measured improvements, not an untested accuracy promise. |
| 5 | Verified in-app update checks | Use our own signed update feed and key, explicit network/privacy disclosure, dependency/license review, bundle/signature/integrity verification and rollback tests. Never import upstream's production updater identity or feed. |
| 6 | Optional toggle recording | Separate safety design: visible recording state, hard duration cap, cancellation, sleep/permission/device-change recovery, no accidental persistent recording. Hold-to-talk remains the default. |

Microphone selection, vocabulary and updater work are not implemented by the
current branch. Automatic language detection and wholesale engine integration
also remain separate decisions; explicit Thai/English stays unchanged.

## Upstream decisions

See [the 2026-10-28 upstream review](UPSTREAM_REVIEW_2026-10-28.md).
Upstream's default branch is unchanged since our earlier review, but the new
v0.2.4 tag and `develop` contain an engine/app library split. Directly linking it
would currently share upstream-branded paths/settings and needs a dedicated
identity/privacy/configuration review. We have not imported it or upgraded
WhisperKit. Our upstream contribution PR #61 is still open/draft as of this review.

## Verification and release gates

Automated tests cover progress normalization/coalescing, phase ordering,
cancel/finish/retry and stale IDs, UI actions, determinate versus loading state,
closed-window behavior, and the existing dictation/configuration/privacy logic.

Verified on 2026-10-28: **70 tests passed**, release build and root/run CLI help
passed, and an unsigned arm64 `0.1.6-dev` app bundle built successfully. No real
model download, microphone access, signing or production installation was used
for these checks. AppKit assertions cover values, layout width and actions;
bitmap previews did not reliably capture native control layers and are not
accepted as visual validation. Live visual inspection remains a pilot check.

```sh
swift test
swift build -c release
.build/release/regardingwork-dictate --help
.build/release/regardingwork-dictate run --help
VERSION=0.1.6-dev DIST=/absolute/path/to/a/new/review-directory ./scripts/build-app.sh
git diff --check
```

Before distribution, complete [PILOT.md](../PILOT.md), including the new model
preparation cases, physical hotkeys/microphones, permissions, Thai speech,
external apps, secure fields, recovery, sleep/wake and login-item persistence.
Automated tests and isolated UI previews do not validate actual downloads,
Core ML cancellation, microphone capture or recognition accuracy.

After approved merge, rebuild from the final default-branch commit and use a
fresh Developer ID signed, notarized and stapled DMG/ZIP with verified checksums.
Do not silently move published tags or publish a release as part of feature work.
Keep v0.1.5 available for rollback; never commit models, recordings, transcripts,
signing material or generated artifacts.
