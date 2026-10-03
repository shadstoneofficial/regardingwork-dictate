# RegardingWork Dictate improvement roadmap

Updated: 2026-10-03. Current published release: v0.1.4. This document records the
agreed priorities, implementation scope, and verification needed before the
next signed release.

## Next release: everyday confidence

Users should know when Dictate is listening, have an easy way to practice, and
avoid losing a sentence or sending it into the wrong application. The following
three priorities are implemented on `agent/dictation-confidence` for review.
They are not yet in a published installer.

### 1. Clear recording feedback

- The overlay says **Listening — English/Thai**, then **Processing —
  English/Thai**, alongside the waveform or spinner.
- Menu-bar status and colour reflect listening and processing.
- **Recording Feedback Sounds** offers start/stop cues. It is off by default
  and saved in configuration as `feedback_sounds`.
- A very brief key tap produces a hold-longer message. Very low microphone
  signal produces a try-again message without invoking recognition.
- An empty recognition result produces a visible notice rather than silently
  disappearing.
- These signal checks do not claim to identify speech; microphone quality and
  background noise still affect recognition.

### 2. Built-in practice box

- **Try Dictation** appears in the ready window and **Try Dictation…** in the
  waveform menu.
- A focused, editable practice field explains holding and releasing Fn and
  shows the current language and recording state.
- Practice uses the normal capture, transcription, and keyboard-insertion path.
- Its contents are held in memory while open and cleared when closed; there is
  no saved practice history or undo archive.
- If the user changes focus or moves the practice cursor before recognition
  completes, the result goes to recovery instead of being inserted elsewhere.

### 3. Protection against lost or misplaced text

- Only one recording/transcription session is accepted at a time. Extra Fn
  presses during processing are ignored until that sentence completes.
- Session IDs reject duplicate or stale completions.
- Before recording, Dictate captures the original application, focused editable
  field, and selection range where available. It reads identity/selection
  metadata, not the field's text.
- Before insertion, it checks the same application, field, editability, and
  selection. An unknown, secure, changed, or unavailable field uses recovery.
- Keyboard events are prepared before posting, and UTF-16 surrogate pairs are
  kept together so emoji are not split across events.
- The recovery window offers **Copy Text**. Only a blocked result is kept, in
  memory, for up to 60 seconds. Closing the window, copying it, changing
  languages, starting a new dictation, or quitting clears it from the app.
- Copying is explicit and replaces the clipboard. The clipboard and destination
  application's retention/sync behaviour are outside Dictate's control.
- Posting keyboard events does not prove that another app accepted them. Apps
  with unusual Accessibility implementations may require the recovery path;
  secure inputs are not bypassed. Successful results are not retained for later
  recovery.

## Subsequent improvements

These items are planned, not implemented in this change.

| Priority | Improvement | Intended outcome and acceptance |
| --- | --- | --- |
| 4 | Custom shortcuts and toggle recording | Choose a shortcut and hold-to-talk or press-to-toggle. Test external keyboards, conflicts with macOS shortcuts, and cancellation. Keep event monitoring narrowly scoped. |
| 5 | Thai accuracy and local vocabulary | Collect Snook's non-sensitive examples of names, terminology, punctuation, and mixed Thai/English speech. Establish a baseline before testing optional local vocabulary hints. Ship only measured improvements. |
| 6 | Model progress and microphone selection | Show real download progress and retries; select/test a microphone. Test interrupted downloads, offline restarts, Bluetooth disconnects, and device changes. |
| 7 | In-app update checks | Let users deliberately check for updates and install a verified, signed release. Validate artifact integrity, bundle identity, signature, and Gatekeeper before replacing the app. |

## Verification and release gate

Automated coverage includes session sequencing, stale completion rejection,
very short/quiet audio, bounded recovery lifetime, changed app/field/selection,
unavailable fields, Unicode event chunking, opt-in sound configuration, and
practice/recovery UI actions and text clearing.

Run:

```sh
swift test
swift build -c release
.build/release/regardingwork-dictate --help
VERSION=0.1.5-dev DIST=/absolute/path/to/a/new/review-directory ./scripts/build-app.sh
git diff --check
```

Before distributing v0.1.5, complete the manual cases in [PILOT.md](../PILOT.md),
including real microphones, physical Fn input, permission prompts, Thai speech,
focus switching, recovery expiry/copy, external applications, and optional
sounds. Automated tests do not certify these macOS interactions or recognition
accuracy.

Use a reviewed merge followed by a fresh Developer ID signed, notarized, stapled
DMG/ZIP with checksums. The current v0.1.4 download remains the supported build
until that release is published. No recordings, dictated text, model downloads,
or signing material belong in Git.

### Development verification on 2026-10-03

- `swift test`: 46 tests passed.
- `swift build -c release`: passed.
- Root and `run --help` CLI smoke tests: passed.
- Practice and recovery windows: visually reviewed in isolated AppKit previews
  using non-sensitive example text; previews did not access the microphone.
- Real speech, permissions, physical Fn input, sound audibility, focus changes
  in external applications, and recognition quality: pending manual pilot tests.
