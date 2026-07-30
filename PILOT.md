# Pilot guide

## Supported pilot hardware

- Apple Silicon Mac (M1 or later)
- macOS 14 or later
- Working built-in or external microphone
- Physical `fn` / globe key

Intel Macs and non-macOS systems are not supported.

## Setup

Use a signed, notarized pilot build installed at the stable path
`/Applications/RegardingWork Dictate.app`. Verify the supplied checksum before
opening it. Never remove quarantine or override Gatekeeper.

```sh
regardingwork-dictate setup
regardingwork-dictate doctor
regardingwork-dictate models download whisper-base.en
regardingwork-dictate install --launch-at-login
```

In System Settings → Privacy & Security, grant microphone and Accessibility
access to RegardingWork Dictate. Set System Settings → Keyboard → “Press 🌐
key to” to “Do Nothing.”

## Manual acceptance tests

Automated tests do not exercise macOS privacy prompts or physical input. On
each pilot Mac:

1. Confirm Gatekeeper accepts the installed app without a bypass.
2. Confirm `doctor` reports microphone and Accessibility permission.
3. Hold and release `fn`; verify the recording overlay transitions to
   transcribing and returns to idle.
4. Dictate into TextEdit, Safari, Messages, Slack, a terminal, and one Electron
   app. Confirm text appears only at the active cursor.
5. Confirm no transcript text appears in
   `~/Library/Logs/RegardingWork Dictate/`.
6. Confirm ordinary keystrokes are not logged with modifier debugging enabled.
7. Opt into `--dump-wav`, inspect permissions with `stat`, then delete the
   recording and disable the option.
8. Log out and back in; confirm the LaunchAgent starts and existing permission
   grants remain valid.
9. Upgrade the signed app in place and repeat the permission check.

Secure password fields may reject injected text; record that as a platform
constraint, not a reason to broaden Accessibility event capture.

## Uninstall

```sh
regardingwork-dictate install --uninstall
sudo rm "/usr/local/bin/regardingwork-dictate"
sudo rm -R "/Applications/RegardingWork Dictate.app"
```

Review before deleting optional local data:

```sh
ls -la "$HOME/Library/Application Support/RegardingWork Dictate"
ls -la "$HOME/Library/Logs/RegardingWork Dictate"
```

Remove those directories only if the pilot user explicitly wants configuration,
downloaded models, and logs erased.

## Rollback

Uninstall the LaunchAgent, restore the previously approved signed app bundle to
the same `/Applications` path, verify its checksum/signature/Gatekeeper status,
and reinstall launch-at-login. Never roll back by moving tags or installing an
unsigned artifact.

Users migrating from the original upstream app should stop its LaunchAgent
before installing this app. Legacy upstream data and logs are not imported
automatically; review and remove them manually only with the user's approval.
