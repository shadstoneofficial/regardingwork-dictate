import Foundation

struct AppConfig: Codable, Equatable {
    var model: String?
    var language: TranscriptionLanguage
    var overlay: Bool
    var debugHotkey: Bool
    var dumpWAV: Bool

    static let `default` = AppConfig(
        model: nil,
        language: .english,
        overlay: true,
        debugHotkey: false,
        dumpWAV: false
    )

    enum ConfigError: Error, Equatable {
        case unsupportedVersion(Int)
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case model
        case language
        case overlay
        case debugHotkey = "debug_hotkey"
        case dumpWAV = "dump_wav"
    }

    init(
        model: String?,
        language: TranscriptionLanguage = .english,
        overlay: Bool,
        debugHotkey: Bool,
        dumpWAV: Bool
    ) {
        self.model = model
        self.language = language
        self.overlay = overlay
        self.debugHotkey = debugHotkey
        self.dumpWAV = dumpWAV
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        guard version == 1 else {
            throw ConfigError.unsupportedVersion(version)
        }
        model = try container.decodeIfPresent(String.self, forKey: .model)
        language = try container.decodeIfPresent(
            TranscriptionLanguage.self,
            forKey: .language
        ) ?? .english
        overlay = try container.decodeIfPresent(Bool.self, forKey: .overlay) ?? true
        debugHotkey = try container.decodeIfPresent(Bool.self, forKey: .debugHotkey) ?? false
        dumpWAV = try container.decodeIfPresent(Bool.self, forKey: .dumpWAV) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(1, forKey: .version)
        try container.encodeIfPresent(model, forKey: .model)
        try container.encode(language, forKey: .language)
        try container.encode(overlay, forKey: .overlay)
        try container.encode(debugHotkey, forKey: .debugHotkey)
        try container.encode(dumpWAV, forKey: .dumpWAV)
    }

    static func load(from url: URL, fileManager: FileManager = .default) throws -> AppConfig {
        guard fileManager.fileExists(atPath: url.path) else {
            return .default
        }
        return try JSONDecoder().decode(AppConfig.self, from: Data(contentsOf: url))
    }

    func save(to url: URL) throws {
        try SecureFiles.createPrivateDirectory(url.deletingLastPathComponent())
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(self).write(to: url, options: .atomic)
        try SecureFiles.restrictFile(url)
    }
}
