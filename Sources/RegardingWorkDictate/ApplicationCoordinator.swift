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
        let language: TranscriptionLanguage
        let debugHotkey: Bool
        let dumpWAV: Bool
        let overlay: Bool
        let feedbackSounds: Bool
    }

    private let options: RuntimeOptions
    private let menuBar = MenuBarController()
    private let setupWindow = SetupWindowController()
    private let launchAtLogin = LaunchAtLoginManager()
    private let practiceWindow = PracticeWindowController()
    private let recoveryWindow = RecoveryWindowController()
    private var startupState: StartupState = .checking
    private var preparationTask: Task<Void, Never>?
    private var signalSource: DispatchSourceSignal?

    private var monitor: HotkeyMonitor?
    private var capture: AudioCapture?
    private var overlay: RecordingOverlay?
    private var transcriber: WhisperKitTranscriber?
    private var activeModelID: String?
    private var activeLanguage: TranscriptionLanguage?
    private var dumpWAVEnabled = false
    private var feedbackSoundsEnabled = false
    private var session = DictationSession()
    private var destination: TextDestination?
    private var practiceSelection: NSRange?
    private var transcriptionTask: Task<Void, Never>?
    private var feedbackDismissal: Task<Void, Never>?
    private var recoveryExpiry: Task<Void, Never>?
    private var pendingDictation = PendingDictation()

    init(options: RuntimeOptions) {
        self.options = options
        super.init()
    }

    func start() {
        NSApp.delegate = self
        menuBar.onShowSetup = { [weak self] in
            self?.renderStartupState(autoDismissReady: false)
        }
        menuBar.onSelectLanguage = { [weak self] language in
            self?.selectLanguage(language)
        }
        menuBar.onToggleLaunchAtLogin = { [weak self] in
            self?.toggleLaunchAtLogin()
        }
        menuBar.onPractice = { [weak self] in self?.showPractice() }
        menuBar.onToggleSounds = { [weak self] in self?.toggleFeedbackSounds() }
        recoveryWindow.onCopy = { [weak self] in self?.copyPendingDictation() }
        recoveryWindow.onDismiss = { [weak self] in
            self?.pendingDictation.clear()
            self?.recoveryExpiry?.cancel()
        }
        do {
            try launchAtLogin.migrateLegacyIfNeeded()
        } catch {
            FileHandle.standardError.write(Data(
                "launch-at-login migration failed: \(error.localizedDescription)\n".utf8
            ))
        }
        refreshLaunchAtLoginStatus()
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
        guard preparationTask == nil, session.isIdle else { return }
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
                displayName: "\(settings.model.displayName) for \(settings.language.displayName)"
            ))

            let transcriber = WhisperKitTranscriber(
                model: settings.model,
                language: settings.language
            )
            try await transcriber.warmUp()
            try startRuntime(transcriber: transcriber, settings: settings)

            transition(to: .ready(modelID: settings.model.id))
        } catch {
            transition(to: .failed(Self.userFacingMessage(for: error)))
        }
    }

    private func resolveSettings() throws -> ResolvedSettings {
        let storedConfig: AppConfig
        do {
            storedConfig = try AppConfig.load(from: configurationURL)
        } catch {
            throw StartupError.configuration(path: configurationURL.path, underlying: error)
        }

        let selectedModelID = options.modelID ?? storedConfig.model
        let model: TranscriptionModel
        if let selectedModelID {
            guard let selectedModel = ModelRegistry.find(selectedModelID) else {
                throw StartupError.unknownModel(selectedModelID)
            }
            if selectedModel.supports(storedConfig.language) {
                model = selectedModel
            } else if options.modelID != nil {
                throw StartupError.unsupportedLanguage(
                    model: selectedModelID,
                    language: storedConfig.language.displayName
                )
            } else if let fallback = ModelRegistry.recommended(for: storedConfig.language) {
                model = fallback
            } else {
                throw StartupError.noModelForLanguage(storedConfig.language.displayName)
            }
        } else {
            guard let defaultModel = ModelRegistry.recommended(for: storedConfig.language) else {
                throw StartupError.noModelForLanguage(storedConfig.language.displayName)
            }
            model = defaultModel
        }

        menuBar.setLanguage(storedConfig.language)

        return ResolvedSettings(
            model: model,
            language: storedConfig.language,
            debugHotkey: options.debugHotkey || storedConfig.debugHotkey,
            dumpWAV: options.dumpWAV || storedConfig.dumpWAV,
            overlay: !options.noOverlay && storedConfig.overlay,
            feedbackSounds: storedConfig.feedbackSounds
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
        transcriptionTask?.cancel()
        session.cancel()

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
        activeLanguage = settings.language
        dumpWAVEnabled = settings.dumpWAV
        feedbackSoundsEnabled = settings.feedbackSounds
        menuBar.setSoundsEnabled(settings.feedbackSounds)
    }

    private func handleHotkey(_ event: HotkeyMonitor.Event) {
        guard case .ready = startupState, let capture, let language = activeLanguage else { return }

        switch event {
        case .pressed:
            guard session.begin() != nil else {
                // Keep the current processing indicator; ignore the matching release.
                return
            }
            feedbackDismissal?.cancel()
            destination = TextDestination.capture()
            practiceSelection = practiceWindow.isInputFocused ? practiceWindow.textView.selectedRange() : nil
            clearRecovery()
            do {
                try capture.start()
                FileHandle.standardError.write(Data("● recording\n".utf8))
                overlay?.show(.recording, language: language)
                menuBar.setRecording(true)
                menuBar.setLanguageSelectionEnabled(false)
                menuBar.setPracticeEnabled(false)
                practiceWindow.setStatus("Listening — \(language.displayName)")
                playFeedbackSound("Tink")
            } catch {
                session.cancel()
                showRuntimeFailure("Microphone capture failed: \(error.localizedDescription)")
            }

        case .released:
            guard let sessionID = session.release() else { return }
            let samples = capture.stop()
            playFeedbackSound("Pop")
            overlay?.show(.transcribing, language: language)
            menuBar.setTranscribing()
            practiceWindow.setStatus("Processing — \(language.displayName)")

            let seconds = Double(samples.count) / AudioCapture.targetSampleRate
            let rms = computeRMS(samples)
            FileHandle.standardError.write(Data(
                String(format: "○ captured %.2fs · rms %.3f\n", seconds, rms).utf8
            ))

            if dumpWAVEnabled, !samples.isEmpty {
                writeDebugAudio(samples)
            }

            let assessment = CapturedAudioAssessment.assess(samples)
            guard assessment == .usable else {
                _ = session.complete(sessionID)
                showNotice(assessment == .tooShort
                    ? "Hold fn longer while you speak"
                    : "Microphone too quiet — try again")
                return
            }
            guard let transcriber else {
                _ = session.complete(sessionID)
                showRuntimeFailure("Dictation is not ready. Please try setup again.")
                return
            }

            transcriptionTask = Task { [weak self] in
                let started = Date()
                do {
                    let text = try await transcriber.transcribe(samples)
                    guard !Task.isCancelled, let self, self.session.complete(sessionID) else { return }
                    let elapsed = Date().timeIntervalSince(started)
                    FileHandle.standardError.write(Data(
                        String(format: "→ %.2fs · %d characters\n", elapsed, text.count).utf8
                    ))
                    self.transcriptionTask = nil
                    self.finishDictation(text)
                } catch {
                    guard !Task.isCancelled, let self, self.session.complete(sessionID) else { return }
                    self.transcriptionTask = nil
                    self.showRuntimeFailure("Transcription failed. Choose Try Again to prepare dictation again.")
                }
            }
        }
    }

    private func finishDictation(_ text: String) {
        guard !text.isEmpty else {
            showNotice("No words recognized — try again")
            return
        }
        let canInsert: Bool
        if let practiceSelection {
            canInsert = practiceWindow.isInputFocused &&
                practiceWindow.textView.selectedRange() == practiceSelection
        } else {
            canInsert = destination?.isStillFocused == true
        }
        guard canInsert else {
            offerRecovery(text, reason: "The original text field is no longer selected, or it does not allow text input. Copy your words and paste them where you want.")
            return
        }
        guard TextInjector.inject(text) else {
            offerRecovery(text, reason: "Text could not be sent to the selected field. Copy your words and paste them where you want.")
            return
        }
        returnToReadyState()
        practiceWindow.setStatus("Text sent — check your sentence below. Hold fn to try again.")
    }

    private func showNotice(_ message: String) {
        returnToReadyState()
        menuBar.setNeedsAttention(message)
        practiceWindow.setStatus(message)
        overlay?.show(.notice(message), language: activeLanguage ?? .english)
        feedbackDismissal?.cancel()
        feedbackDismissal = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled, let self, self.session.isIdle else { return }
            self.returnToReadyState()
        }
    }

    private func offerRecovery(_ text: String, reason: String) {
        returnToReadyState()
        practiceWindow.setStatus("Text was not inserted. Use the temporary recovery window to copy it.")
        pendingDictation.store(text)
        recoveryWindow.present(text: text, reason: reason)
        recoveryExpiry?.cancel()
        recoveryExpiry = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(PendingDictation.lifetime * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.clearRecovery()
        }
    }

    private func clearRecovery() {
        pendingDictation.clear()
        recoveryExpiry?.cancel()
        recoveryExpiry = nil
        recoveryWindow.clear()
    }

    private func copyPendingDictation() {
        guard let text = pendingDictation.text() else {
            clearRecovery()
            return
        }
        NSPasteboard.general.clearContents()
        if NSPasteboard.general.setString(text, forType: .string) { clearRecovery() }
    }

    private func showPractice() {
        guard session.isIdle, case .ready = startupState, let language = activeLanguage else { return }
        setupWindow.closeAndReturnToMenuBar()
        practiceWindow.present(language: language)
    }

    private func playFeedbackSound(_ name: String) {
        guard feedbackSoundsEnabled else { return }
        NSSound(named: NSSound.Name(name))?.play()
    }

    private func toggleFeedbackSounds() {
        do {
            var config = try AppConfig.load(from: configurationURL)
            config.feedbackSounds.toggle()
            try config.save(to: configurationURL)
            feedbackSoundsEnabled = config.feedbackSounds
            menuBar.setSoundsEnabled(config.feedbackSounds)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Couldn’t Save Recording Sounds"
            alert.informativeText = "Please check that the configuration folder is writable and try again."
            alert.runModal()
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
        destination = nil
        practiceSelection = nil
        overlay?.hide()
        if let activeModelID {
            menuBar.setReady(modelID: activeModelID)
            menuBar.setLanguageSelectionEnabled(true)
            menuBar.setPracticeEnabled(true)
        }
    }

    private var configurationURL: URL {
        options.configurationPath.map {
            URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath)
        } ?? AppIdentity.Paths.current.configuration
    }

    private func selectLanguage(_ language: TranscriptionLanguage) {
        guard session.isIdle, language != activeLanguage else { return }
        feedbackDismissal?.cancel()
        clearRecovery()

        do {
            var config = try AppConfig.load(from: configurationURL)
            config.language = language
            try config.save(to: configurationURL)

            menuBar.setLanguage(language)
            monitor?.stop()
            monitor = nil
            capture = nil
            overlay?.hide()
            overlay = nil
            transcriber = nil
            activeModelID = nil
            activeLanguage = nil
            beginPreparation()
        } catch {
            if let activeLanguage {
                menuBar.setLanguage(activeLanguage)
            }
            showLanguageError(error)
        }
    }

    private func showLanguageError(_ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Couldn’t Change Dictation Language"
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showRuntimeFailure(_ message: String) {
        overlay?.hide()
        transition(to: .failed(message))
    }

    private func transition(to state: StartupState) {
        startupState = state
        menuBar.setPracticeEnabled(false)

        switch state {
        case .checking:
            menuBar.setChecking()
            menuBar.setLanguageSelectionEnabled(false)
        case .permissions:
            menuBar.setNeedsAttention("permissions")
            menuBar.setLanguageSelectionEnabled(true)
        case .preparing(let modelID, _):
            menuBar.setPreparing(modelID: modelID)
            menuBar.setLanguageSelectionEnabled(false)
        case .ready(let modelID):
            menuBar.setReady(modelID: modelID)
            menuBar.setLanguageSelectionEnabled(true)
            menuBar.setPracticeEnabled(true)
        case .failed:
            menuBar.setNeedsAttention("setup")
            menuBar.setLanguageSelectionEnabled(true)
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
                },
                practice: { [weak self] in
                    UserDefaults.standard.set(true, forKey: "hasCompletedFirstLaunch")
                    self?.showPractice()
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

    private func toggleLaunchAtLogin() {
        let currentStatus = launchAtLogin.status
        if currentStatus == .requiresApproval {
            launchAtLogin.openSystemSettings()
            return
        }

        do {
            try launchAtLogin.setEnabled(currentStatus != .enabled)
            refreshLaunchAtLoginStatus()
        } catch {
            refreshLaunchAtLoginStatus()
            showLaunchAtLoginError(error)
        }
    }

    private func refreshLaunchAtLoginStatus() {
        menuBar.setLaunchAtLoginStatus(launchAtLogin.status)
    }

    private func showLaunchAtLoginError(_ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Couldn’t Change Start at Login"
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Open Login Items")
        if alert.runModal() == .alertSecondButtonReturn {
            launchAtLogin.openSystemSettings()
        }
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

    func applicationWillTerminate(_ notification: Notification) {
        monitor?.stop()
        capture?.stop()
        transcriptionTask?.cancel()
        feedbackDismissal?.cancel()
        clearRecovery()
        session.cancel()
        practiceWindow.textView.string = ""
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
    case noModelForLanguage(String)
    case unsupportedLanguage(model: String, language: String)

    var errorDescription: String? {
        switch self {
        case .configuration(let path, let underlying):
            return "The configuration at \(path) could not be read: \(underlying.localizedDescription)"
        case .unknownModel(let id):
            return "The configured model “\(id)” is not available. Update or remove that model setting, then try again."
        case .noModels:
            return "No on-device transcription models are registered."
        case .noModelForLanguage(let language):
            return "No on-device transcription model is available for \(language)."
        case .unsupportedLanguage(let model, let language):
            return "The model “\(model)” does not support \(language). Choose a multilingual model or remove the model override."
        }
    }
}
