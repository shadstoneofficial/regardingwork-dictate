import ArgumentParser
import Foundation

/// Compatibility CLI for the app's native macOS login-item setting.
struct Install: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Enable or disable the native launch-at-login setting."
    )

    @Flag(name: .long, help: "Register RegardingWork Dictate to start at login.")
    var launchAtLogin: Bool = false

    @Flag(name: .long, help: "Disable launch at login.")
    var uninstall: Bool = false

    func run() throws {
        guard launchAtLogin != uninstall else {
            FileHandle.standardError.write(Data(
                "specify exactly one of --launch-at-login or --uninstall\n".utf8
            ))
            throw ExitCode(64)
        }
        let manager = LaunchAtLoginManager()
        try manager.setEnabled(launchAtLogin)
        if manager.status == .requiresApproval {
            print("Open System Settings → General → Login Items to approve \(AppIdentity.productName).")
        } else {
            print("✓ \(AppIdentity.productName) start at login \(launchAtLogin ? "enabled" : "disabled")")
        }
    }
}
