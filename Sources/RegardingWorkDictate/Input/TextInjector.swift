import CoreGraphics
import Foundation

/// Posts a string of text at the current cursor location by synthesizing
/// keyboard events with `CGEventKeyboardSetUnicodeString`. Works in nearly
/// every text field on macOS; some Electron apps and secure password fields
/// can drop characters (platform constraint).
enum TextInjector {
    /// Inject the given text at the current cursor location.
    /// Splits long strings into chunks because the underlying API has a
    /// per-event character limit (~20 chars).
    /// True means events were posted, not that the receiving app accepted them.
    static func inject(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        var events: [CGEvent] = []
        for var chunk in chunks(for: text) {
            guard let down = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
                  let up = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false)
            else { return false }
            down.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: &chunk)
            up.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: &chunk)
            events.append(contentsOf: [down, up])
        }
        // Prepare all events first to avoid partial insertion on allocation failure.
        events.forEach { $0.post(tap: .cgSessionEventTap) }
        return true
    }

    static func chunks(for text: String, limit: Int = 20) -> [[UniChar]] {
        precondition(limit >= 2)
        let utf16 = Array(text.utf16)
        var chunks: [[UniChar]] = []
        var index = 0
        while index < utf16.count {
            var end = min(index + limit, utf16.count)
            // Do not divide a Unicode surrogate pair between keyboard events.
            if end < utf16.count, (0xD800...0xDBFF).contains(utf16[end - 1]) { end -= 1 }
            chunks.append(Array(utf16[index..<end]))
            index = end
        }
        return chunks
    }
}
