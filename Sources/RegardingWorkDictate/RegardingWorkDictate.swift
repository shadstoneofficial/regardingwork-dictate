import AppKit
import ArgumentParser
import Foundation
import WhisperKit

@main
struct RegardingWorkDictate: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: AppIdentity.executableName,
        abstract: "Private, on-device macOS push-to-talk dictation from RegardingWork Voice.",
        subcommands: [Run.self, Setup.self, Doctor.self, Models.self, Install.self],
        defaultSubcommand: Run.self
    )
}

struct Run: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Run the menu-bar app (default)."
    )

    @Flag(name: .long, help: "Skip permission checks at startup.")
    var skipDoctor: Bool = false

    @Flag(name: .long, help: "Print modifier-state changes for hotkey debugging.")
    var debugHotkey: Bool = false

    @Flag(name: .long, help: "Write the latest capture to a private temporary WAV file.")
    var dumpWav: Bool = false

    @Flag(name: .long, help: "Disable the on-screen recording overlay.")
    var noOverlay: Bool = false

    @Option(name: .long, help: "Model id to use. Defaults to the recommended model.")
    var model: String?

    @Option(name: .long, help: "Configuration JSON path. Defaults to Application Support.")
    var config: String?

    func run() throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)

        let options = RuntimeOptions(
            skipDoctor: skipDoctor,
            debugHotkey: debugHotkey,
            dumpWAV: dumpWav,
            noOverlay: noOverlay,
            modelID: model,
            configurationPath: config
        )
        let coordinator = MainActor.assumeIsolated {
            ApplicationCoordinator(options: options)
        }
        MainActor.assumeIsolated {
            coordinator.start()
        }

        app.run()
        withExtendedLifetime(coordinator) {}
    }
}

struct Doctor: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Check microphone, accessibility, and Fn key configuration."
    )

    func run() throws {
        let checks = DoctorReport.run()
        DoctorReport.print(checks)
        if !DoctorReport.allOK(checks) {
            throw ExitCode(1)
        }
    }
}

struct Models: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Manage transcription models.",
        subcommands: [List.self, Download.self]
    )

    struct List: ParsableCommand {
        func run() throws {
            for model in ModelRegistry.shared {
                let star = model.recommended ? "★" : " "
                let id = model.id.padding(toLength: 26, withPad: " ", startingAt: 0)
                let languages = "[\(model.languages.joined(separator: ","))]"
                    .padding(toLength: 9, withPad: " ", startingAt: 0)
                let size = String(format: "%5d MB", model.sizeMB)
                print("\(star) \(id) \(size)  \(languages)  \(model.displayName)")
            }
        }
    }

    struct Download: ParsableCommand {
        @Argument(help: "Model id to download.") var id: String

        func run() throws {
            guard let model = ModelRegistry.find(id) else {
                print("unknown model: \(id)")
                throw ExitCode(1)
            }
            let transcriber = WhisperKitTranscriber(model: model)

            let semaphore = DispatchSemaphore(value: 0)
            var capturedError: Error?
            Task.detached {
                do {
                    try await transcriber.warmUp()
                } catch {
                    capturedError = error
                }
                semaphore.signal()
            }
            semaphore.wait()
            if let capturedError {
                throw capturedError
            }
        }
    }
}
