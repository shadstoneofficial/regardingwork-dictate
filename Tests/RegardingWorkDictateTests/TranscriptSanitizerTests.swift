import XCTest
@testable import RegardingWorkDictate

final class TranscriptSanitizerTests: XCTestCase {
    func testRemovesKnownNonSpeechAndControlTokens() {
        let input = " Hello [BLANK_AUDIO] (music playing) <|nospeech|> *background noise* world. "
        XCTAssertEqual(TranscriptSanitizer.sanitize(input), "Hello world.")
    }

    func testPreservesLegitimateBracketsParenthesesAndEmphasis() {
        let input = "Use [draft] (not final) and *important*."
        XCTAssertEqual(TranscriptSanitizer.sanitize(input), input)
    }

    func testCollapsesWhitespace() {
        XCTAssertEqual(TranscriptSanitizer.sanitize("one\n\t two   three"), "one two three")
    }
}
