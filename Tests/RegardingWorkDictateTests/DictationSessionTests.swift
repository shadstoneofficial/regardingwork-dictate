import XCTest
@testable import RegardingWorkDictate

final class DictationSessionTests: XCTestCase {
    func testRapidPressAndReleaseCannotCreateOverlappingTranscriptions() {
        var session = DictationSession()
        let first = session.begin()!
        XCTAssertNil(session.begin())
        XCTAssertEqual(session.release(), first)
        XCTAssertNil(session.begin())
        XCTAssertNil(session.release())
        XCTAssertTrue(session.complete(first))
        XCTAssertNotNil(session.begin())
    }

    func testReleaseWithoutPressAndWrongCompletionAreIgnored() {
        var session = DictationSession()
        XCTAssertNil(session.release())
        let id = session.begin()!
        XCTAssertFalse(session.complete(id)) // still listening
        XCTAssertEqual(session.release(), id)
        XCTAssertFalse(session.complete(UUID()))
        XCTAssertEqual(session.state, .processing(id))
    }

    func testCancelledSessionCannotInsertAfterNewSessionStarts() {
        var session = DictationSession()
        let old = session.begin()!
        _ = session.release()
        session.cancel()
        let current = session.begin()!
        _ = session.release()
        XCTAssertFalse(session.complete(old))
        XCTAssertEqual(session.state, .processing(current))
        XCTAssertTrue(session.complete(current))
        XCTAssertFalse(session.complete(current))
    }

    func testNoSignalAndBriefTapDoNotReachTranscription() {
        XCTAssertEqual(CapturedAudioAssessment.assess([]), .tooShort)
        XCTAssertEqual(CapturedAudioAssessment.assess(Array(repeating: 0.2, count: 1000)), .tooShort)
        XCTAssertEqual(CapturedAudioAssessment.assess(Array(repeating: 0, count: 16_000)), .tooQuiet)
        XCTAssertEqual(CapturedAudioAssessment.assess(Array(repeating: 0.0001, count: 16_000)), .tooQuiet)
    }

    func testQuietUtteranceWithLongPausesIsNotDiscarded() {
        var samples = Array(repeating: Float(0), count: 160_000)
        samples.replaceSubrange(32_000..<33_600, with: repeatElement(Float(0.005), count: 1600))
        XCTAssertEqual(CapturedAudioAssessment.assess(samples), .usable)
    }

    func testBlockedTextExpiresAndCannotBeRecoveredAfterDismissal() {
        let now = Date(timeIntervalSince1970: 1000)
        var pending = PendingDictation()
        pending.store("ข้อความทดสอบ", now: now)
        XCTAssertEqual(pending.text(now: now.addingTimeInterval(59)), "ข้อความทดสอบ")
        XCTAssertNil(pending.text(now: now.addingTimeInterval(60)))
        XCTAssertNil(pending.text(now: now)) // expired result cannot reappear
        pending.store("Temporary example", now: now)
        pending.clear()
        XCTAssertNil(pending.text(now: now))
    }

    func testRecoveryHoldsOnlyTheLatestBlockedResult() {
        let now = Date(timeIntervalSince1970: 1000)
        var pending = PendingDictation()
        pending.store("First example", now: now)
        pending.store("Second example", now: now)
        XCTAssertEqual(pending.text(now: now), "Second example")
        pending.store("", now: now)
        XCTAssertNil(pending.text(now: now))
    }
}
