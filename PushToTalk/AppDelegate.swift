//
//  AppDelegate.swift
//  PushToTalk
//
//  Created by Ahmy Yulrizka on 17/03/15.
//  Copyright (c) 2015 yulrizka. All rights reserved.
//

import Cocoa
import AudioToolbox
import Foundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var menuItemToggle: NSMenuItem!
    
    let keyDownMask = 0x80140
    let keyUpMask = 0x100
    var talking = false
    var enable = true
    
    var talkIcon:NSImage?
    var muteIcon:NSImage?
    
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        // add status menu
        talkIcon = NSImage(named: "statusIconTalk")
        muteIcon = NSImage(named: "statusIconMute")
        updateToggleTitle()
        
        statusItem.image = muteIcon
        statusItem.menu = statusMenu
        

        // handle when application is on background
        NSEvent.addGlobalMonitorForEventsMatchingMask(NSEventMask.FlagsChangedMask, handler: handleFlagChangedEvent)
        
        // handle when application is on foreground
        NSEvent.addLocalMonitorForEventsMatchingMask(NSEventMask.FlagsChangedMask, handler: { (theEvent) -> NSEvent! in
            self.handleFlagChangedEvent(theEvent)
            return theEvent
        })
    }
    
    
    func handleFlagChangedEvent(theEvent:NSEvent!) {
        if !self.enable {
            return
        }
        
        if theEvent.keyCode == 61 {
            if(theEvent.modifierFlags & NSEventModifierFlags.AlternateKeyMask != nil) {
                self.toggleMic(true)
            } else if theEvent.modifierFlags != nil {
                self.toggleMic(false)
            }
        }
    }
    
    /**
    Helper function triggered whenever the button in pressed
    
    :param: enable set the state of the microphone
    */
    func toggleMic(enable:Bool) {
        if (enable) {
            toggleMute(false)
            statusItem.image = talkIcon
        } else {
            toggleMute(true)
            statusItem.image = muteIcon
        }
    }

    /**
    Function to get default output volume
    
    :param: defaultOutputDeviceID inputoutput variable result of deviceID
    */
    func getDefaultInputDevice(inout defaultOutputDeviceID:UInt32)  {
        defaultOutputDeviceID = AudioDeviceID(0)
        var defaultOutputDeviceIDSize = UInt32(sizeofValue(defaultOutputDeviceID))
        
        var getDefaultInputDevicePropertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDefaultInputDevice),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        
        let status1 = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &getDefaultInputDevicePropertyAddress,
            0,
            nil,
            &defaultOutputDeviceIDSize,
            &defaultOutputDeviceID)
    }
    
    /**
    Return default Output volume
    
    :returns: default output folume level 0.0 ... 1.0
    */
    func getDefaultOutputVolume() -> Float32 {
        var defaultInputDeviceId = AudioDeviceID(0)
        getDefaultInputDevice(&defaultInputDeviceId)
        
        // show volume
        var volume = Float32(0.50) // 0.0 ... 1.0
        var volumeSize = UInt32(sizeofValue(volume))
        
        var volumePropertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyVolumeScalar),
            mScope: AudioObjectPropertyScope(kAudioDevicePropertyScopeInput),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        
        AudioObjectGetPropertyData(defaultInputDeviceId, &volumePropertyAddress, 0, nil, &volumeSize, &volume)
        
        return volume
    }

    /**
    Function to mute the default input microphone
    */
    func toggleMute(mute:Bool) {
      
        /* https://github.com/paulreimer/ofxAudioFeatures/blob/master/src/ofxAudioDeviceControl.mm */
        
        var defaultInputDeviceId = AudioDeviceID(0)
        getDefaultInputDevice(&defaultInputDeviceId)

        // set mute
        var address = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyMute),
            mScope: AudioObjectPropertyScope(kAudioDevicePropertyScopeInput),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        
        var size = UInt32(sizeof(UInt32))
        var mute:UInt32 = mute ? 1 : 0;
        
        let err = AudioObjectSetPropertyData(defaultInputDeviceId, &address, 0, nil, size, &mute)
    }
    
    func updateToggleTitle() {
        if (enable) {
            menuItemToggle.title = "Disable"
        } else {
            menuItemToggle.title = "Enable"
        }
    }
    
    // MARK: Menu item Actions
    @IBAction func toggleAction(sender: NSMenuItem) {
        enable = !enable
        toggleMute(enable)
        updateToggleTitle()
    }
    
    @IBAction func menuItemQuitAction(sender: NSMenuItem) {
        exit(0)
    }
}

