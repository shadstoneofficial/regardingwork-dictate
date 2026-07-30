import AppKit
import XCTest
@testable import RegardingWorkDictate

@MainActor
final class SetupWindowControllerTests: XCTestCase {
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
