import XCTest
@testable import RegardingWorkDictate

final class ModelRegistryTests: XCTestCase {
    private let models = [
        TranscriptionModel(
            id: "first",
            displayName: "First",
            engine: .whisperKit,
            whisperKitID: "first",
            sizeMB: 1,
            languages: ["en"],
            recommended: false
        ),
        TranscriptionModel(
            id: "recommended",
            displayName: "Recommended",
            engine: .whisperKit,
            whisperKitID: "recommended",
            sizeMB: 2,
            languages: ["en"],
            recommended: true
        ),
    ]

    func testExplicitSelectionWins() {
        XCTAssertEqual(ModelRegistry.select(id: "first", from: models)?.id, "first")
    }

    func testRecommendedSelectionIsDefault() {
        XCTAssertEqual(ModelRegistry.select(id: nil, from: models)?.id, "recommended")
    }

    func testUnknownAndEmptySelectionsFailSafely() {
        XCTAssertNil(ModelRegistry.select(id: "missing", from: models))
        XCTAssertNil(ModelRegistry.select(id: nil, from: []))
    }
}
