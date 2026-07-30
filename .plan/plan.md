# RegardingWork Dictate development plan

This implementation began as a minimal on-device macOS dictation daemon and is
now maintained as a signed menu-bar application in the RegardingWork Voice
family. Historical origin and sync details live in [../UPSTREAM.md](../UPSTREAM.md).

Current priorities:

1. Preserve private, on-device push-to-talk transcription.
2. Keep transcript contents out of logs and debug audio explicitly opt-in.
3. Maintain stable signed application, microphone, Accessibility, and
   LaunchAgent identity.
4. Validate platform-independent behavior with Swift tests.
5. Complete physical-key, microphone, permission, overlay, and text-injection
   checks on each signed pilot build.

Deferred work must not weaken these boundaries. Additional engines may be
considered only after their network behavior, model license, binary size, and
on-device guarantees are reviewed. Cloud transcription, telemetry, meeting
capture, and server infrastructure remain out of scope.
