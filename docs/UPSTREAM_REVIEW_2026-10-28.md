# Upstream review — 2026-10-28

## Verified snapshot

- Upstream: [humanitas-labs/parrot](https://github.com/humanitas-labs/parrot).
  The preserved `digimata/parrot` remote redirects there.
- `master`: `0eb470847fa38095f60d727391a5098ee893de58`, unchanged since October 3.
  There are **zero** new commits on that branch.
- `develop`: `f577918537f7ba901417b3f8a43040a62804fae5`, seven commits ahead of
  master, introducing a public engine library and a separate app library.
- Latest upstream release:
  [v0.2.4](https://github.com/humanitas-labs/parrot/releases/tag/v0.2.4), published
  October 12 Bangkok time (October 11 UTC), points to
  `473bdee11c017cac084af24d63381207d7a3437b` on that
  engine-split lineage, not the fetched master tip. “Latest release” does not
  imply “new commits on master.”
- Product release:
  [RegardingWork v0.1.5](https://github.com/shadstoneofficial/regardingwork-dictate/releases/tag/v0.1.5),
  published October 3 from `7e4774e`. PRs #6/#7 are merged; the old roadmap's
  “under review / v0.1.4 latest” descriptions were stale.

The [October 3 review](UPSTREAM_REVIEW_2026-10-03.md) remains historical evidence;
this review supersedes its current-status statements.

## Findings and decisions

1. **Download progress already exists upstream.** `35536e5` explicitly calls
   `WhisperKit.download` to expose progress, then constructs WhisperKit with the
   folder and `download: false`. We adapt this bounded pattern to our existing
   dependency without its model-switching/settings/tuning/update pipeline. Our
   state model rejects stale/nonfinite/regressive callbacks and serializes retry.
2. **Engine extraction is not a drop-in integration.** ADR-006/current `develop`
   expose `ParrotCore` without Sparkle/app UI, but its documented paths,
   dictionary and settings remain upstream-branded/shared. Its dependency and
   public API differ from ours. Adoption requires separate identity/path
   injection, migration, dependency/privacy review, benchmarks and pilot tests.
   No library split or dependency upgrade is imported by this branch.
3. **Review dictionary work before duplicating it.** Editor/Fix Word
   [PR #59](https://github.com/humanitas-labs/parrot/pull/59) remains open.
   Establish a local Thai baseline and replacement rules first. Optional prompt
   handling in the newer Argmax version also needs measurement.
4. **Input-device selection remains open**
   [#44](https://github.com/humanitas-labs/parrot/issues/44), as do clamshell
   [#56](https://github.com/humanitas-labs/parrot/issues/56), Electron AX
   [#60](https://github.com/humanitas-labs/parrot/issues/60) and custom models
   [#63](https://github.com/humanitas-labs/parrot/issues/63). This change does not
   claim to solve them.
5. **Our contribution is pending:** cursor/selection safety
   [PR #61](https://github.com/humanitas-labs/parrot/pull/61) is open/draft and
   unmerged. This check did not change its status or message maintainers.

## Scope, provenance and privacy

No wholesale merge, remote repointing, model download, real recording,
production install, signing or publication is part of this work. Original MIT
licensing, the supplemental Humanitas Labs notice and complete fork history are
preserved. Model paths/provider, dependency versions and explicit English/Thai
selection remain unchanged. No telemetry/server/update-feed/signing identity is
introduced. Progress carries phase and percent only, never audio or transcript
text. Cancellation does not delete partial/cached model files.

## Verification and remaining gates

The branch adds progress-state and AppKit presentation/action tests, alongside
existing build/CLI/bundle checks. Full results are recorded in the product PR
and roadmap. Isolated previews use synthetic model labels only.

Real downloads, cached/offline behavior, permission prompts, physical input,
Thai recognition and cross-app insertion still need manual pilot verification.
Cancellation is cooperative: Stopping remains until the library/Core ML operation
unwinds; no fixed cancellation deadline or byte-level resume is promised.
