import AppKit
import ApplicationServices
import AVFoundation
import Foundation

@MainActor
final class ApplicationCoordinator: NSObject, NSApplicationDelegate {
    private enum StartupState {
        case checking
        case permissions([Check])
        case preparing(modelID: String, displayName: String)
        case ready(modelID: String)
        case failed(String)
    }

    private struct ResolvedSettings {
        let model: TranscriptionModel
        let debugHotkey: Bool
        let dumpWAV: Bool
        let overlay: Bool
    }

    private let options: RuntimeOptions
    private let menuBar = MenuBarController()
    private let setupWindow = SetupWindowController()
    private var startupState: StartupState = .checking
    private var preparationTask: Task<Void, Never>?
    private var signalSource: DispatchSourceSignal?

    private var monitor: HotkeyMonitor?
    private var capture: AudioCapture?
    private var overlay: RecordingOverlay?
    private var transcriber: WhisperKitTranscriber?
    private var activeModelID: String?
    private var dumpWAVEnabled = false

    init(options: RuntimeOptions) {
        self.options = options
        super.init()
    }

    func start() {
        NSApp.delegate = self
        menuBar.onShowSetup = { [weak self] in
            self?.renderStartupState(autoDismissReady: false)
        }
        installSignalHandler()
        transition(to: .checking)
        beginPreparation()
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        renderStartupState(autoDismissReady: false)
        return true
    }

    private func beginPreparation() {
        guard preparationTask == nil else { return }
        preparationTask = Task { [weak self] in
            guard let self else { return }
            await self.prepare()
            self.preparationTask = nil
        }
    }

    private func prepare() async {
        transition(to: .checking)

        do {
            let settings = try resolveSettings()

            if !options.skipDoctor {
                await requestMicrophoneIfNeeded()
                requestAccessibilityIfNeeded()

                let checks = DoctorReport.run()
                let failures = DoctorReport.runtimePermissionFailures(checks)
                guard failures.isEmpty else {
                    transition(to: .permissions(failures))
                    return
                }
            }

            transition(to: .preparing(
                modelID: settings.model.id,
                displayName: settings.model.displayName
            ))

            let transcriber = WhisperKitTranscriber(model: settings.model)
            try await transcriber.warmUp()
            try startRuntime(transcriber: transcriber, settings: settings)

            transition(to: .ready(modelID: settings.model.id))
        } catch {
            transition(to: .failed(Self.userFacingMessage(for: error)))
        }
    }

    private func resolveSettings() throws -> ResolvedSettings {
        let configURL = options.configurationPath.map {
            URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath)
        } ?? AppIdentity.Paths.current.configuration

        let storedConfig: AppConfig
        do {
            storedConfig = try AppConfig.load(from: configURL)
        } catch {
            throw StartupError.configuration(path: configURL.path, underlying: error)
        }

        let selectedModelID = options.modelID ?? storedConfig.model
        guard let model = ModelRegistry.select(id: selectedModelID) else {
            if let selectedModelID {
                throw StartupError.unknownModel(selectedModelID)
            }
            throw StartupError.noModels
        }

        return ResolvedSettings(
            model: model,
            debugHotkey: options.debugHotkey || storedConfig.debugHotkey,
            dumpWAV: options.dumpWAV || storedConfig.dumpWAV,
            overlay: !options.noOverlay && storedConfig.overlay
        )
    }

    private func requestMicrophoneIfNeeded() async {
        guard AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined else {
            return
        }

        setupWindow.showWaitingForMicrophone()
        _ = await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
    }

    private func startRuntime(
        transcriber: WhisperKitTranscriber,
        settings: ResolvedSettings
    ) throws {
        monitor?.stop()

        let monitor = HotkeyMonitor(debug: settings.debugHotkey)
        let capture = AudioCapture()
        let overlay = settings.overlay ? RecordingOverlay() : nil
        if let overlay {
            capture.onLevel = { level in
                overlay.pushLevel(level)
            }
        }

        try monitor.start { [weak self] event in
            Task { @MainActor in
                self?.handleHotkey(event)
            }
        }

        self.monitor = monitor
        self.capture = capture
        self.overlay = overlay
        self.transcriber = transcriber
        activeModelID = settings.model.id
        dumpWAVEnabled = settings.dumpWAV
    }

    private func handleHotkey(_ event: HotkeyMonitor.Event) {
        guard let capture else { return }

        switch event {
        case .pressed:
            do {
                try capture.start()
                FileHandle.standardError.write(Data("● recording\n".utf8))
                overlay?.show(.recording)
                menuBar.setRecording(true)
            } catch {
                showRuntimeFailure("Microphone capture failed: \(error.localizedDescription)")
            }

        case .released:
            let samples = capture.stop()
            overlay?.show(.transcribing)
            menuBar.setTranscribing()

            let seconds = Double(samples.count) / AudioCapture.targetSampleRate
            let rms = computeRMS(samples)
            FileHandle.standardError.write(Data(
                String(format: "○ captured %.2fs · rms %.3f\n", seconds, rms).utf8
            ))

            if dumpWAVEnabled, !samples.isEmpty {
                writeDebugAudio(samples)
            }

            guard !samples.isEmpty, let transcriber else {
                returnToReadyState()
                return
            }

            Task { [weak self] in
                let started = Date()
                do {
                    let text = try await transcriber.transcribe(samples)
                    let elapsed = Date().timeIntervalSince(started)
                    FileHandle.standardError.write(Data(
                        String(format: "→ %.2fs · %d characters\n", elapsed, text.count).utf8
                    ))
                    await MainActor.run {
                        TextInjector.inject(text)
                        self?.returnToReadyState()
                    }
                } catch {
                    await MainActor.run {
                        self?.showRuntimeFailure(
                            "Transcription failed: \(error.localizedDescription)"
                        )
                    }
                }
            }
        }
    }

    private func writeDebugAudio(_ samples: [Float]) {
        let url = AppIdentity.Paths.current.debugWAV
        do {
            try SecureFiles.createPrivateDirectory(url.deletingLastPathComponent())
            try WAVWriter.write(samples: samples, sampleRate: 16_000, to: url.path)
            try SecureFiles.restrictFile(url)
            FileHandle.standardError.write(
                Data("  wrote private debug audio: \(url.path)\n".utf8)
            )
        } catch {
            FileHandle.standardError.write(Data("  wav write failed: \(error)\n".utf8))
        }
    }

    private func returnToReadyState() {
        overlay?.hide()
        if let activeModelID {
            menuBar.setReady(modelID: activeModelID)
        }
    }

    private func showRuntimeFailure(_ message: String) {
        overlay?.hide()
        transition(to: .failed(message))
    }

    private func transition(to state: StartupState) {
        startupState = state

        switch state {
        case .checking:
            menuBar.setChecking()
        case .permissions:
            menuBar.setNeedsAttention("permissions")
        case .preparing(let modelID, _):
            menuBar.setPreparing(modelID: modelID)
        case .ready(let modelID):
            menuBar.setReady(modelID: modelID)
        case .failed:
            menuBar.setNeedsAttention("setup")
        }

        renderStartupState(autoDismissReady: true)
    }

    private func renderStartupState(autoDismissReady: Bool) {
        switch startupState {
        case .checking:
            setupWindow.showChecking()

        case .permissions(let checks):
            setupWindow.showPermissionRequired(
                checks: checks,
                retry: { [weak self] in self?.beginPreparation() },
                openSettings: { [weak self] in self?.openRelevantPrivacySettings(for: checks) }
            )

        case .preparing(_, let displayName):
            setupWindow.showPreparingModel(name: displayName)

        case .ready:
            let hasCompletedFirstLaunch = UserDefaults.standard.bool(
                forKey: "hasCompletedFirstLaunch"
            )
            setupWindow.showReady(
                autoDismiss: autoDismissReady && hasCompletedFirstLaunch,
                done: { [weak self] in
                    UserDefaults.standard.set(true, forKey: "hasCompletedFirstLaunch")
                    self?.setupWindow.closeAndReturnToMenuBar()
                }
            )

        case .failed(let message):
            setupWindow.showError(
                message: message,
                retry: { [weak self] in self?.beginPreparation() }
            )
        }
    }

    private func openRelevantPrivacySettings(for checks: [Check]) {
        let hasMicrophoneFailure = checks.contains { check in
            check.name == "microphone"
        }
        let pane = hasMicrophoneFailure ? "Privacy_Microphone" : "Privacy_Accessibility"
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?\(pane)"
        ) else { return }
        NSWorkspace.shared.open(url)
    }

    private func installSignalHandler() {
        signal(SIGINT, SIG_IGN)
        let source = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        source.setEventHandler { [weak self] in
            self?.monitor?.stop()
            NSApp.terminate(nil)
        }
        source.resume()
        signalSource = source
    }

    private static func userFacingMessage(for error: Error) -> String {
        if let localized = error as? LocalizedError,
           let description = localized.errorDescription {
            return description
        }
        return error.localizedDescription
    }
}

private enum StartupError: LocalizedError {
    case configuration(path: String, underlying: Error)
    case unknownModel(String)
    case noModels

    var errorDescription: String? {
        switch self {
        case .configuration(let path, let underlying):
            return "The configuration at \(path) could not be read: \(underlying.localizedDescription)"
        case .unknownModel(let id):
            return "The configured model “\(id)” is not available. Update or remove that model setting, then try again."
        case .noModels:
            return "No on-device transcription models are registered."
        }
    }
}
