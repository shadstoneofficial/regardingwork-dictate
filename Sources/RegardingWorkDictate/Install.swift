import ArgumentParser
import Foundation

/// Installs a per-user LaunchAgent that runs the executable from the signed
/// application bundle. The stable bundle path and signature preserve macOS
/// microphone and Accessibility identity across upgrades.
struct Install: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Install or remove the launch-at-login LaunchAgent."
    )

    @Flag(name: .long, help: "Register RegardingWork Dictate to start at login.")
    var launchAtLogin: Bool = false

    @Flag(name: .long, help: "Remove the launch-at-login agent.")
    var uninstall: Bool = false

    func run() throws {
        guard launchAtLogin != uninstall else {
            FileHandle.standardError.write(Data(
                "specify exactly one of --launch-at-login or --uninstall\n".utf8
            ))
            throw ExitCode(64)
        }
        try uninstall ? removeAgent() : writeAgent()
    }

    private var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents", isDirectory: true)
            .appendingPathComponent("\(AppIdentity.launchAgentIdentifier).plist")
    }

    private func writeAgent() throws {
        let binary = try resolveBinaryPath()
        let paths = AppIdentity.Paths.current
        try SecureFiles.preparePrivateLog(paths.standardOutputLog)
        try SecureFiles.preparePrivateLog(paths.standardErrorLog)

        let plist: [String: Any] = [
            "Label": AppIdentity.launchAgentIdentifier,
            "ProgramArguments": [binary, "run", "--skip-doctor"],
            "RunAtLoad": true,
            "KeepAlive": ["SuccessfulExit": false] as [String: Any],
            "ProcessType": "Interactive",
            "StandardOutPath": paths.standardOutputLog.path,
            "StandardErrorPath": paths.standardErrorLog.path,
            "Umask": 0o077,
        ]

        let url = plistURL
        try SecureFiles.createPrivateDirectory(url.deletingLastPathComponent())
        let data = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )
        try data.write(to: url, options: .atomic)
        try SecureFiles.restrictFile(url)

        _ = runLaunchctl(["bootout", "gui/\(uid())", url.path])
        let result = runLaunchctl(["bootstrap", "gui/\(uid())", url.path])
        if result.status != 0 {
            FileHandle.standardError.write(Data(
                "warning: launchctl bootstrap exited \(result.status):\n\(result.stderr)\n".utf8
            ))
        }

        print("✓ \(AppIdentity.productName) launch-at-login installed")
        print("  plist:  \(url.path)")
        print("  binary: \(binary)")
        print("  logs:   \(paths.logs.path) (private, transcript text is never written)")
    }

    private func removeAgent() throws {
        let url = plistURL
        if FileManager.default.fileExists(atPath: url.path) {
            _ = runLaunchctl(["bootout", "gui/\(uid())", url.path])
            try FileManager.default.removeItem(at: url)
            print("✓ \(AppIdentity.productName) launch-at-login removed")
        } else {
            print("nothing to remove (no agent at \(url.path))")
        }
    }

    private func resolveBinaryPath() throws -> String {
        let installed = "/Applications/\(AppIdentity.productName).app/Contents/MacOS/\(AppIdentity.executableName)"
        if FileManager.default.isExecutableFile(atPath: installed) {
            return installed
        }

        let userInstalled = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications/\(AppIdentity.productName).app/Contents/MacOS")
            .appendingPathComponent(AppIdentity.executableName)
            .path
        if FileManager.default.isExecutableFile(atPath: userInstalled) {
            return userInstalled
        }

        let argv0 = CommandLine.arguments.first ?? AppIdentity.executableName
        if argv0.hasPrefix("/"), FileManager.default.isExecutableFile(atPath: argv0) {
            FileHandle.standardError.write(Data(
                "note: installed app not found; using development executable \(argv0)\n".utf8
            ))
            return argv0
        }

        FileHandle.standardError.write(Data(
            "couldn't locate \(AppIdentity.productName).app. Install the app in /Applications first.\n".utf8
        ))
        throw ExitCode(1)
    }

    private func uid() -> uid_t { getuid() }

    private func runLaunchctl(_ args: [String]) -> (status: Int32, stderr: String) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        task.arguments = args
        let errPipe = Pipe()
        task.standardError = errPipe
        task.standardOutput = Pipe()
        do {
            try task.run()
        } catch {
            return (-1, "\(error)")
        }
        task.waitUntilExit()
        let errorText = String(
            data: errPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
        return (task.terminationStatus, errorText)
    }
}
