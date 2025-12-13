//
//  MicrophoneMonitor.swift
//  PushToTalk
//
//  Created for microphone monitoring integration
//

import Foundation

class MicrophoneMonitor {

    static let shared = MicrophoneMonitor()
    private init() {}

    // Callbacks for microphone events
    var onMicrophoneStatusChanged: ((_ isRunning: Bool, _ deviceName: String) -> Void)?
    var onMicrophoneAdded: ((_ deviceName: String) -> Void)?
    var onMicrophoneRemoved: ((_ deviceName: String) -> Void)?
    var onMicrophoneMuteChanged: ((_ isMuted: Bool, _ deviceName: String) -> Void)?

    /// Start monitoring audio device events
    func startMonitoring() {
        NotificationCenter.defaultCenter.subscribe(
            self,
            eventType: AudioHardwareEvent.self,
            dispatchQueue: DispatchQueue.main
        )
        NotificationCenter.defaultCenter.subscribe(
            self,
            eventType: AudioDeviceEvent.self,
            dispatchQueue: DispatchQueue.main
        )

        print("MicrophoneMonitor: Started monitoring microphone events")
    }

    /// Stop monitoring audio device events
    func stopMonitoring() {
        NotificationCenter.defaultCenter.unsubscribe(self, eventType: AudioHardwareEvent.self)
        NotificationCenter.defaultCenter.unsubscribe(self, eventType: AudioDeviceEvent.self)

        print("MicrophoneMonitor: Stopped monitoring microphone events")
    }
}

// MARK: - EventSubscriber Protocol
extension MicrophoneMonitor: EventSubscriber {

    func eventReceiver(_ event: Event) {
        // Handle AudioDeviceEvent
        if let deviceEvent = event as? AudioDeviceEvent {
            handleDeviceEvent(deviceEvent)
        }

        // Handle AudioHardwareEvent
        if let hardwareEvent = event as? AudioHardwareEvent {
            handleHardwareEvent(hardwareEvent)
        }
    }

    var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }

    // MARK: - Private Event Handlers

    private func handleDeviceEvent(_ event: AudioDeviceEvent) {
        switch event {
        case .isRunningSomewhereDidChange(audioDevice: let audioDevice):
            // Only process input devices (microphones)
            guard audioDevice.isInputOnlyDevice() else { return }

            let isRunning = audioDevice.isRunningSomewhere()
            let deviceName = audioDevice.name

            print("MicrophoneMonitor: Device '\(deviceName)' isRunning: \(isRunning)")
            onMicrophoneStatusChanged?(isRunning, deviceName)

        case .muteDidChange(audioDevice: let audioDevice, channel: let channel, direction: let direction):
            // Only process input direction (recording)
            guard direction == .recording else { return }
            guard audioDevice.isMicroDevice() else { return }

            // Check mute status
            if let isMuted = audioDevice.isMuted(channel: channel, direction: .recording) {
                let deviceName = audioDevice.name
                print("MicrophoneMonitor: Device '\(deviceName)' mute changed: \(isMuted)")
                onMicrophoneMuteChanged?(isMuted, deviceName)
            }

        default:
            break
        }
    }

    private func handleHardwareEvent(_ event: AudioHardwareEvent) {
        switch event {
        case .deviceListChanged(addedDevices: let addedDevices, removedDevices: let removedDevices):

            // Handle added microphones
            if let addedMic = addedDevices.first(where: { $0.isMicroDevice() }) {
                let deviceName = addedMic.name
                print("MicrophoneMonitor: Microphone added: '\(deviceName)'")
                onMicrophoneAdded?(deviceName)
            }

            // Handle removed microphones
            if let removedMic = removedDevices.first(where: { $0.isMicroDevice() }) {
                let deviceName = removedMic.name
                print("MicrophoneMonitor: Microphone removed: '\(deviceName)'")
                onMicrophoneRemoved?(deviceName)
            }

        default:
            break
        }
    }
}
