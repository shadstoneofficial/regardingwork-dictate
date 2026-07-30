import AppKit

/// Persistent menu-bar presence. It is created before permissions or model
/// loading so Finder launches always produce immediate, visible feedback.
@MainActor
final class MenuBarController {
    private let statusItem: NSStatusItem
    private let modelLabel: NSMenuItem
    private let stateLabel: NSMenuItem
    private let setupItem: NSMenuItem

    var onShowSetup: (() -> Void)?

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

        let quitItem = NSMenuItem(
            title: "Quit \(AppIdentity.productName)",
            action: #selector(quitClicked),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        setupItem.target = self
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

    private func setState(_ title: String) {
        stateLabel.title = title
        statusItem.button?.toolTip = "\(AppIdentity.productName): \(title)"
    }

    @objc private func showSetupClicked() {
        onShowSetup?()
    }

    @objc private func quitClicked() {
        NSApp.terminate(nil)
    }
}
