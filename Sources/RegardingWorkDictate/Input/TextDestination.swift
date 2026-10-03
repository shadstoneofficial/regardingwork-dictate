import AppKit
import ApplicationServices

/// Captures identity and selection metadata, never the target's text contents.
@MainActor
struct TextDestination {
    struct FocusSnapshot {
        let processID: pid_t
        let element: AXUIElement
        let selection: CFRange?
        let editable: Bool
    }

    private let original: FocusSnapshot
    private let readFocus: @MainActor () -> FocusSnapshot?

    static func capture(readFocus: @escaping @MainActor () -> FocusSnapshot? = readCurrentFocus) -> TextDestination? {
        guard let snapshot = readFocus(), snapshot.editable else { return nil }
        return TextDestination(original: snapshot, readFocus: readFocus)
    }

    private static func readCurrentFocus() -> FocusSnapshot? {
        guard let processID = NSWorkspace.shared.frontmostApplication?.processIdentifier,
              let element = focusedElement(in: processID) else { return nil }
        let selection = selectedRange(element)
        let editable = isEditable(element)
        // AX queries can take time. Reject a focus change that occurred while
        // metadata was being collected, before returning the snapshot.
        guard let finalElement = focusedElement(in: processID), CFEqual(element, finalElement),
              NSWorkspace.shared.frontmostApplication?.processIdentifier == processID else { return nil }
        return FocusSnapshot(
            processID: processID,
            element: element,
            selection: selection,
            editable: editable
        )
    }

    var isStillFocused: Bool {
        guard let current = readFocus(), current.processID == original.processID,
              CFEqual(original.element, current.element), current.editable else { return false }
        if let selection = original.selection {
            guard let currentRange = current.selection,
                  selection.location == currentRange.location,
                  selection.length == currentRange.length else { return false }
        }
        return true
    }

    private static func focusedElement(in processID: pid_t) -> AXUIElement? {
        let application = AXUIElementCreateApplication(processID)
        AXUIElementSetMessagingTimeout(application, 0.2)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            application, kAXFocusedUIElementAttribute as CFString, &value
        ) == .success, let value,
              CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        let element = unsafeBitCast(value, to: AXUIElement.self)
        AXUIElementSetMessagingTimeout(element, 0.2)
        return element
    }

    private static func isEditable(_ element: AXUIElement) -> Bool {
        var role: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role) == .success,
              let role = role as? String,
              [kAXTextFieldRole, kAXTextAreaRole, kAXComboBoxRole].contains(role) else { return false }
        var subrole: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &subrole)
        guard (subrole as? String) != kAXSecureTextFieldSubrole else { return false }
        var enabled: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXEnabledAttribute as CFString, &enabled)
        if let enabled = enabled as? Bool, !enabled { return false }

        var valueSettable = DarwinBoolean(false)
        var selectionSettable = DarwinBoolean(false)
        AXUIElementIsAttributeSettable(element, kAXValueAttribute as CFString, &valueSettable)
        AXUIElementIsAttributeSettable(element, kAXSelectedTextAttribute as CFString, &selectionSettable)
        return valueSettable.boolValue || selectionSettable.boolValue
    }

    private static func selectedRange(_ element: AXUIElement) -> CFRange? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element, kAXSelectedTextRangeAttribute as CFString, &value
        ) == .success, let value, CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        let rangeValue = unsafeBitCast(value, to: AXValue.self)
        guard AXValueGetType(rangeValue) == .cfRange else { return nil }
        var range = CFRange(location: 0, length: 0)
        return AXValueGetValue(rangeValue, .cfRange, &range) ? range : nil
    }
}
