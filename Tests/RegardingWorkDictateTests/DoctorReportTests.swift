import XCTest
@testable import RegardingWorkDictate

final class DoctorReportTests: XCTestCase {
    func testRuntimeBlocksOnPermissionFailuresOnly() {
        let checks = [
            Check(name: "microphone", status: .ok, remediation: nil),
            Check(name: "accessibility", status: .fail("not granted"), remediation: nil),
            Check(name: "fn key mapping", status: .fail("system action enabled"), remediation: nil),
        ]

        let failures = DoctorReport.runtimePermissionFailures(checks)
        XCTAssertEqual(failures.map(\.name), ["accessibility"])
    }

    func testFnMappingDoesNotMakeAppLaunchFail() {
        let checks = [
            Check(name: "microphone", status: .ok, remediation: nil),
            Check(name: "accessibility", status: .ok, remediation: nil),
            Check(name: "fn key mapping", status: .fail("system action enabled"), remediation: nil),
        ]

        XCTAssertTrue(DoctorReport.runtimePermissionFailures(checks).isEmpty)
        XCTAssertFalse(DoctorReport.allOK(checks))
    }
}
