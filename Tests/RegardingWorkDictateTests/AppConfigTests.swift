import XCTest
@testable import RegardingWorkDictate

final class AppConfigTests: XCTestCase {
    func testMissingFileUsesPrivacyPreservingDefaults() throws {
        let url = URL(fileURLWithPath: "/path/that/does/not/exist/config.json")
        XCTAssertEqual(try AppConfig.load(from: url), .default)
        XCTAssertFalse(AppConfig.default.debugHotkey)
        XCTAssertFalse(AppConfig.default.dumpWAV)
        XCTAssertFalse(AppConfig.default.feedbackSounds)
        XCTAssertTrue(AppConfig.default.overlay)
        XCTAssertEqual(AppConfig.default.language, .english)
    }

    func testDecodesVersionedConfiguration() throws {
        let data = Data(
            """
            {
              "version": 1,
              "model": "whisper-small.en",
              "language": "th",
              "overlay": false,
              "debug_hotkey": true,
              "dump_wav": true
            }
            """.utf8
        )

        let config = try JSONDecoder().decode(AppConfig.self, from: data)
        XCTAssertEqual(config.model, "whisper-small.en")
        XCTAssertEqual(config.language, .thai)
        XCTAssertFalse(config.overlay)
        XCTAssertTrue(config.debugHotkey)
        XCTAssertTrue(config.dumpWAV)
    }

    func testExistingConfigurationWithoutLanguageDefaultsToEnglish() throws {
        let data = Data(#"{"version":1}"#.utf8)
        let config = try JSONDecoder().decode(AppConfig.self, from: data)
        XCTAssertEqual(config.language, .english)
        XCTAssertFalse(config.feedbackSounds)
    }

    func testFeedbackSoundsAreOptInAndRoundTripWithoutBreakingExistingConfig() throws {
        var config = AppConfig.default
        config.feedbackSounds = true
        let data = try JSONEncoder().encode(config)
        XCTAssertEqual(try JSONDecoder().decode(AppConfig.self, from: data), config)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["feedback_sounds"] as? Bool, true)
    }

    func testSavesLanguageWithPrivatePermissions() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("config.json")
        var config = AppConfig.default
        config.language = .thai

        try config.save(to: url)

        XCTAssertEqual(try AppConfig.load(from: url).language, .thai)
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        XCTAssertEqual((attributes[.posixPermissions] as? NSNumber)?.intValue, 0o600)
    }

    func testRejectsUnsupportedConfigurationVersion() {
        let data = Data(#"{"version":2}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(AppConfig.self, from: data)) { error in
            XCTAssertEqual(error as? AppConfig.ConfigError, .unsupportedVersion(2))
        }
    }
}
