import AppKit
import XCTest
@testable import RegardingWorkDictate

@MainActor
final class SetupWindowControllerTests: XCTestCase {
    func testSelectedKeyAppearsInSetupAndPractice() {
        _ = NSApplication.shared
        let setup = SetupWindowController()
        setup.showReady(autoDismiss: false, done: {}, hotkey: .rightOption)
        XCTAssertTrue(textFields(in: setup.window?.contentView).contains { $0.stringValue.contains("hold right ⌥") })
        setup.closeAndReturnToMenuBar()
        let practice = PracticeWindowController()
        practice.present(language: .thai, hotkey: .leftControl)
        XCTAssertTrue(textFields(in: practice.window?.contentView).contains { $0.stringValue.contains("Hold left ⌃") })
        practice.setHotkey(.rightShift)
        XCTAssertTrue(textFields(in: practice.window?.contentView).contains { $0.stringValue.contains("Hold right ⇧") })
        practice.close()
    }
    func testReadyWindowOffersPracticeWithoutRequiringTerminal() {
        _ = NSApplication.shared
        let controller = SetupWindowController()
        var practiced = false
        controller.showReady(autoDismiss: false, done: {}, practice: { practiced = true })
        let button = buttons(in: controller.window?.contentView).first { $0.title == "Try Dictation" }
        XCTAssertEqual(button?.isHidden, false)
        button?.performClick(nil)
        XCTAssertTrue(practiced)
        controller.closeAndReturnToMenuBar()
    }

    func testPracticeClearsItsTextWhenClosed() {
        _ = NSApplication.shared
        let controller = PracticeWindowController()
        controller.present(language: .thai)
        controller.textView.string = "ข้อความทดสอบ"
        XCTAssertTrue(controller.textView.isEditable)
        XCTAssertFalse(controller.textView.allowsUndo)
        controller.close()
        XCTAssertEqual(controller.textView.string, "")
    }

    func testRecoveryRequiresExplicitCopyAndClearsItsTextOnClose() {
        _ = NSApplication.shared
        let controller = RecoveryWindowController()
        var copied = false
        var dismissed = false
        controller.onCopy = { copied = true }
        controller.onDismiss = { dismissed = true }
        controller.present(text: "Temporary example", reason: "Focus changed")
        let textView = descendants(in: controller.window?.contentView).compactMap { $0 as? NSTextView }.first
        XCTAssertEqual(textView?.string, "Temporary example")
        XCTAssertEqual(textView?.isEditable, false)
        XCTAssertFalse(copied)
        buttons(in: controller.window?.contentView).first { $0.title == "Copy Text" }?.performClick(nil)
        XCTAssertTrue(copied)
        controller.clear()
        XCTAssertEqual(textView?.string, "")
        XCTAssertTrue(dismissed)
    }

    func testStartupFailureIsVisibleAndRecoverable() {
        _ = NSApplication.shared
        let controller = SetupWindowController()
        controller.showError(message: "Model preparation failed") {}

        XCTAssertEqual(controller.window?.isVisible, true)
        XCTAssertTrue(
            textFields(in: controller.window?.contentView).contains {
                $0.stringValue.contains("Model preparation failed")
            }
        )
        XCTAssertTrue(
            buttons(in: controller.window?.contentView).contains {
                !$0.isHidden && $0.title == "Try Again"
            }
        )

        controller.closeAndReturnToMenuBar()
    }

    func testModelPreparationShowsVisibleActivity() {
        _ = NSApplication.shared
        let controller = SetupWindowController()
        controller.showPreparingModel(name: "Whisper Base")

        XCTAssertEqual(controller.window?.isVisible, true)
        XCTAssertTrue(
            textFields(in: controller.window?.contentView).contains {
                $0.stringValue.contains("Whisper Base")
            }
        )
        XCTAssertTrue(
            progressIndicators(in: controller.window?.contentView).contains {
                !$0.isHidden && $0.isIndeterminate
            }
        )

        controller.closeAndReturnToMenuBar()
    }

    private func textFields(in view: NSView?) -> [NSTextField] {
        descendants(in: view).compactMap { $0 as? NSTextField }
    }

    private func buttons(in view: NSView?) -> [NSButton] {
        descendants(in: view).compactMap { $0 as? NSButton }
    }

    private func progressIndicators(in view: NSView?) -> [NSProgressIndicator] {
        descendants(in: view).compactMap { $0 as? NSProgressIndicator }
    }

    private func descendants(in view: NSView?) -> [NSView] {
        guard let view else { return [] }
        return view.subviews + view.subviews.flatMap { descendants(in: $0) }
    }
}
