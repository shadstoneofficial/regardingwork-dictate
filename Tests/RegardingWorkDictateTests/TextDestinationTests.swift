import ApplicationServices
import XCTest
@testable import RegardingWorkDictate

@MainActor
final class TextDestinationTests: XCTestCase {
    func testChangedAppOrFieldBlocksInsertionEvenWhenSelectionMatches() throws {
        let field = AXUIElementCreateApplication(100)
        var focus: TextDestination.FocusSnapshot? = snapshot(element: field)
        let destination = try XCTUnwrap(TextDestination.capture { focus })
        XCTAssertTrue(destination.isStillFocused)
        focus = snapshot(processID: 200, element: field)
        XCTAssertFalse(destination.isStillFocused)
        focus = snapshot(element: AXUIElementCreateApplication(200))
        XCTAssertFalse(destination.isStillFocused)
    }

    func testMovingCursorOrChangingSelectionBlocksInsertion() throws {
        let field = AXUIElementCreateApplication(100)
        var focus: TextDestination.FocusSnapshot? = snapshot(element: field)
        let destination = try XCTUnwrap(TextDestination.capture { focus })
        focus = snapshot(element: field, range: CFRange(location: 12, length: 0))
        XCTAssertFalse(destination.isStillFocused)
        focus = snapshot(element: field, range: CFRange(location: 10, length: 2))
        XCTAssertFalse(destination.isStillFocused)
        focus = snapshot(element: field, range: nil)
        XCTAssertFalse(destination.isStillFocused)
    }

    func testUnavailableOrNonEditableFieldNeverAcceptsText() throws {
        let field = AXUIElementCreateApplication(100)
        XCTAssertNil(TextDestination.capture { nil })
        XCTAssertNil(TextDestination.capture { self.snapshot(element: field, editable: false) })
        var focus: TextDestination.FocusSnapshot? = snapshot(element: field)
        let destination = try XCTUnwrap(TextDestination.capture { focus })
        focus = snapshot(element: field, editable: false)
        XCTAssertFalse(destination.isStillFocused)
        focus = nil
        XCTAssertFalse(destination.isStillFocused)
    }

    private func snapshot(
        processID: pid_t = 100,
        element: AXUIElement,
        range: CFRange? = CFRange(location: 10, length: 0),
        editable: Bool = true
    ) -> TextDestination.FocusSnapshot {
        .init(processID: processID, element: element, selection: range, editable: editable)
    }
}
