import Foundation

enum ModelPreparationEvent: Sendable {
    case downloading(Double?)
    case loading
}

enum ModelPreparationProgress: Equatable, Sendable {
    case checking
    case downloading(Int?)
    case loading

    var message: String {
        switch self {
        case .checking: return "Checking model files…"
        case .downloading(nil): return "Checking or downloading model files…"
        case .downloading(let percent?): return "Downloading model files — \(percent)%"
        case .loading: return "Loading on-device model…"
        }
    }
}

/// One preparation at a time. Late callbacks cannot affect a retry or a ready app.
/// Percentages describe the model-file transfer, not Core ML load/compile time.
struct ModelPreparationSession {
    private(set) var attemptID: UUID?
    private(set) var isCancelled = false
    private(set) var progress: ModelPreparationProgress = .checking

    mutating func begin() -> UUID? {
        guard attemptID == nil else { return nil }
        let id = UUID()
        attemptID = id
        isCancelled = false
        progress = .checking
        return id
    }

    mutating func accept(_ event: ModelPreparationEvent, for id: UUID) -> Bool {
        guard attemptID == id, !isCancelled else { return false }
        let next: ModelPreparationProgress
        switch event {
        case .loading: next = .loading
        case .downloading(let fraction):
            guard progress != .loading else { return false }
            if let fraction {
                guard fraction.isFinite else { return false }
                let percent = Int((min(1, max(0, fraction)) * 100).rounded(.down))
                if case .downloading(let previous?) = progress, percent <= previous { return false }
                next = .downloading(percent)
            } else {
                guard progress == .checking else { return false }
                next = .downloading(nil)
            }
        }
        guard next != progress else { return false }
        progress = next
        return true
    }

    mutating func cancel(_ id: UUID) -> Bool {
        guard attemptID == id, !isCancelled else { return false }
        isCancelled = true
        return true
    }

    mutating func finish(_ id: UUID) {
        guard attemptID == id else { return }
        attemptID = nil
    }
}
