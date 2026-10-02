import Foundation
import WhisperKit

actor WhisperKitTranscriber: Transcriber {
    let modelID: String
    private let model: TranscriptionModel
    private let language: TranscriptionLanguage
    private var pipeline: WhisperKit?

    init(model: TranscriptionModel, language: TranscriptionLanguage = .english) {
        self.modelID = model.id
        self.model = model
        self.language = language
    }

    /// Loads the model into memory; downloads first if not already on disk.
    /// Call once at startup so the first hotkey press isn't blocked on model
    /// download/load.
    func warmUp() async throws {
        if pipeline != nil { return }
        guard let whisperKitID = model.whisperKitID else {
            throw TranscriberError.missingEngineID
        }
        let modelDirectory = AppIdentity.Paths.current.models
        try SecureFiles.createPrivateDirectory(modelDirectory)
        FileHandle.standardError.write(Data("loading \(model.id)...\n".utf8))
        let config = WhisperKitConfig(
            model: whisperKitID,
            downloadBase: modelDirectory,
            verbose: false,
            prewarm: true,
            load: true
        )
        pipeline = try await WhisperKit(config)
        FileHandle.standardError.write(Data("✓ \(model.id) ready\n".utf8))
    }

    func transcribe(_ audio: [Float]) async throws -> String {
        if pipeline == nil { try await warmUp() }
        guard let pipeline else { throw TranscriberError.notLoaded }

        let decodeOptions = Self.decodingOptions(for: language)
        let results = try await pipeline.transcribe(
            audioArray: audio,
            decodeOptions: decodeOptions
        )
        let raw = results.map(\.text).joined(separator: " ")
        return TranscriptSanitizer.sanitize(raw)
    }

    static func decodingOptions(for language: TranscriptionLanguage) -> DecodingOptions {
        DecodingOptions(
            task: .transcribe,
            language: language.rawValue,
            usePrefillPrompt: true,
            detectLanguage: false
        )
    }
}

enum TranscriberError: Error {
    case missingEngineID
    case notLoaded
}
