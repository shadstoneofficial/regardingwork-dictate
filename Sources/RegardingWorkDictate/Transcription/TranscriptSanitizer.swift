import Foundation

enum TranscriptSanitizer {
    private static let nonSpeechLabels = [
        "blank_audio",
        "silence",
        "music",
        "music playing",
        "background noise",
        "noise",
        "applause",
        "laughter",
    ]

    static func sanitize(_ text: String) -> String {
        var output = text

        // Whisper control tokens are metadata and never dictated content.
        output = output.replacingOccurrences(
            of: #"<\|[^|]*\|>"#,
            with: " ",
            options: [.regularExpression, .caseInsensitive]
        )

        for label in nonSpeechLabels {
            let escaped = NSRegularExpression.escapedPattern(for: label)
            for pattern in [
                #"\[\s*\#(escaped)\s*\]"#,
                #"\(\s*\#(escaped)\s*\)"#,
                #"\*\s*\#(escaped)\s*\*"#,
            ] {
                output = output.replacingOccurrences(
                    of: pattern,
                    with: " ",
                    options: [.regularExpression, .caseInsensitive]
                )
            }
        }

        output = output.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
