import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

/// Watches a single modifier key (default: Fn) and emits press/release edges.
/// Requires Accessibility permission. If the tap fails to register, callers
/// will see an error from `start()`.
final class HotkeyMonitor {
    enum Event: Equatable { case pressed, released, cancelled }
    enum HotkeyError: Error { case tapCreateFailed }

    private(set) var key: HotkeyKey
    private let debug: Bool
    private var onEvent: ((Event) -> Void)?
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var gesture = Gesture()
    fileprivate var tapForRecovery: CFMachPort? { tap }

    init(key: HotkeyKey = .fn, debug: Bool = false) {
        self.key = key
        self.debug = debug
    }

    func setKey(_ key: HotkeyKey) {
        guard self.key != key else { return }
        let action = gesture.reset()
        self.key = key
        if let action { emit(action) }
    }

    func start(onEvent: @escaping (Event) -> Void) throws {
        self.onEvent = onEvent

        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let trusted = AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
        if !trusted {
            FileHandle.standardError.write(Data(
                "accessibility not granted — system prompt opened. Grant access, then quit and relaunch \(AppIdentity.productName).\n".utf8
            ))
            throw HotkeyError.tapCreateFailed
        }

        // Request modifier changes only. Dictated or typed key events are never observed.
        let mask: CGEventMask = (1 << CGEventType.flagsChanged.rawValue)
        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        // .cgSessionEventTap is the right level for an accessibility-granted
        // user process (.cghidEventTap requires root).
        guard
            let tap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .listenOnly,
                eventsOfInterest: mask,
                callback: hotkeyCallback,
                userInfo: userInfo
            )
        else {
            throw HotkeyError.tapCreateFailed
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        self.tap = tap
        self.runLoopSource = source
    }

    func stop() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        tap = nil
        runLoopSource = nil
        onEvent = nil
        _ = gesture.reset()
    }

    fileprivate func handle(type: CGEventType, event: CGEvent) {
        if debug {
            let flags = event.flags
            FileHandle.standardError.write(
                Data(
                    "  [debug] modifier flags=\(String(flags.rawValue, radix: 16))\n"
                        .utf8
                ))
        }
        guard type == .flagsChanged else { return }
        let keycode = event.getIntegerValueField(.keyboardEventKeycode)
        guard let input = Self.input(keycode: keycode, flags: event.flags, key: key, held: gesture.isHeld) else { return }
        if let action = gesture.handle(input, at: ProcessInfo.processInfo.systemUptime) {
            emit(action)
        }
    }

    private func emit(_ action: Gesture.Action) {
        switch action {
        case .start: onEvent?(.pressed)
        case .transcribe: onEvent?(.released)
        case .cancel: onEvent?(.cancelled)
        }
    }

    // Adapted from upstream a67e7f3. Side-specific keys share one flag bit.
    static let modifierKeycodes: Set<Int64> = [54, 55, 56, 58, 59, 60, 61, 62, 63]
    static let chordFlags: CGEventFlags = [.maskShift, .maskControl, .maskAlternate, .maskCommand, .maskSecondaryFn]

    static func input(keycode: Int64, flags: CGEventFlags, key: HotkeyKey, held: Bool) -> Gesture.Input? {
        let flagSet = flags.contains(key.flag)
        if held {
            if !flagSet { return .hotkeyUp }
            if key != .fn, keycode == key.keycode { return .hotkeyUp }
            if keycode != key.keycode, modifierKeycodes.contains(keycode) { return .otherModifier }
            return nil
        }
        guard flagSet, key == .fn || keycode == key.keycode else { return nil }
        let others = flags.intersection(chordFlags).subtracting(key.flag)
        return .hotkeyDown(othersHeld: !others.isEmpty)
    }
}

private func hotkeyCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let monitor = Unmanaged<HotkeyMonitor>.fromOpaque(userInfo).takeUnretainedValue()

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = monitor.tapForRecovery {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }

    let copy = event.copy()
    DispatchQueue.main.async {
        if let copy {
            monitor.handle(type: type, event: copy)
        }
    }
    return Unmanaged.passUnretained(event)
}
