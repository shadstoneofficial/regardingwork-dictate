import CoreGraphics
import XCTest
@testable import RegardingWorkDictate

final class HotkeyTests: XCTestCase {
    func testEveryChoiceHasDistinctKeycodeAndRoundTrips() throws {
        XCTAssertEqual(Set(HotkeyKey.allCases.map(\.keycode)).count, 9)
        for key in HotkeyKey.allCases {
            var config = AppConfig.default
            config.hotkey = key
            XCTAssertEqual(try JSONDecoder().decode(AppConfig.self, from: JSONEncoder().encode(config)), config)
        }
    }

    func testOldConfigurationUsesFnAndInvalidNameIsRejected() throws {
        let old = try JSONDecoder().decode(AppConfig.self, from: Data(#"{"version":1}"#.utf8))
        XCTAssertEqual(old.hotkey, .fn)
        XCTAssertThrowsError(try JSONDecoder().decode(AppConfig.self, from: Data(#"{"hotkey":"space"}"#.utf8)))
    }

    func testSideSpecificKeysIgnoreOppositeSideAtPress() {
        for key in HotkeyKey.allCases where key != .fn {
            let opposite = HotkeyKey.allCases.first { $0.flag == key.flag && $0 != key }!
            XCTAssertNil(HotkeyMonitor.input(keycode: opposite.keycode, flags: key.flag, key: key, held: false))
            XCTAssertEqual(HotkeyMonitor.input(keycode: key.keycode, flags: key.flag, key: key, held: false), .hotkeyDown(othersHeld: false))
            // The selected side's release still counts if the other side holds
            // their shared flag. Another modifier instead cancels the gesture.
            XCTAssertEqual(HotkeyMonitor.input(keycode: key.keycode, flags: key.flag, key: key, held: true), .hotkeyUp)
            XCTAssertEqual(HotkeyMonitor.input(keycode: opposite.keycode, flags: key.flag, key: key, held: true), .otherModifier)
        }
    }

    func testFnAndChordMatching() {
        XCTAssertEqual(HotkeyMonitor.input(keycode: 63, flags: .maskSecondaryFn, key: .fn, held: false), .hotkeyDown(othersHeld: false))
        XCTAssertEqual(HotkeyMonitor.input(keycode: 61, flags: [.maskAlternate, .maskCommand], key: .rightOption, held: false), .hotkeyDown(othersHeld: true))
        XCTAssertEqual(HotkeyMonitor.input(keycode: 61, flags: [.maskAlternate, .maskSecondaryFn], key: .rightOption, held: false), .hotkeyDown(othersHeld: true))
        XCTAssertEqual(HotkeyMonitor.input(keycode: 55, flags: [.maskAlternate, .maskCommand], key: .rightOption, held: true), .otherModifier)
        XCTAssertEqual(HotkeyMonitor.input(keycode: 0, flags: [], key: .rightOption, held: true), .hotkeyUp)
    }

    func testTapIsCancelledAndValidHoldTranscribes() {
        var gesture = Gesture()
        XCTAssertEqual(gesture.handle(.hotkeyDown(othersHeld: false), at: 0), .start)
        XCTAssertEqual(gesture.handle(.hotkeyUp, at: 0.1), .cancel)
        XCTAssertFalse(gesture.isHeld)
        XCTAssertEqual(gesture.handle(.hotkeyDown(othersHeld: false), at: 1), .start)
        XCTAssertEqual(gesture.handle(.hotkeyUp, at: 1.5), .transcribe)
    }

    func testChordIsIgnoredUntilRelease() {
        var gesture = Gesture()
        XCTAssertNil(gesture.handle(.hotkeyDown(othersHeld: true), at: 0))
        XCTAssertNil(gesture.handle(.hotkeyUp, at: 1))
        XCTAssertEqual(gesture.handle(.hotkeyDown(othersHeld: false), at: 2), .start)
        XCTAssertEqual(gesture.handle(.otherModifier, at: 2.2), .cancel)
        XCTAssertNil(gesture.handle(.hotkeyDown(othersHeld: false), at: 2.3))
        XCTAssertNil(gesture.handle(.hotkeyUp, at: 3))
        XCTAssertFalse(gesture.isHeld)
    }

    func testMinimumHoldBoundaryTranscribes() {
        var gesture = Gesture()
        _ = gesture.handle(.hotkeyDown(othersHeld: false), at: 0)
        XCTAssertEqual(gesture.handle(.hotkeyUp, at: Gesture.minimumHold), .transcribe)
    }

    func testResetCancelsRecordingAndUnmatchedEdgesDoNothing() {
        var gesture = Gesture()
        XCTAssertNil(gesture.handle(.hotkeyUp, at: 0))
        XCTAssertEqual(gesture.handle(.hotkeyDown(othersHeld: false), at: 1), .start)
        XCTAssertNil(gesture.handle(.hotkeyDown(othersHeld: false), at: 1.1))
        XCTAssertEqual(gesture.reset(), .cancel)
        XCTAssertNil(gesture.handle(.hotkeyUp, at: 2))
        XCTAssertNil(gesture.reset())
    }

    func testMonitorSwitchResetsOldGesture() {
        let monitor = HotkeyMonitor()
        monitor.setKey(.rightOption)
        XCTAssertEqual(monitor.key, .rightOption)
        monitor.setKey(.rightOption)
        XCTAssertEqual(monitor.key, .rightOption)
    }

    func testCLIValidatesHotkeyWithoutStartingApplication() throws {
        let run = try Run.parse(["--hotkey", "right-option"])
        XCTAssertEqual(run.hotkey, "right-option")
        XCTAssertThrowsError(try Run.parse(["--hotkey", "space"]))
    }

    func testDoctorDoesNotCheckFnMappingForAnotherKey() {
        XCTAssertFalse(DoctorReport.run(hotkey: .rightOption).contains { $0.name == "fn key mapping" })
    }
}
