import XCTest
@testable import RegardingWorkDictate

final class ModelPreparationTests: XCTestCase {
    func testOneAttemptAtATime() throws {
        var session = ModelPreparationSession()
        XCTAssertEqual(session.progress, .checking)
        let id = try XCTUnwrap(session.begin())
        XCTAssertNil(session.begin())
        session.finish(id)
        XCTAssertNotNil(session.begin())
    }

    func testUnknownDownloadHasNoMadeUpPercentage() throws {
        var session = ModelPreparationSession()
        let id = try XCTUnwrap(session.begin())
        XCTAssertTrue(session.accept(.downloading(nil), for: id))
        XCTAssertEqual(session.progress, .downloading(nil))
        XCTAssertFalse(session.progress.message.contains("%"))
    }

    func testWholePercentUpdatesAndDuplicateCoalescing() throws {
        var session = ModelPreparationSession()
        let id = try XCTUnwrap(session.begin())
        XCTAssertTrue(session.accept(.downloading(0.426), for: id))
        XCTAssertEqual(session.progress, .downloading(42))
        XCTAssertFalse(session.accept(.downloading(0.429), for: id))
        XCTAssertTrue(session.accept(.downloading(0.44), for: id))
    }

    func testOutOfOrderCallbacksNeverMoveProgressBackwards() throws {
        var session = ModelPreparationSession()
        let id = try XCTUnwrap(session.begin())
        _ = session.accept(.downloading(0.8), for: id)
        XCTAssertFalse(session.accept(.downloading(0.1), for: id))
        XCTAssertFalse(session.accept(.downloading(nil), for: id))
        XCTAssertEqual(session.progress, .downloading(80))
    }

    func testBoundsAndNonFiniteValues() throws {
        var session = ModelPreparationSession()
        let id = try XCTUnwrap(session.begin())
        for invalid in [Double.nan, .infinity, -.infinity] {
            XCTAssertFalse(session.accept(.downloading(invalid), for: id))
        }
        XCTAssertEqual(session.progress, .checking)
        XCTAssertTrue(session.accept(.downloading(-0.5), for: id))
        XCTAssertEqual(session.progress, .downloading(0))
        XCTAssertTrue(session.accept(.downloading(1.5), for: id))
        XCTAssertEqual(session.progress, .downloading(100))
    }

    func testTransferCompletionIsNotModelReadiness() throws {
        var session = ModelPreparationSession()
        let id = try XCTUnwrap(session.begin())
        _ = session.accept(.downloading(1), for: id)
        XCTAssertEqual(session.progress, .downloading(100))
        XCTAssertTrue(session.accept(.loading, for: id))
        XCTAssertEqual(session.progress, .loading)
        XCTAssertEqual(session.attemptID, id)
        XCTAssertFalse(session.accept(.loading, for: id))
        XCTAssertFalse(session.accept(.downloading(0.99), for: id))
        session.finish(id)
        XCTAssertNil(session.attemptID)
    }

    func testCancellationRejectsCallbacksAndWaitsForFinishBeforeRetry() throws {
        var session = ModelPreparationSession()
        let id = try XCTUnwrap(session.begin())
        XCTAssertTrue(session.cancel(id))
        XCTAssertFalse(session.cancel(id))
        XCTAssertTrue(session.isCancelled)
        XCTAssertFalse(session.accept(.loading, for: id))
        XCTAssertFalse(session.accept(.downloading(0.5), for: id))
        XCTAssertNil(session.begin())
        session.finish(id)
        let retry = try XCTUnwrap(session.begin())
        XCTAssertNotEqual(id, retry)
        XCTAssertFalse(session.isCancelled)
        XCTAssertEqual(session.progress, .checking)
    }

    func testOldAttemptCannotAffectNewAttempt() throws {
        var session = ModelPreparationSession()
        let old = try XCTUnwrap(session.begin())
        session.finish(old)
        let current = try XCTUnwrap(session.begin())
        XCTAssertFalse(session.accept(.loading, for: old))
        XCTAssertFalse(session.cancel(old))
        session.finish(old)
        XCTAssertEqual(session.attemptID, current)
        XCTAssertTrue(session.accept(.downloading(0.5), for: current))
    }

    func testFinishedAttemptRejectsLateCallbacks() throws {
        var session = ModelPreparationSession()
        let id = try XCTUnwrap(session.begin())
        session.finish(id)
        XCTAssertFalse(session.accept(.loading, for: id))
        XCTAssertFalse(session.cancel(id))
    }
}
