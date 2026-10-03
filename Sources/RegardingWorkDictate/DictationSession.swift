import Foundation

/// One recording/transcription at a time. Session IDs reject stale completions.
struct DictationSession {
    enum State: Equatable {
        case idle
        case listening(UUID)
        case processing(UUID)
    }

    private(set) var state: State = .idle
    var isIdle: Bool { state == .idle }

    mutating func begin() -> UUID? {
        guard isIdle else { return nil }
        let id = UUID()
        state = .listening(id)
        return id
    }

    mutating func release() -> UUID? {
        guard case .listening(let id) = state else { return nil }
        state = .processing(id)
        return id
    }

    mutating func complete(_ id: UUID) -> Bool {
        guard state == .processing(id) else { return false }
        state = .idle
        return true
    }

    mutating func cancel() { state = .idle }
}

enum CapturedAudioAssessment: Equatable {
    case usable
    case tooShort
    case tooQuiet

    static func assess(_ samples: [Float], sampleRate: Double = 16_000) -> Self {
        guard samples.count >= Int(sampleRate * 0.15) else { return .tooShort }
        // Look at short windows so pauses do not dilute a quiet utterance's level.
        // This detects very low signal, not whether a person actually spoke.
        let windowSize = max(1, Int(sampleRate * 0.1))
        for start in stride(from: 0, to: samples.count, by: windowSize) {
            let window = samples[start..<min(start + windowSize, samples.count)]
            let energy = window.reduce(0.0) { $0 + Double($1) * Double($1) }
            if sqrt(energy / Double(window.count)) >= 0.001 { return .usable }
        }
        return .tooQuiet
    }
}

/// Only a blocked result is kept, in memory, for a maximum of one minute.
struct PendingDictation {
    static let lifetime: TimeInterval = 60
    private var value: String?
    private var deadline: Date?

    mutating func store(_ text: String, now: Date = Date()) {
        value = text.isEmpty ? nil : text
        deadline = text.isEmpty ? nil : now.addingTimeInterval(Self.lifetime)
    }

    mutating func text(now: Date = Date()) -> String? {
        guard let deadline, now < deadline else {
            clear()
            return nil
        }
        return value
    }

    mutating func clear() {
        value = nil
        deadline = nil
    }
}
