# Pilot guide

## Supported pilot hardware

- Apple Silicon Mac (M1 or later)
- macOS 14 or later
- Working built-in or external microphone
- Physical `fn` / globe key, or a supported modifier key in the next release

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
15. Choose **Dictation Language → Thai**. Confirm the multilingual model is
    prepared locally, the menu reports Thai, and the selection survives an app
    restart.
16. Dictate several Thai-only phrases into TextEdit and Safari. Confirm Thai
    script is inserted at the cursor and no transcript appears in application
    logs.
17. Test Thai names, numbers, punctuation, and short mixed Thai-English phrases.
    Record accuracy limitations without transmitting recordings or transcripts.
18. Switch back to English and confirm the smaller English model becomes ready
    without restarting the app.
19. Upgrade the signed app in place and repeat the permission, language, and
    login-item checks.

### Next-release confidence checks

Use non-sensitive example speech. Do not upload recordings or transcripts.

1. Open **Try Dictation** from setup and **Try Dictation…** from the waveform
   menu. Dictate English and Thai sentences into the practice box, confirm
   Listening/Processing labels, and close/reopen it to confirm the text clears.
2. Confirm the selected language is visible in the overlay. With no speech or
   very low microphone signal, expect a try-again notice, not fabricated text.
   A brief hotkey tap should show a cancellation notice without recognition.
3. Enable **Recording Feedback Sounds**, listen for start/stop cues, restart,
   and confirm the preference persists. Disable it and confirm cues stop.
4. Press/release Fn again while the first sentence is processing. Confirm no
   second capture starts, no duplicate text is sent, and later dictation works.
5. Switch to another app, another field in the same app, or move/select text
   while recognition is processing. Confirm nothing is sent to the changed
   destination and the result appears in recovery instead.
6. Try a password field, read-only field, and an app whose field cannot be
   inspected through Accessibility. Confirm the app does not bypass those
   restrictions and offers recovery for a recognized sentence.
7. Copy recovery text explicitly and paste it into a chosen field. Confirm the
   recovery window clears. Repeat, wait 60 seconds without copying, and confirm
   expiry clears and closes it. Also check close, new recording, language
   change, and quit clear a pending result.
8. Close the practice window or change its selection during processing. Confirm
   no result is inserted elsewhere. Test long Thai text and emoji in TextEdit,
   Safari, Messages, Slack, and an Electron app for dropped/reordered characters.
9. Repeat on multiple displays and in a full-screen app. Confirm the overlay
   does not take keyboard focus or disappear during a new recording.

### Next-release configurable key checks

1. Select every **Push-to-Talk Key** choice. Confirm its checkmark, ready text,
   setup instructions and practice instructions agree. Restart and confirm the
   saved choice survives; old configuration files must still default to Fn.
2. Test left and right sides separately on Apple and third-party USB/Bluetooth
   keyboards. The opposite side alone must not record; release must end capture.
3. Tap for under 0.3 seconds and combine the selected key with another modifier,
   including Fn. Confirm no transcript is produced and the next clean hold works.
4. Test normal keyboard shortcuts and typing. A modifier-only listener cannot
   identify letter shortcuts: pick an otherwise unused side-specific modifier.
5. While listening or processing, confirm key selection is disabled and extra
   gestures do not cancel an in-flight sentence. Change key while idle and confirm
   no old-key release starts or ends a new recording.
6. Test sleep/wake, keyboard disconnect/reconnect, permissions revocation,
   multiple monitors and closed-lid operation with a working external microphone.
   This change does not claim to resolve upstream's open clamshell issue.
7. Run CLI help and an invalid `--hotkey` value without recording. A valid CLI
   override must not save itself; choosing a key in the menu is an explicit save.

macOS keyboard-event posting cannot confirm that a receiving app accepted the
text. Successful results are not retained for retry; record app-specific
compatibility limitations without adding transcript history.

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
