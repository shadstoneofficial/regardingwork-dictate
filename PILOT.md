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

Double-click the app and complete the visible first-run window. The app must
request microphone and Accessibility access, show model preparation, and
confirm when dictation is ready without requiring Terminal.

In System Settings → Privacy & Security, grant access to RegardingWork Dictate.
The app may recommend setting System Settings → Keyboard → “Press 🌐 key to”
to “Do Nothing,” but that preference must not make the app silently exit.

## Manual acceptance tests

Automated tests do not exercise macOS privacy prompts or physical input. On
each pilot Mac:

1. Confirm Gatekeeper accepts the installed app without a bypass.
2. Double-click the app and confirm a setup/preparation window appears
   immediately, before model loading completes.
3. Deny or remove a permission and confirm the app remains running with a
   visible explanation, **Open System Settings**, and **Check Again** actions.
4. Confirm the waveform menu item appears during preparation and offers
   **Setup & Diagnostics…**.
5. Select **Start RegardingWork Dictate at Login**, confirm its checkmark
   appears, and verify RegardingWork Dictate is enabled in System Settings →
   General → Login Items & Extensions.
6. Confirm model preparation has a visible activity indicator and a local-data
   explanation.
7. Quit and double-click again; confirm it reaches ready state without Terminal.
8. Hold and release `fn`; verify the recording overlay transitions to
   transcribing and returns to idle.
9. Dictate into TextEdit, Safari, Messages, Slack, a terminal, and one Electron
   app. Confirm text appears only at the active cursor.
10. Confirm no transcript text appears in
   `~/Library/Logs/RegardingWork Dictate/`.
11. Confirm ordinary keystrokes are not logged with modifier debugging enabled.
12. Opt into `--dump-wav`, inspect permissions with `stat`, then delete the
   recording and disable the option.
13. Log out and back in; confirm the native login item starts the app and
   existing permission grants remain valid.
14. Clear **Start RegardingWork Dictate at Login**, log out and back in, and
   confirm the app does not start automatically.
15. Upgrade the signed app in place and repeat the permission and login-item
   checks.

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

Disable **Start RegardingWork Dictate at Login**, restore the previously
approved signed app bundle to the same `/Applications` path, verify its
checksum/signature/Gatekeeper status, and re-enable the setting. Never roll
back by moving tags or installing an unsigned artifact.

Users migrating from the original upstream app should stop its LaunchAgent
before installing this app. RegardingWork Dictate automatically removes its own
obsolete LaunchAgent file after enabling the native login item; it does not
alter the upstream app's files. Legacy upstream data and logs are not imported
automatically; review and remove them manually only with the user's approval.
