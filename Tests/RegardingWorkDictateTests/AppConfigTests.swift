import XCTest
@testable import RegardingWorkDictate

final class AppConfigTests: XCTestCase {
    func testMissingFileUsesPrivacyPreservingDefaults() throws {
        let url = URL(fileURLWithPath: "/path/that/does/not/exist/config.json")
        XCTAssertEqual(try AppConfig.load(from: url), .default)
        XCTAssertFalse(AppConfig.default.debugHotkey)
        XCTAssertFalse(AppConfig.default.dumpWAV)
        XCTAssertTrue(AppConfig.default.overlay)
    }

    func testDecodesVersionedConfiguration() throws {
        let data = Data(
            """
            {
              "version": 1,
              "model": "whisper-small.en",
              "overlay": false,
              "debug_hotkey": true,
              "dump_wav": true
            }
            """.utf8
        )

        let config = try JSONDecoder().decode(AppConfig.self, from: data)
        XCTAssertEqual(config.model, "whisper-small.en")
        XCTAssertFalse(config.overlay)
        XCTAssertTrue(config.debugHotkey)
        XCTAssertTrue(config.dumpWAV)
    }

    func testRejectsUnsupportedConfigurationVersion() {
        let data = Data(#"{"version":2}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(AppConfig.self, from: data)) { error in
            XCTAssertEqual(error as? AppConfig.ConfigError, .unsupportedVersion(2))
        }
    }
}
