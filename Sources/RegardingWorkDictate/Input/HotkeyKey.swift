import CoreGraphics

/// Side-specific modifier choices adapted from upstream; see UPSTREAM.md.
enum HotkeyKey: String, Codable, CaseIterable, Sendable {
    case fn
    case leftOption = "left-option"
    case rightOption = "right-option"
    case leftCommand = "left-command"
    case rightCommand = "right-command"
    case leftControl = "left-control"
    case rightControl = "right-control"
    case leftShift = "left-shift"
    case rightShift = "right-shift"

    var displayName: String {
        switch self {
        case .fn: return "fn / Globe"
        case .leftOption: return "Left Option (⌥)"
        case .rightOption: return "Right Option (⌥)"
        case .leftCommand: return "Left Command (⌘)"
        case .rightCommand: return "Right Command (⌘)"
        case .leftControl: return "Left Control (⌃)"
        case .rightControl: return "Right Control (⌃)"
        case .leftShift: return "Left Shift (⇧)"
        case .rightShift: return "Right Shift (⇧)"
        }
    }

    var shortName: String {
        switch self {
        case .fn: return "fn"
        case .leftOption: return "left ⌥"
        case .rightOption: return "right ⌥"
        case .leftCommand: return "left ⌘"
        case .rightCommand: return "right ⌘"
        case .leftControl: return "left ⌃"
        case .rightControl: return "right ⌃"
        case .leftShift: return "left ⇧"
        case .rightShift: return "right ⇧"
        }
    }

    var keycode: Int64 {
        switch self {
        case .fn: return 63
        case .leftOption: return 58
        case .rightOption: return 61
        case .leftCommand: return 55
        case .rightCommand: return 54
        case .leftControl: return 59
        case .rightControl: return 62
        case .leftShift: return 56
        case .rightShift: return 60
        }
    }

    var flag: CGEventFlags {
        switch self {
        case .fn: return .maskSecondaryFn
        case .leftOption, .rightOption: return .maskAlternate
        case .leftCommand, .rightCommand: return .maskCommand
        case .leftControl, .rightControl: return .maskControl
        case .leftShift, .rightShift: return .maskShift
        }
    }
}
