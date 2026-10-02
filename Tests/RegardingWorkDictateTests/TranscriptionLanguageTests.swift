import XCTest
@testable import RegardingWorkDictate

final class TranscriptionLanguageTests: XCTestCase {
    func testLanguageIdentityAndDisplayNames() {
        XCTAssertEqual(TranscriptionLanguage.english.rawValue, "en")
        XCTAssertEqual(TranscriptionLanguage.english.displayName, "English")
        XCTAssertEqual(TranscriptionLanguage.thai.rawValue, "th")
        XCTAssertEqual(TranscriptionLanguage.thai.displayName, "Thai")
    }

    func testThaiUsesExplicitLanguageWithoutAutomaticDetection() {
        let options = WhisperKitTranscriber.decodingOptions(for: .thai)
        XCTAssertEqual(options.language, "th")
        XCTAssertFalse(options.detectLanguage)
        XCTAssertTrue(options.usePrefillPrompt)
    }
}
