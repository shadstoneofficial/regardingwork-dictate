# Privacy

RegardingWork Dictate is designed for private, local dictation.

## Data handling

- Microphone audio is captured while the push-to-talk key is held and processed
  in memory after release.
- Transcription runs locally through WhisperKit and Core ML.
- Text is sent to the original focused text field only if its identity and
  selection can still be verified. Target contents are not read; only
  Accessibility identity, editability, and selection metadata are checked.
- Successful results are not retained. If insertion is blocked, one temporary
  result is displayed for explicit copying and held in memory for up to 60
  seconds. Closing or copying it, starting another dictation, changing language,
  or quitting clears it. It is never written to disk or logs.
- Practice text remains in its window's memory while open and clears on close.
- Choosing **Copy Text** replaces the system clipboard. macOS clipboard sync,
  clipboard managers, and destination apps may retain that text independently.
- Transcript text is never written to application or LaunchAgent logs.
- No audio, transcript, usage event, diagnostic, or telemetry is transmitted.
- There is no server, account, Railway service, analytics SDK, or cloud
  transcription dependency.

The selected model may be downloaded from WhisperKit's model host. Swift
dependencies are downloaded during development and CI builds. Those downloads
do not include microphone audio or transcript text.

## Optional debugging data

Audio dumping is off by default. `run --dump-wav` or `"dump_wav": true` creates
one `0600` WAV file in a `0700` branded temporary directory. The next capture
replaces it, and macOS may remove temporary files. Treat the file as sensitive
and delete it after debugging.

Modifier debugging is off by default. `--debug-hotkey` records modifier flag
changes only; the event tap does not subscribe to normal key-down or key-up
events and does not record keycodes.

## Local paths

- Configuration and models:
  `~/Library/Application Support/RegardingWork Dictate/`
- Logs: `~/Library/Logs/RegardingWork Dictate/`
- Debug audio: the macOS temporary directory under
  `com.regardingwork.dictate/`

Private directories are created with mode `0700`; logs, legacy LaunchAgent
plists, and debug recordings are restricted to mode `0600`.

The selected language and optional recording-sound preference are saved locally
in configuration. Recording sounds are off by default.

## Reporting

Report a suspected privacy issue privately using the process in
[SECURITY.md](SECURITY.md). Do not attach recordings or transcripts unless an
authorized reviewer explicitly requests a sanitized reproduction.
