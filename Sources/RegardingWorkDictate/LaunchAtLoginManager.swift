import Foundation
import ServiceManagement

enum LaunchAtLoginStatus: Equatable {
    case disabled
    case enabled
    case requiresApproval
    case unavailable

    var isSelected: Bool {
        self == .enabled || self == .requiresApproval
    }
}

protocol LaunchAtLoginService {
    var status: LaunchAtLoginStatus { get }
    func register() throws
    func unregister() throws
    func openSystemSettings()
}

struct SystemLaunchAtLoginService: LaunchAtLoginService {
    private var service: SMAppService { .mainApp }

    var status: LaunchAtLoginStatus {
        switch service.status {
        case .notRegistered:
            return .disabled
        case .enabled:
            return .enabled
        case .requiresApproval:
            return .requiresApproval
        case .notFound:
            return .unavailable
        @unknown default:
            return .unavailable
        }
    }

    func register() throws {
        try service.register()
    }

    func unregister() throws {
        try service.unregister()
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}

struct LegacyLaunchAgentStore {
    let plistURL: URL

    init(homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) {
        plistURL = homeDirectory
            .appendingPathComponent("Library/LaunchAgents", isDirectory: true)
            .appendingPathComponent("\(AppIdentity.launchAgentIdentifier).plist")
    }

    var isInstalled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    /// Removes only the obsolete registration file. It intentionally does not
    /// boot out the current job, because doing so would terminate an app that
    /// was launched by the legacy agent. The job disappears at logout, while
    /// the native login item takes effect at the next login.
    func removeRegistrationFile() throws {
        guard isInstalled else { return }
        try FileManager.default.removeItem(at: plistURL)
    }
}

struct LaunchAtLoginManager {
    private let service: LaunchAtLoginService
    private let legacyStore: LegacyLaunchAgentStore

    init(
        service: LaunchAtLoginService = SystemLaunchAtLoginService(),
        legacyStore: LegacyLaunchAgentStore = LegacyLaunchAgentStore()
    ) {
        self.service = service
        self.legacyStore = legacyStore
    }

    var status: LaunchAtLoginStatus {
        let nativeStatus = service.status
        if (nativeStatus == .disabled || nativeStatus == .unavailable),
           legacyStore.isInstalled {
            return .enabled
        }
        return nativeStatus
    }

    func migrateLegacyIfNeeded() throws {
        guard legacyStore.isInstalled else { return }

        switch service.status {
        case .disabled:
            try service.register()
            try legacyStore.removeRegistrationFile()
        case .enabled, .requiresApproval:
            try legacyStore.removeRegistrationFile()
        case .unavailable:
            // Keep the working legacy registration when the native service is
            // unavailable, such as in an unsigned development bundle.
            break
        }
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            switch service.status {
            case .enabled:
                break
            case .requiresApproval:
                service.openSystemSettings()
                return
            case .disabled, .unavailable:
                try service.register()
            }
            try legacyStore.removeRegistrationFile()
            return
        }

        let nativeStatus = service.status
        if nativeStatus == .enabled || nativeStatus == .requiresApproval {
            try service.unregister()
        }
        try legacyStore.removeRegistrationFile()
    }

    func openSystemSettings() {
        service.openSystemSettings()
    }
}
