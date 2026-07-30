import AppKit

/// Visible first-launch and recovery surface for the menu-bar application.
/// Normal users should never need Terminal to understand startup state.
@MainActor
final class SetupWindowController: NSWindowController, NSWindowDelegate {
    private let titleLabel = NSTextField(labelWithString: "")
    private let messageLabel = NSTextField(wrappingLabelWithString: "")
    private let detailLabel = NSTextField(wrappingLabelWithString: "")
    private let progressIndicator = NSProgressIndicator()
    private let primaryButton = NSButton()
    private let secondaryButton = NSButton()
    private var primaryAction: (() -> Void)?
    private var secondaryAction: (() -> Void)?
    private var pendingDismissal: DispatchWorkItem?

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 330),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = AppIdentity.productName
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
        window.delegate = self
        configureContent(in: window)
    }

    required init?(coder: NSCoder) {
        nil
    }

    func showChecking() {
        configure(
            title: "Getting RegardingWork Dictate ready",
            message: "Checking microphone and Accessibility permissions…",
            detail: "You will not need Terminal. This window will stay open if anything needs your attention.",
            showsProgress: true
        )
        present()
    }

    func showWaitingForMicrophone() {
        configure(
            title: "Allow microphone access",
            message: "Please choose Allow in the macOS microphone prompt.",
            detail: "Audio is captured only while you hold the push-to-talk key and is transcribed on this Mac.",
            showsProgress: true
        )
        present()
    }

    func showPermissionRequired(
        checks: [Check],
        retry: @escaping () -> Void,
        openSettings: @escaping () -> Void
    ) {
        let details = checks.compactMap { check -> String? in
            guard case .fail(let reason) = check.status else { return nil }
            return "• \(check.name.capitalized): \(reason)"
        }.joined(separator: "\n")

        configure(
            title: "One permission still needs attention",
            message: "Enable RegardingWork Dictate in System Settings, then return here and choose Check Again.",
            detail: details,
            showsProgress: false,
            primaryTitle: "Check Again",
            primaryAction: retry,
            secondaryTitle: "Open System Settings",
            secondaryAction: openSettings
        )
        present()
    }

    func showPreparingModel(name: String) {
        configure(
            title: "Preparing on-device dictation",
            message: "Downloading or loading \(name)…",
            detail: "The first launch can take a few minutes. Audio and transcripts stay on this Mac.",
            showsProgress: true
        )
        present()
    }

    func showReady(autoDismiss: Bool, done: @escaping () -> Void) {
        configure(
            title: "RegardingWork Dictate is ready",
            message: "Click into any text field, hold fn while you speak, then release it.",
            detail: "The waveform icon in the menu bar shows that the app is running.",
            showsProgress: false,
            primaryTitle: "Start Dictating",
            primaryAction: done
        )
        present()

        if autoDismiss {
            let dismissal = DispatchWorkItem { [weak self] in
                self?.closeAndReturnToMenuBar()
            }
            pendingDismissal = dismissal
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: dismissal)
        }
    }

    func showError(message: String, retry: @escaping () -> Void) {
        configure(
            title: "RegardingWork Dictate could not start",
            message: message,
            detail: "The app will remain available from the menu bar. No recording is taking place.",
            showsProgress: false,
            primaryTitle: "Try Again",
            primaryAction: retry
        )
        present()
    }

    func closeAndReturnToMenuBar() {
        pendingDismissal?.cancel()
        pendingDismissal = nil
        close()
        NSApp.setActivationPolicy(.accessory)
    }

    func windowWillClose(_ notification: Notification) {
        pendingDismissal?.cancel()
        pendingDismissal = nil
        NSApp.setActivationPolicy(.accessory)
    }

    private func configureContent(in window: NSWindow) {
        let icon = NSImageView()
        icon.image = NSImage(
            systemSymbolName: "waveform.circle.fill",
            accessibilityDescription: AppIdentity.productName
        )
        icon.contentTintColor = .controlAccentColor
        icon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 42, weight: .regular)
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 52),
            icon.heightAnchor.constraint(equalToConstant: 52),
        ])

        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        titleLabel.maximumNumberOfLines = 2
        messageLabel.font = .systemFont(ofSize: 15)
        messageLabel.textColor = .labelColor
        detailLabel.font = .systemFont(ofSize: 13)
        detailLabel.textColor = .secondaryLabelColor

        progressIndicator.style = .spinning
        progressIndicator.controlSize = .regular
        progressIndicator.isIndeterminate = true

        primaryButton.bezelStyle = .rounded
        primaryButton.keyEquivalent = "\r"
        primaryButton.target = self
        primaryButton.action = #selector(primaryClicked)

        secondaryButton.bezelStyle = .rounded
        secondaryButton.target = self
        secondaryButton.action = #selector(secondaryClicked)

        let heading = NSStackView(views: [icon, titleLabel])
        heading.orientation = .horizontal
        heading.alignment = .centerY
        heading.spacing = 14

        let buttons = NSStackView(views: [secondaryButton, primaryButton])
        buttons.orientation = .horizontal
        buttons.alignment = .centerY
        buttons.distribution = .gravityAreas
        buttons.spacing = 10

        let content = NSStackView(views: [
            heading,
            messageLabel,
            detailLabel,
            progressIndicator,
            buttons,
        ])
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 16
        content.setHuggingPriority(.defaultLow, for: .horizontal)
        content.translatesAutoresizingMaskIntoConstraints = false

        let contentView = NSView()
        contentView.addSubview(content)
        window.contentView = contentView

        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            content.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28),
            content.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 26),
            content.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24),
            messageLabel.widthAnchor.constraint(equalTo: content.widthAnchor),
            detailLabel.widthAnchor.constraint(equalTo: content.widthAnchor),
            buttons.widthAnchor.constraint(equalTo: content.widthAnchor),
        ])
    }

    private func configure(
        title: String,
        message: String,
        detail: String,
        showsProgress: Bool,
        primaryTitle: String? = nil,
        primaryAction: (() -> Void)? = nil,
        secondaryTitle: String? = nil,
        secondaryAction: (() -> Void)? = nil
    ) {
        pendingDismissal?.cancel()
        pendingDismissal = nil

        titleLabel.stringValue = title
        messageLabel.stringValue = message
        detailLabel.stringValue = detail

        if showsProgress {
            progressIndicator.isHidden = false
            progressIndicator.startAnimation(nil)
        } else {
            progressIndicator.stopAnimation(nil)
            progressIndicator.isHidden = true
        }

        self.primaryAction = primaryAction
        primaryButton.title = primaryTitle ?? ""
        primaryButton.isHidden = primaryTitle == nil

        self.secondaryAction = secondaryAction
        secondaryButton.title = secondaryTitle ?? ""
        secondaryButton.isHidden = secondaryTitle == nil
    }

    private func present() {
        NSApp.setActivationPolicy(.regular)
        showWindow(nil)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func primaryClicked() {
        primaryAction?()
    }

    @objc private func secondaryClicked() {
        secondaryAction?()
    }
}
