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
        TranscriptionModel(
            id: "multilingual",
            displayName: "Multilingual",
            engine: .whisperKit,
            whisperKitID: "multilingual",
            sizeMB: 3,
            languages: ["multi"],
            recommended: false
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

    func testThaiSelectsMultilingualModel() {
        XCTAssertEqual(
            ModelRegistry.select(id: nil, language: .thai, from: models)?.id,
            "multilingual"
        )
        XCTAssertEqual(
            ModelRegistry.select(id: "recommended", language: .thai, from: models)?.id,
            "multilingual"
        )
    }

    func testEnglishKeepsRecommendedEnglishModel() {
        XCTAssertEqual(
            ModelRegistry.select(id: nil, language: .english, from: models)?.id,
            "recommended"
        )
    }
}
