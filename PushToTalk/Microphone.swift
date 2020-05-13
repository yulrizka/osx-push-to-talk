//
//  Microphone.swift
//  PushToTalk
//
//  Created by Chris Nielubowicz on 12/5/16.
//  Copyright © 2016 yulrizka. All rights reserved.
//

import Cocoa
import AudioToolbox
import Carbon.HIToolbox

class DeviceMenuItem: NSMenuItem {
    var inputDevice: InputDevice?
}

class Microphone {
    
    typealias StatusUpdate = (MicrophoneStatus) -> ()
    var statusUpdated: StatusUpdate?
    var selectedInput: InputDevice?
    
    /* Public method to set status of the microphone
     * 
     * @discussion
     *      This method calls necessary private methods to mute or unmute the microphone
     */
    var status: MicrophoneStatus = .Muted {
        didSet {
            self.setMuted(status == .Muted)
            self.statusUpdated?(status)
        }
    }
    
    init() {
        // handle when application is on background
        NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.flagsChanged, handler: self.handleFlagChangedEvent)
        
        // handle when application is on foreground
        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.flagsChanged, handler: { (theEvent) -> NSEvent? in
            self.handleFlagChangedEvent(theEvent)
            return theEvent
        })
    }
    
    func toggle() {
        self.status = (self.status == .Muted) ? .Speaking : .Muted
    }
    
    func setupDeviceMenu(menu: NSMenu) throws {
        menu.removeAllItems()
        let devices = try? getInputDevices()
        self.selectedInput = devices![0]
        for device in devices! {
            let item = DeviceMenuItem()
            item.inputDevice = device
            item.title = device.name
            item.target = self
            item.action = #selector(Microphone.itemSelected(item:))
            if item.inputDevice?.id == self.selectedInput?.id {
                item.state = NSControl.StateValue.on
            }
            menu.addItem(item)
        }
    }
    
    @objc func itemSelected(item: DeviceMenuItem) {
        // Disable muting.
        let status = self.status
        self.status = .Speaking
        for i in item.menu!.items {
            i.state = NSControl.StateValue.off
        }
        item.state = NSControl.StateValue.on
        self.selectedInput = item.inputDevice;
        self.status = status
    }
}

struct InputDevice {
    var id: AudioDeviceID = 0
    var name: String = "None"
}

// MARK - Sound Methods
extension Microphone {
    
    func handle(_ errorCode: OSStatus) throws {
        if errorCode != kAudioHardwareNoError {
            let error = NSError(domain: NSOSStatusErrorDomain, code: Int(errorCode), userInfo: [NSLocalizedDescriptionKey : "CAError: \(errorCode)" ])
            NSApplication.shared.presentError(error)
            throw error
        }
    }

    func getInputDevices() throws -> [InputDevice] {

        var inputDevices: [InputDevice] = []

        // Construct the address of the property which holds all available devices
        var devicesPropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
        var propertySize = UInt32(0)

        // Get the size of the property in the kAudioObjectSystemObject so we can make space to store it
        try handle(AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &devicesPropertyAddress, 0, nil, &propertySize))

        // Get the number of devices by dividing the property address by the size of AudioDeviceIDs
        let numberOfDevices = Int(propertySize) / MemoryLayout<AudioDeviceID>.size

        // Create space to store the values
        var deviceIDs: [AudioDeviceID] = []
        for _ in 0 ..< numberOfDevices {
            deviceIDs.append(AudioDeviceID())
        }

        // Get the available devices
        try handle(AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &devicesPropertyAddress, 0, nil, &propertySize, &deviceIDs))

        // Iterate
        for id in deviceIDs {

            // Get the device name for fun
            var name: CFString = "" as CFString
            var propertySize = UInt32(MemoryLayout<CFString>.size)
            var deviceNamePropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceNameCFString, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
            try handle(AudioObjectGetPropertyData(id, &deviceNamePropertyAddress, 0, nil, &propertySize, &name))

            // Check the input scope of the device for any channels. That would mean it's an input device

            // Get the stream configuration of the device. It's a list of audio buffers.
            var streamConfigAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyStreamConfiguration, mScope: kAudioDevicePropertyScopeInput, mElement: 0)

            // Get the size so we can make room again
            try handle(AudioObjectGetPropertyDataSize(id, &streamConfigAddress, 0, nil, &propertySize))

            // Create a buffer list with the property size we just got and let core audio fill it
            let audioBufferList = AudioBufferList.allocate(maximumBuffers: Int(propertySize))
            try handle(AudioObjectGetPropertyData(id, &streamConfigAddress, 0, nil, &propertySize, audioBufferList.unsafeMutablePointer))

            // Get the number of channels in all the audio buffers in the audio buffer list
            var channelCount = 0
            for i in 0 ..< Int(audioBufferList.unsafeMutablePointer.pointee.mNumberBuffers) {
                channelCount = channelCount + Int(audioBufferList[i].mNumberChannels)
            }

            free(audioBufferList.unsafeMutablePointer)

            // If there are channels, it's an input device
            if channelCount > 0 {
                Swift.print("Found input device '\(name)' with \(channelCount) channels")
                inputDevices.append(InputDevice(id: id, name: name as String))
            }
        }

        return inputDevices
    }
    
    internal func setMuted(_ muted:Bool) {
        
        /* https://github.com/paulreimer/ofxAudioFeatures/blob/master/src/ofxAudioDeviceControl.mm */
        if let input = selectedInput {
            let inputDeviceId = input.id
            
            // set mute
            var address = AudioObjectPropertyAddress(
                mSelector: AudioObjectPropertySelector(kAudioDevicePropertyMute),
                mScope: AudioObjectPropertyScope(kAudioDevicePropertyScopeInput),
                mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
            
            let size = UInt32(MemoryLayout<UInt32>.size)
            var mute:UInt32 = muted ? 1 : 0;
            
            AudioObjectSetPropertyData(inputDeviceId, &address, 0, nil, size, &mute)
        }
    }
}

// MARK - Event Handling
extension Microphone {
    internal func handleFlagChangedEvent(_ theEvent: NSEvent!) { 
        guard theEvent.keyCode == 61 else { return }
        self.status = (theEvent.modifierFlags.contains(NSEvent.ModifierFlags.option)) ? .Speaking : .Muted
    }
}
