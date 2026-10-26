//
//  Microphone.swift
//  PushToTalk
//
//  Created by Chris Nielubowicz on 12/5/16.
//  Copyright © 2016 yulrizka. All rights reserved.
//

import AppKit
import CoreAudio
import os

struct InputDevice: Equatable {
    let id: AudioDeviceID
    let uid: String
    let name: String
    let muteElements: [AudioObjectPropertyElement] // empty = no mute control
    let volumeElements: [AudioObjectPropertyElement] // empty = no input volume control

    var supportsMute: Bool { !muteElements.isEmpty }
}

final class Microphone {
    private static let logger = Logger(subsystem: "com.yulrizka.PushToTalk", category: "microphone")
    private static let pinnedDeviceKey = "prefInputDeviceUID"
    private static let lockedVolumeKey = "prefLockedInputVolume"
    private static let lockedVolumeDeviceKey = "prefLockedInputVolumeDevice"
    private static let systemObject = AudioObjectID(kAudioObjectSystemObject)

    var statusUpdated: ((MicrophoneStatus) -> Void)?
    private(set) var selectedInput: InputDevice?
    private weak var deviceMenu: NSMenu?

    // Input volume to restore whenever another app changes it; nil = not locked.
    var lockedInputVolume: Float? = UserDefaults.standard.object(forKey: Microphone.lockedVolumeKey) as? Float {
        didSet {
            UserDefaults.standard.set(lockedInputVolume, forKey: Self.lockedVolumeKey)
            UserDefaults.standard.set(lockedInputVolume == nil ? nil : selectedInput?.uid, forKey: Self.lockedVolumeDeviceKey)
        }
    }

    var status: MicrophoneStatus = .muted {
        didSet {
            applyStatus()
            statusUpdated?(status)
        }
    }

    init() {
        // Rebuild the device list when devices come and go or the system default input changes.
        for selector in [kAudioHardwarePropertyDevices, kAudioHardwarePropertyDefaultInputDevice] {
            var address = Self.address(selector)
            AudioObjectAddPropertyListenerBlock(Self.systemObject, &address, .main) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.refreshDevices() }
            }
        }
        // Some apps unmute the input device or change its volume behind our back: re-apply every 0.2 s.
        let timer = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                if self.status.isMuted { self.applyStatus() }
                self.enforceLockedVolume()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
    }

    func setupDeviceMenu(_ menu: NSMenu) {
        menu.autoenablesItems = false
        deviceMenu = menu
        refreshDevices()
    }

    func refreshDevices() {
        let devices = inputDevices()
        let pinnedUID = UserDefaults.standard.string(forKey: Self.pinnedDeviceKey)
        let defaultID = defaultInputDeviceID()
        let usable = devices.filter(\.supportsMute)
        // No fallback to another device: muting a mic macOS does not use would leave the real one live.
        let newSelection = usable.first { $0.uid == pinnedUID } ?? usable.first { $0.id == defaultID }
        if let old = selectedInput, old != newSelection, devices.contains(old) {
            setMuted(false, on: old) // stop managing a device we no longer control
        }
        selectedInput = newSelection
        // The locked level belongs to one device, also across launches.
        if lockedInputVolume != nil, UserDefaults.standard.string(forKey: Self.lockedVolumeDeviceKey) != newSelection?.uid {
            lockedInputVolume = nil
        }
        applyStatus()
        statusUpdated?(status) // the icon depends on whether a device is controlled

        guard let menu = deviceMenu else { return }
        menu.removeAllItems()
        let systemDefault = NSMenuItem(title: "System Default", action: #selector(selectDevice(_:)), keyEquivalent: "")
        systemDefault.target = self
        systemDefault.state = pinnedUID == nil ? .on : .off
        menu.addItem(systemDefault)
        menu.addItem(.separator())
        if devices.isEmpty {
            menu.addItem(NSMenuItem(title: "No input devices", action: nil, keyEquivalent: ""))
            menu.items.last?.isEnabled = false
        }
        for device in devices {
            let title = device.supportsMute ? device.name : "\(device.name) (no mute control)"
            let item = NSMenuItem(title: title, action: #selector(selectDevice(_:)), keyEquivalent: "")
            item.representedObject = device
            item.target = self
            item.isEnabled = device.supportsMute
            item.state = device == selectedInput ? .on : .off
            menu.addItem(item)
        }
    }

    func applyStatus() {
        guard let device = selectedInput else { return }
        setMuted(status.isMuted, on: device)
    }

    // 0...1, nil when the selected device has no input volume control.
    func inputVolume() -> Float? {
        guard let device = selectedInput, let element = device.volumeElements.first else { return nil }
        var address = Self.address(kAudioDevicePropertyVolumeScalar, scope: kAudioDevicePropertyScopeInput, element: element)
        var volume: Float32 = 0
        var size = UInt32(MemoryLayout<Float32>.size)
        return AudioObjectGetPropertyData(device.id, &address, 0, nil, &size, &volume) == noErr ? volume : nil
    }

    func setInputVolume(_ volume: Float) {
        guard let device = selectedInput else { return }
        for element in device.volumeElements {
            var address = Self.address(kAudioDevicePropertyVolumeScalar, scope: kAudioDevicePropertyScopeInput, element: element)
            var value = Float32(min(max(volume, 0), 1))
            let result = AudioObjectSetPropertyData(device.id, &address, 0, nil, UInt32(MemoryLayout<Float32>.size), &value)
            if result != noErr {
                Self.logger.error("Failed to set the input volume of \(device.name, privacy: .public): OSStatus \(result)")
            }
        }
    }

    private func enforceLockedVolume() {
        guard let wanted = lockedInputVolume, let current = inputVolume(), abs(current - wanted) > 0.005 else { return }
        setInputVolume(wanted)
        // A device with coarse volume steps reports its nearest step: adopt it instead of rewriting forever.
        if let actual = inputVolume(), abs(actual - wanted) > 0.005 { lockedInputVolume = actual }
    }

    @objc private func selectDevice(_ item: NSMenuItem) {
        UserDefaults.standard.set((item.representedObject as? InputDevice)?.uid, forKey: Self.pinnedDeviceKey)
        refreshDevices()
    }

    private func setMuted(_ muted: Bool, on device: InputDevice) {
        for element in device.muteElements {
            var address = Self.address(kAudioDevicePropertyMute, scope: kAudioDevicePropertyScopeInput, element: element)
            var size = UInt32(MemoryLayout<UInt32>.size)
            var current: UInt32 = 0
            if AudioObjectGetPropertyData(device.id, &address, 0, nil, &size, &current) == noErr, (current != 0) == muted { continue }
            var value: UInt32 = muted ? 1 : 0
            let result = AudioObjectSetPropertyData(device.id, &address, 0, nil, size, &value)
            if result != noErr {
                Self.logger.error("Failed to \(muted ? "mute" : "unmute", privacy: .public) \(device.name, privacy: .public): OSStatus \(result)")
            }
        }
    }

    private func inputDevices() -> [InputDevice] {
        var address = Self.address(kAudioHardwarePropertyDevices)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(Self.systemObject, &address, 0, nil, &size) == noErr else { return [] }
        var ids = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(Self.systemObject, &address, 0, nil, &size, &ids) == noErr else { return [] }
        return ids.compactMap { id in
            let channels = inputChannelCount(of: id)
            guard channels > 0,
                  let uid = string(kAudioDevicePropertyDeviceUID, of: id),
                  let name = string(kAudioDevicePropertyDeviceNameCFString, of: id) else { return nil }
            return InputDevice(id: id, uid: uid, name: name,
                               muteElements: settableElements(of: id, property: kAudioDevicePropertyMute, channels: channels),
                               volumeElements: settableElements(of: id, property: kAudioDevicePropertyVolumeScalar, channels: channels))
        }
    }

    // The main element when the device has one control, otherwise every channel that has its own.
    private func settableElements(of id: AudioObjectID, property: AudioObjectPropertySelector, channels: Int) -> [AudioObjectPropertyElement] {
        let candidates = [kAudioObjectPropertyElementMain] + (1...channels).map { AudioObjectPropertyElement($0) }
        let settable = candidates.filter { element in
            var address = Self.address(property, scope: kAudioDevicePropertyScopeInput, element: element)
            var flag: DarwinBoolean = false
            return AudioObjectHasProperty(id, &address)
                && AudioObjectIsPropertySettable(id, &address, &flag) == noErr && flag.boolValue
        }
        return settable.first == kAudioObjectPropertyElementMain ? [kAudioObjectPropertyElementMain] : settable
    }

    private func defaultInputDeviceID() -> AudioDeviceID? {
        var address = Self.address(kAudioHardwarePropertyDefaultInputDevice)
        var id: AudioDeviceID = 0
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        return AudioObjectGetPropertyData(Self.systemObject, &address, 0, nil, &size, &id) == noErr ? id : nil
    }

    private func inputChannelCount(of id: AudioObjectID) -> Int {
        var address = Self.address(kAudioDevicePropertyStreamConfiguration, scope: kAudioDevicePropertyScopeInput)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(id, &address, 0, nil, &size) == noErr else { return 0 }
        let list = AudioBufferList.allocate(maximumBuffers: Int(size) / MemoryLayout<AudioBuffer>.size + 1)
        defer { free(list.unsafeMutablePointer) }
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, list.unsafeMutablePointer) == noErr else { return 0 }
        return list.reduce(0) { $0 + Int($1.mNumberChannels) }
    }

    private func string(_ selector: AudioObjectPropertySelector, of id: AudioObjectID) -> String? {
        var address = Self.address(selector)
        var value: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &value) == noErr, let value else { return nil }
        return value.takeRetainedValue() as String
    }

    private static func address(_ selector: AudioObjectPropertySelector,
                                scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
                                element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element)
    }
}
