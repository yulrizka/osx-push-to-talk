//
//  Microphone.swift
//  PushToTalk
//
//  Created by Chris Nielubowicz on 12/5/16.
//  Copyright © 2016 yulrizka. All rights reserved.
//

import Cocoa
import AudioToolbox

class Microphone {
    
    typealias StatusUpdate = (MicrophoneStatus) -> ()
    var statusUpdated: StatusUpdate?
    
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
        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.flagsChanged, handler: { (theEvent) -> NSEvent! in
            self.handleFlagChangedEvent(theEvent)
            return theEvent
        })
    }
    
    func toggle() {
        self.status = (self.status == .Muted) ? .Speaking : .Muted
    }
}

// MARK - Sound Methods
extension Microphone {
    
    internal func getDefaultInputDevice(_ defaultOutputDeviceID:inout UInt32)  {
        defaultOutputDeviceID = AudioDeviceID(0)
        var defaultOutputDeviceIDSize = UInt32(MemoryLayout.size(ofValue: defaultOutputDeviceID))
        
        var getDefaultInputDevicePropertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDefaultInputDevice),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &getDefaultInputDevicePropertyAddress,
            0,
            nil,
            &defaultOutputDeviceIDSize,
            &defaultOutputDeviceID)
    }
    
    internal func setMuted(_ muted:Bool) {
        
        /* https://github.com/paulreimer/ofxAudioFeatures/blob/master/src/ofxAudioDeviceControl.mm */
        
        var defaultInputDeviceId = AudioDeviceID(0)
        self.getDefaultInputDevice(&defaultInputDeviceId)
        
        // set mute
        var address = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyMute),
            mScope: AudioObjectPropertyScope(kAudioDevicePropertyScopeInput),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        
        let size = UInt32(MemoryLayout<UInt32>.size)
        var mute:UInt32 = muted ? 1 : 0;
        
        AudioObjectSetPropertyData(defaultInputDeviceId, &address, 0, nil, size, &mute)
    }
}

// MARK - Event Handling
extension Microphone {
    internal func handleFlagChangedEvent(_ theEvent: NSEvent!) {
        guard theEvent.keyCode == 61 else { return }
        self.status = (theEvent.modifierFlags.contains(NSEvent.ModifierFlags.option)) ? .Speaking : .Muted
    }
}
