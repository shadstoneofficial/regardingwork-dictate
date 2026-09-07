import Foundation
import XCTest
@testable import RegardingWorkDictate

final class LaunchAtLoginManagerTests: XCTestCase {
    func testDisabledServiceReportsEnabledWhenLegacyAgentExists() throws {
        let fixture = try Fixture(legacyInstalled: true)
        defer { fixture.cleanup() }
        let service = FakeLaunchAtLoginService(status: .disabled)
        let manager = LaunchAtLoginManager(service: service, legacyStore: fixture.store)

        XCTAssertEqual(manager.status, .enabled)
    }

    func testEnablingRegistersNativeServiceAndRemovesLegacyFile() throws {
        let fixture = try Fixture(legacyInstalled: true)
        defer { fixture.cleanup() }
        let service = FakeLaunchAtLoginService(status: .disabled)
        let manager = LaunchAtLoginManager(service: service, legacyStore: fixture.store)

        try manager.setEnabled(true)

        XCTAssertEqual(service.registerCount, 1)
        XCTAssertEqual(service.status, .enabled)
        XCTAssertFalse(fixture.store.isInstalled)
    }

    func testMigrationPreservesLegacyPreferenceUsingNativeService() throws {
        let fixture = try Fixture(legacyInstalled: true)
        defer { fixture.cleanup() }
        let service = FakeLaunchAtLoginService(status: .disabled)
        let manager = LaunchAtLoginManager(service: service, legacyStore: fixture.store)

        try manager.migrateLegacyIfNeeded()

        XCTAssertEqual(service.registerCount, 1)
        XCTAssertEqual(service.status, .enabled)
        XCTAssertFalse(fixture.store.isInstalled)
    }

    func testMigrationKeepsLegacyFileWhenNativeServiceIsUnavailable() throws {
        let fixture = try Fixture(legacyInstalled: true)
        defer { fixture.cleanup() }
        let service = FakeLaunchAtLoginService(status: .unavailable)
        let manager = LaunchAtLoginManager(service: service, legacyStore: fixture.store)

        try manager.migrateLegacyIfNeeded()

        XCTAssertEqual(service.registerCount, 0)
        XCTAssertTrue(fixture.store.isInstalled)
    }

    func testDisablingUnregistersNativeServiceAndRemovesLegacyFile() throws {
        let fixture = try Fixture(legacyInstalled: true)
        defer { fixture.cleanup() }
        let service = FakeLaunchAtLoginService(status: .enabled)
        let manager = LaunchAtLoginManager(service: service, legacyStore: fixture.store)

        try manager.setEnabled(false)

        XCTAssertEqual(service.unregisterCount, 1)
        XCTAssertEqual(service.status, .disabled)
        XCTAssertFalse(fixture.store.isInstalled)
    }

    func testApprovalRequiredOpensLoginItemsInsteadOfRegisteringAgain() throws {
        let fixture = try Fixture(legacyInstalled: false)
        defer { fixture.cleanup() }
        let service = FakeLaunchAtLoginService(status: .requiresApproval)
        let manager = LaunchAtLoginManager(service: service, legacyStore: fixture.store)

        try manager.setEnabled(true)

        XCTAssertEqual(service.openSettingsCount, 1)
        XCTAssertEqual(service.registerCount, 0)
    }
}

private final class FakeLaunchAtLoginService: LaunchAtLoginService {
    var status: LaunchAtLoginStatus
    var registerCount = 0
    var unregisterCount = 0
    var openSettingsCount = 0

    init(status: LaunchAtLoginStatus) {
        self.status = status
    }

    func register() throws {
        registerCount += 1
        status = .enabled
    }

    func unregister() throws {
        unregisterCount += 1
        status = .disabled
    }

    func openSystemSettings() {
        openSettingsCount += 1
    }
}

private struct Fixture {
    let home: URL
    let store: LegacyLaunchAgentStore

    init(legacyInstalled: Bool) throws {
        home = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        store = LegacyLaunchAgentStore(homeDirectory: home)
        if legacyInstalled {
            try FileManager.default.createDirectory(
                at: store.plistURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data("legacy".utf8).write(to: store.plistURL)
        }
    }

    func cleanup() {
        try? FileManager.default.removeItem(at: home)
    }
}
