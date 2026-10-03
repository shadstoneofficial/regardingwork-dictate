import AppKit

/// A voluntary practice field. Contents exist only while this window is open.
@MainActor
final class PracticeWindowController: NSWindowController, NSWindowDelegate {
    let textView = NSTextView()
    private let statusLabel = NSTextField(wrappingLabelWithString: "")

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 360),
            styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false
        )
        window.title = "Try Dictation — \(AppIdentity.productName)"
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 460, height: 320)
        super.init(window: window)
        window.delegate = self

        let heading = NSTextField(labelWithString: "Try your first dictation")
        heading.font = .systemFont(ofSize: 22, weight: .semibold)
        let instructions = NSTextField(wrappingLabelWithString:
            "Hold fn, say a short sentence, then release. Your words will appear below. Close this window to clear the practice text."
        )
        instructions.font = .systemFont(ofSize: 14)
        textView.font = .systemFont(ofSize: 18)
        textView.isRichText = false
        textView.allowsUndo = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.setAccessibilityLabel("Dictation practice text")
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        scroll.documentView = textView
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.textColor = .secondaryLabelColor
        let stack = NSStackView(views: [heading, instructions, statusLabel, scroll])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        let content = NSView()
        content.addSubview(stack)
        window.contentView = content
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -24),
            instructions.widthAnchor.constraint(equalTo: stack.widthAnchor),
            scroll.widthAnchor.constraint(equalTo: stack.widthAnchor),
            scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 150),
        ])
    }

    required init?(coder: NSCoder) { nil }

    func present(language: TranscriptionLanguage) {
        statusLabel.stringValue = "Ready — \(language.displayName). Practice text stays in this window."
        NSApp.setActivationPolicy(.regular)
        window?.center()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(textView)
        NSApp.activate(ignoringOtherApps: true)
    }

    func setStatus(_ text: String) { statusLabel.stringValue = text }

    var isInputFocused: Bool {
        window?.isVisible == true && window?.isKeyWindow == true &&
            window?.firstResponder === textView && NSApp.isActive
    }

    func windowWillClose(_ notification: Notification) {
        textView.string = ""
        if !NSApp.windows.contains(where: { $0 !== window && $0.isVisible && $0.styleMask.contains(.titled) }) {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
