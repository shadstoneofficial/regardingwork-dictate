import Foundation

enum TranscriptionLanguage: String, Codable, CaseIterable, Equatable {
    case english = "en"
    case thai = "th"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .thai: return "Thai"
        }
    }
}
