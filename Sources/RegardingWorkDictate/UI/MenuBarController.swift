import AppKit

/// Persistent menu-bar presence. It is created before permissions or model
/// loading so Finder launches always produce immediate, visible feedback.
@MainActor
final class MenuBarController {
    private let statusItem: NSStatusItem
    private let modelLabel: NSMenuItem
    private let stateLabel: NSMenuItem
    private let setupItem: NSMenuItem
    private let languageItem: NSMenuItem
    private let englishLanguageItem: NSMenuItem
    private let thaiLanguageItem: NSMenuItem
    private let launchAtLoginItem: NSMenuItem
    private let practiceItem: NSMenuItem
    private let soundsItem: NSMenuItem
    private var currentLanguage = TranscriptionLanguage.english

    var onShowSetup: (() -> Void)?
    var onSelectLanguage: ((TranscriptionLanguage) -> Void)?
    var onToggleLaunchAtLogin: (() -> Void)?
    var onPractice: (() -> Void)?
    var onToggleSounds: (() -> Void)?

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

        practiceItem = NSMenuItem(title: "Try Dictation…", action: #selector(practiceClicked), keyEquivalent: "")
        practiceItem.isEnabled = false
        menu.addItem(practiceItem)
        soundsItem = NSMenuItem(title: "Recording Feedback Sounds", action: #selector(soundsClicked), keyEquivalent: "")
        menu.addItem(soundsItem)

        languageItem = NSMenuItem(
            title: "Dictation Language: English",
            action: nil,
            keyEquivalent: ""
        )
        englishLanguageItem = NSMenuItem(
            title: "English",
            action: #selector(selectEnglishClicked),
            keyEquivalent: ""
        )
        thaiLanguageItem = NSMenuItem(
            title: "Thai",
            action: #selector(selectThaiClicked),
            keyEquivalent: ""
        )
        let languageMenu = NSMenu(title: "Dictation Language")
        languageMenu.addItem(englishLanguageItem)
        languageMenu.addItem(thaiLanguageItem)
        languageItem.submenu = languageMenu
        menu.addItem(languageItem)

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
        practiceItem.target = self
        soundsItem.target = self
        englishLanguageItem.target = self
        thaiLanguageItem.target = self
        launchAtLoginItem.target = self
        quitItem.target = self
        statusItem.menu = menu
        setLanguage(.english)

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
        setState(readyStateTitle)
    }

    func setNeedsAttention(_ message: String) {
        setState("needs attention · \(message)")
    }

    func setRecording(_ recording: Bool) {
        setState(recording ? "● Listening — \(currentLanguage.displayName)" : readyStateTitle)
        statusItem.button?.contentTintColor = recording ? .systemRed : nil
    }

    func setTranscribing() {
        setState("Processing — \(currentLanguage.displayName)…")
        statusItem.button?.contentTintColor = .systemOrange
    }

    func setPracticeEnabled(_ enabled: Bool) { practiceItem.isEnabled = enabled }

    func setSoundsEnabled(_ enabled: Bool) { soundsItem.state = enabled ? .on : .off }

    func setLanguage(_ language: TranscriptionLanguage) {
        currentLanguage = language
        languageItem.title = "Dictation Language: \(language.displayName)"
        englishLanguageItem.state = language == .english ? .on : .off
        thaiLanguageItem.state = language == .thai ? .on : .off
    }

    func setLanguageSelectionEnabled(_ enabled: Bool) {
        languageItem.isEnabled = enabled
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
        statusItem.button?.contentTintColor = nil
        stateLabel.title = title
        statusItem.button?.toolTip = "\(AppIdentity.productName): \(title)"
    }

    private var readyStateTitle: String {
        "ready · \(currentLanguage.displayName) · hold fn to dictate"
    }

    @objc private func showSetupClicked() {
        onShowSetup?()
    }

    @objc private func practiceClicked() { onPractice?() }

    @objc private func soundsClicked() { onToggleSounds?() }

    @objc private func selectEnglishClicked() {
        onSelectLanguage?(.english)
    }

    @objc private func selectThaiClicked() {
        onSelectLanguage?(.thai)
    }

    @objc private func toggleLaunchAtLoginClicked() {
        onToggleLaunchAtLogin?()
    }

    @objc private func quitClicked() {
        NSApp.terminate(nil)
    }
}
