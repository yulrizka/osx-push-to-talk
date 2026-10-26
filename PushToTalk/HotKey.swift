//
//  HotKey.swift
//  PushToTalk
//
//  Created by Jeremy Ellison on 5/14/20.
//  Copyright © 2020 yulrizka. All rights reserved.
//

import AppKit

final class HotKey {
    static let relevantModifiers: NSEvent.ModifierFlags = [.shift, .control, .option, .command, .function]
    private static let keyCodeKey = "prefKeyCode"
    private static let modifiersKey = "prefModifier"
    private static let defaultKeyCode: UInt16 = 61 // Right Option
    private static let doubleTapIntervalKey = "prefDoubleTapInterval"

    // Two presses closer than this toggle the lock. Measured double taps land 140 to 260 ms apart; separate presses are seconds apart.
    static var doubleTapInterval: TimeInterval {
        UserDefaults.standard.object(forKey: doubleTapIntervalKey) as? Double ?? 0.3
    }

    private let microphone: Microphone
    private let menuItem: NSMenuItem
    private var keyCode: UInt16
    private var modifierFlags: NSEvent.ModifierFlags
    private var recordingHotKey = false
    private var lastPressTime: TimeInterval = 0
    private var lockedOpen = false

    init(microphone: Microphone, menuItem: NSMenuItem) {
        self.microphone = microphone
        self.menuItem = menuItem
        let defaults = UserDefaults.standard
        let savedFlags = NSEvent.ModifierFlags(rawValue: UInt(defaults.integer(forKey: Self.modifiersKey))).intersection(Self.relevantModifiers)
        // Old versions could save a caps lock hotkey, which has no relevant flag and would never mute.
        if defaults.object(forKey: Self.keyCodeKey) == nil || savedFlags.isEmpty {
            keyCode = Self.defaultKeyCode
            modifierFlags = .option
        } else {
            keyCode = UInt16(truncatingIfNeeded: defaults.integer(forKey: Self.keyCodeKey))
            modifierFlags = savedFlags
        }
        updateMenuTitle()
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in self?.handle(event) }
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handle(event)
            return event
        }
    }

    static func matches(_ eventFlags: NSEvent.ModifierFlags, hotkey: NSEvent.ModifierFlags) -> Bool {
        eventFlags.intersection(relevantModifiers) == hotkey.intersection(relevantModifiers)
    }

    func toggle() {
        recordingHotKey = false
        lockedOpen = false
        microphone.status = microphone.status == .disabled ? .muted : .disabled
    }

    func recordNewHotKey() {
        recordingHotKey = true
        microphone.status = .recordingHotKey
    }

    private func updateMenuTitle() {
        menuItem.title = "Change HotKey (\(KeyCodeHelper.keyChars(keyCode: keyCode)))"
    }

    private func handle(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(Self.relevantModifiers)
        if recordingHotKey {
            guard !flags.isEmpty else { return } // caps lock and similar keys carry no modifier flag
            recordingHotKey = false
            keyCode = event.keyCode
            modifierFlags = flags
            UserDefaults.standard.set(Int(keyCode), forKey: Self.keyCodeKey)
            UserDefaults.standard.set(Int(modifierFlags.rawValue), forKey: Self.modifiersKey)
            updateMenuTitle()
            microphone.status = .muted
            return
        }
        guard event.keyCode == keyCode, microphone.status != .disabled else { return }
        if Self.matches(event.modifierFlags, hotkey: modifierFlags) {
            // Pressed with no other modifier held. A double tap toggles the lock; a third press starts a new count.
            let doubleTap = event.timestamp - lastPressTime < Self.doubleTapInterval
            lastPressTime = doubleTap ? 0 : event.timestamp
            if doubleTap { lockedOpen.toggle() }
            microphone.status = doubleTap && !lockedOpen ? .muted : .speaking
        } else if !flags.isSuperset(of: modifierFlags), !lockedOpen {
            microphone.status = .muted
        }
    }
}
