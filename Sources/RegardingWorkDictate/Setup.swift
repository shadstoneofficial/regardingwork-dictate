import ApplicationServices
import ArgumentParser
import AVFoundation
import Foundation

struct Setup: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Walk through first-run permission setup."
    )

    func run() throws {
        print("\(AppIdentity.productName) setup")
        print(String(repeating: "=", count: AppIdentity.productName.count + 6))
        print()
        print("\(AppIdentity.productName) needs two permissions:")
        print("  1. Accessibility — to detect the Fn key globally and inject text at the cursor.")
        print("  2. Microphone — to record audio while you hold Fn.")
        print()
        print("Installed releases attach these grants to the signed \(AppIdentity.productName).app identity.")
        print("Development builds may attach grants to the terminal or build host that launches them.")
        print()

        try waitForAccessibility()
        print()
        try waitForMicrophone()
        print()
        print("✓ all set. Run `\(AppIdentity.executableName)` to start dictation.")
    }

    private func waitForAccessibility() throws {
        if AXIsProcessTrusted() {
            print("✓ accessibility already granted")
            return
        }

        print("→ opening accessibility prompt...")
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)

        print()
        print("  1. Toggle \(AppIdentity.productName) on in the Accessibility list.")
        print("  2. Re-run `\(AppIdentity.executableName) setup` after the grant is applied.")
        throw ExitCode(0)
    }

    private func waitForMicrophone() throws {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            print("✓ microphone already granted")
            return
        case .denied, .restricted:
            print("✗ microphone is denied — macOS won't re-prompt once denied.")
            print("  opening Settings → Privacy & Security → Microphone...")
            openSettings("Privacy_Microphone")
            print("  enable \(AppIdentity.productName), then re-run `\(AppIdentity.executableName) setup`.")
            throw ExitCode(1)
        case .notDetermined:
            print("→ requesting microphone access...")
            let semaphore = DispatchSemaphore(value: 0)
            var granted = false
            AVCaptureDevice.requestAccess(for: .audio) { ok in
                granted = ok
                semaphore.signal()
            }
            semaphore.wait()
            if granted {
                print("  ✓ microphone granted")
            } else {
                print("  ✗ microphone denied")
                throw ExitCode(1)
            }
        @unknown default:
            print("? microphone in unknown state")
        }
    }

    private func openSettings(_ pane: String) {
        let url = "x-apple.systempreferences:com.apple.preference.security?\(pane)"
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [url]
        try? task.run()
    }
}
