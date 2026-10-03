import Foundation

/// Upstream's modifier-only short-tap/chord filter. No typed keys are observed.
struct Gesture {
    static let minimumHold: TimeInterval = 0.3
    enum Input: Equatable {
        case hotkeyDown(othersHeld: Bool), hotkeyUp, otherModifier
    }
    enum Action: Equatable { case start, transcribe, cancel }
    private enum Phase: Equatable {
        case idle, recording(since: TimeInterval), ignoring
    }
    private var phase: Phase = .idle
    var isHeld: Bool { phase != .idle }

    mutating func handle(_ input: Input, at time: TimeInterval) -> Action? {
        switch (phase, input) {
        case (.idle, .hotkeyDown(let othersHeld)):
            if othersHeld {
                phase = .ignoring
                return nil
            }
            phase = .recording(since: time)
            return .start
        case (.recording(let since), .hotkeyUp):
            phase = .idle
            return time - since < Self.minimumHold ? .cancel : .transcribe
        case (.recording, .otherModifier):
            phase = .ignoring
            return .cancel
        case (.ignoring, .hotkeyUp):
            phase = .idle
            return nil
        default: return nil
        }
    }

    mutating func reset() -> Action? {
        defer { phase = .idle }
        if case .recording = phase { return .cancel }
        return nil
    }
}
