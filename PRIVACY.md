# Privacy

RegardingWork Dictate is designed for private, local dictation.

## Data handling

- Microphone audio is held in memory only while the push-to-talk key is held.
- Transcription runs locally through WhisperKit and Core ML.
- The transcript is injected at the active cursor and is not retained.
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

Private directories are created with mode `0700`; logs, LaunchAgent plists, and
debug recordings are restricted to mode `0600`.

## Reporting

Report a suspected privacy issue privately using the process in
[SECURITY.md](SECURITY.md). Do not attach recordings or transcripts unless an
authorized reviewer explicitly requests a sanitized reproduction.
