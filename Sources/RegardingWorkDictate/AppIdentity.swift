import Foundation

enum AppIdentity {
    static let productName = "RegardingWork Dictate"
    static let productFamily = "RegardingWork Voice"
    static let executableName = "regardingwork-dictate"
    static let bundleIdentifier = "com.regardingwork.dictate"
    static let launchAgentIdentifier = bundleIdentifier
    static let website = URL(string: "https://regardingwork.com")!

    struct Paths: Equatable {
        let applicationSupport: URL
        let configuration: URL
        let models: URL
        let logs: URL
        let standardOutputLog: URL
        let standardErrorLog: URL
        let debugTemporary: URL
        let debugWAV: URL

        init(homeDirectory: URL, temporaryDirectory: URL) {
            applicationSupport = homeDirectory
                .appendingPathComponent("Library/Application Support", isDirectory: true)
                .appendingPathComponent(AppIdentity.productName, isDirectory: true)
            configuration = applicationSupport.appendingPathComponent("config.json")
            models = applicationSupport.appendingPathComponent("Models", isDirectory: true)
            logs = homeDirectory
                .appendingPathComponent("Library/Logs", isDirectory: true)
                .appendingPathComponent(AppIdentity.productName, isDirectory: true)
            standardOutputLog = logs.appendingPathComponent("stdout.log")
            standardErrorLog = logs.appendingPathComponent("stderr.log")
            debugTemporary = temporaryDirectory
                .appendingPathComponent(AppIdentity.bundleIdentifier, isDirectory: true)
            debugWAV = debugTemporary.appendingPathComponent("last-capture.wav")
        }

        static var current: Paths {
            Paths(
                homeDirectory: FileManager.default.homeDirectoryForCurrentUser,
                temporaryDirectory: FileManager.default.temporaryDirectory
            )
        }
    }
}

enum SecureFiles {
    static func createPrivateDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: url.path)
    }

    static func restrictFile(_ url: URL) throws {
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    static func preparePrivateLog(_ url: URL) throws {
        try createPrivateDirectory(url.deletingLastPathComponent())
        if !FileManager.default.fileExists(atPath: url.path) {
            guard FileManager.default.createFile(
                atPath: url.path,
                contents: nil,
                attributes: [.posixPermissions: 0o600]
            ) else {
                throw CocoaError(.fileWriteUnknown)
            }
        }
        try restrictFile(url)
    }
}
