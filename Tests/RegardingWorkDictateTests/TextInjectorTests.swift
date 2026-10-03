import XCTest
@testable import RegardingWorkDictate

final class TextInjectorTests: XCTestCase {
    func testChunkingPreservesThaiCombiningMarksAndEmoji() {
        let text = String(repeating: "ข้อความภาษาไทย 👩🏽‍💻 🚀 ", count: 10)
        let chunks = TextInjector.chunks(for: text)
        XCTAssertEqual(chunks.flatMap { $0 }, Array(text.utf16))
        XCTAssertEqual(chunks.map { String(decoding: $0, as: UTF16.self) }.joined(), text)
        XCTAssertTrue(chunks.allSatisfy { !$0.isEmpty && $0.count <= 20 })
    }

    func testSurrogatePairAtChunkBoundaryIsKeptTogether() {
        let text = String(repeating: "a", count: 19) + "🚀end"
        let chunks = TextInjector.chunks(for: text)
        XCTAssertEqual(chunks[0].count, 19)
        XCTAssertEqual(chunks.map { String(decoding: $0, as: UTF16.self) }.joined(), text)
    }

    func testEmptyTextCreatesNoEvents() {
        XCTAssertEqual(TextInjector.chunks(for: ""), [])
        XCTAssertFalse(TextInjector.inject(""))
    }
}
