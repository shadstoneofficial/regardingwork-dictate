import XCTest
@testable import RegardingWorkDictate

final class AppIdentityTests: XCTestCase {
    func testRuntimeIdentifiersAreBranded() {
        XCTAssertEqual(AppIdentity.executableName, "regardingwork-dictate")
        XCTAssertEqual(AppIdentity.bundleIdentifier, "com.regardingwork.dictate")
        XCTAssertEqual(AppIdentity.launchAgentIdentifier, "com.regardingwork.dictate")
    }

    func testPathsUseBrandedPrivateLocations() {
        let paths = AppIdentity.Paths(
            homeDirectory: URL(fileURLWithPath: "/Users/tester"),
            temporaryDirectory: URL(fileURLWithPath: "/private/tmp")
        )

        XCTAssertEqual(
            paths.configuration.path,
            "/Users/tester/Library/Application Support/RegardingWork Dictate/config.json"
        )
        XCTAssertEqual(
            paths.standardErrorLog.path,
            "/Users/tester/Library/Logs/RegardingWork Dictate/stderr.log"
        )
        XCTAssertEqual(
            paths.debugWAV.path,
            "/private/tmp/com.regardingwork.dictate/last-capture.wav"
        )
    }

    func testPrivateFilesUseRestrictivePermissions() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("RegardingWorkDictateTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let log = root.appendingPathComponent("Logs/stderr.log")

        try SecureFiles.preparePrivateLog(log)

        let directoryAttributes = try FileManager.default.attributesOfItem(
            atPath: log.deletingLastPathComponent().path
        )
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: log.path)
        XCTAssertEqual(directoryAttributes[.posixPermissions] as? Int, 0o700)
        XCTAssertEqual(fileAttributes[.posixPermissions] as? Int, 0o600)
    }
}
