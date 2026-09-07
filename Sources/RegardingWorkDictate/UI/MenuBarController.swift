import AppKit

/// Persistent menu-bar presence. It is created before permissions or model
/// loading so Finder launches always produce immediate, visible feedback.
@MainActor
final class MenuBarController {
    private let statusItem: NSStatusItem
    private let modelLabel: NSMenuItem
    private let stateLabel: NSMenuItem
    private let setupItem: NSMenuItem
    private let launchAtLoginItem: NSMenuItem

    var onShowSetup: (() -> Void)?
    var onToggleLaunchAtLogin: (() -> Void)?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let menu = NSMenu()
        menu.autoenablesItems = false

        stateLabel = NSMenuItem(title: "starting…", action: nil, keyEquivalent: "")
        stateLabel.isEnabled = false
        menu.addItem(stateLabel)

        modelLabel = NSMenuItem(title: "model: not loaded", action: nil, keyEquivalent: "")
        modelLabel.isEnabled = false
        menu.addItem(modelLabel)

        menu.addItem(.separator())

        setupItem = NSMenuItem(
            title: "Setup & Diagnostics…",
            action: #selector(showSetupClicked),
            keyEquivalent: ","
        )
        menu.addItem(setupItem)

        launchAtLoginItem = NSMenuItem(
            title: "Start RegardingWork Dictate at Login",
            action: #selector(toggleLaunchAtLoginClicked),
            keyEquivalent: ""
        )
        menu.addItem(launchAtLoginItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit \(AppIdentity.productName)",
            action: #selector(quitClicked),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        setupItem.target = self
        launchAtLoginItem.target = self
        quitItem.target = self
        statusItem.menu = menu

        if let button = statusItem.button {
            let image = NSImage(
                systemSymbolName: "waveform",
                accessibilityDescription: AppIdentity.productName
            )
            image?.isTemplate = true
            button.image = image
            button.toolTip = "\(AppIdentity.productName) is starting"
        }
    }

    func setChecking() {
        setState("checking permissions…")
    }

    func setPreparing(modelID: String) {
        modelLabel.title = "model: \(modelID)"
        setState("preparing on-device model…")
    }

    func setReady(modelID: String) {
        modelLabel.title = "model: \(modelID)"
        setState("ready · hold fn to dictate")
    }

    func setNeedsAttention(_ message: String) {
        setState("needs attention · \(message)")
    }

    func setRecording(_ recording: Bool) {
        setState(recording ? "● recording" : "ready · hold fn to dictate")
    }

    func setTranscribing() {
        setState("transcribing…")
    }

    func setLaunchAtLoginStatus(_ status: LaunchAtLoginStatus) {
        launchAtLoginItem.state = status.isSelected ? .on : .off
        switch status {
        case .requiresApproval:
            launchAtLoginItem.title = "Start RegardingWork Dictate at Login (Approval Required…)"
            launchAtLoginItem.isEnabled = true
        case .unavailable:
            launchAtLoginItem.title = "Start RegardingWork Dictate at Login (Unavailable)"
            launchAtLoginItem.isEnabled = false
        case .disabled, .enabled:
            launchAtLoginItem.title = "Start RegardingWork Dictate at Login"
            launchAtLoginItem.isEnabled = true
        }
    }

    private func setState(_ title: String) {
        stateLabel.title = title
        statusItem.button?.toolTip = "\(AppIdentity.productName): \(title)"
    }

    @objc private func showSetupClicked() {
        onShowSetup?()
    }

    @objc private func toggleLaunchAtLoginClicked() {
        onToggleLaunchAtLogin?()
    }

    @objc private func quitClicked() {
        NSApp.terminate(nil)
    }
}
