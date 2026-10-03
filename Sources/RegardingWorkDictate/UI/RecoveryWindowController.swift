import AppKit

@MainActor
final class RecoveryWindowController: NSWindowController, NSWindowDelegate {
    private let textView = NSTextView()
    private let messageLabel = NSTextField(wrappingLabelWithString: "")
    var onCopy: (() -> Void)?
    var onDismiss: (() -> Void)?

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 340),
            styleMask: [.titled, .closable], backing: .buffered, defer: false
        )
        window.title = "Recover Dictation — \(AppIdentity.productName)"
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.delegate = self
        let heading = NSTextField(labelWithString: "Your dictation is ready to copy")
        heading.font = .systemFont(ofSize: 21, weight: .semibold)
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = false
        textView.font = .systemFont(ofSize: 16)
        textView.textContainerInset = NSSize(width: 10, height: 10)
        textView.setAccessibilityLabel("Temporary recovered dictation")
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        scroll.documentView = textView
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.textContainer?.widthTracksTextView = true
        let privacy = NSTextField(wrappingLabelWithString:
            "This result clears after 60 seconds or when you close this window. Copy puts it on your clipboard, where macOS and other apps may retain or sync it."
        )
        privacy.font = .systemFont(ofSize: 12)
        privacy.textColor = .secondaryLabelColor
        let copy = NSButton(title: "Copy Text", target: self, action: #selector(copyClicked))
        copy.bezelStyle = .rounded
        let stack = NSStackView(views: [heading, messageLabel, scroll, privacy, copy])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        let content = NSView()
        content.addSubview(stack)
        window.contentView = content
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -24),
            scroll.widthAnchor.constraint(equalTo: stack.widthAnchor),
            scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            messageLabel.widthAnchor.constraint(equalTo: stack.widthAnchor),
            privacy.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])
    }

    required init?(coder: NSCoder) { nil }

    func present(text: String, reason: String) {
        textView.string = text
        messageLabel.stringValue = reason
        NSApp.setActivationPolicy(.regular)
        window?.center()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func clear() {
        textView.string = ""
        if window?.isVisible == true { close() }
    }

    func windowWillClose(_ notification: Notification) {
        textView.string = ""
        onDismiss?()
        if !NSApp.windows.contains(where: { $0 !== window && $0.isVisible && $0.styleMask.contains(.titled) }) {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    @objc private func copyClicked() { onCopy?() }
}
