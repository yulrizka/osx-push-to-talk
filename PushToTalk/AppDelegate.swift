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
    
    
    let statusItem = NSStatusBar.system().statusItem(withLength: -1)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // add status menu
        talkIcon = NSImage(named: "statusIconTalk")
        muteIcon = NSImage(named: "statusIconMute")
        updateToggleTitle()
        
        statusItem.image = muteIcon
        statusItem.menu = statusMenu
        

        // handle when application is on background
        NSEvent.addGlobalMonitorForEvents(matching: NSEventMask.flagsChanged, handler: handleFlagChangedEvent)
        
        // handle when application is on foreground
        NSEvent.addLocalMonitorForEvents(matching: NSEventMask.flagsChanged, handler: { (theEvent) -> NSEvent! in
            self.handleFlagChangedEvent(theEvent)
            return theEvent
        })
    }
    
    
    func handleFlagChangedEvent(_ theEvent:NSEvent!) {
        if !self.enable {
            return
        }
        
        if theEvent.modifierFlags.contains(.option) {
           self.toggleMic(true)
        } else {
           self.toggleMic(false)
        }    
    }
    
    /**
    Helper function triggered whenever the button in pressed
    
    :param: enable set the state of the microphone
    */
    func toggleMic(_ enable:Bool) {
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
    func getDefaultInputDevice(_ defaultOutputDeviceID:inout UInt32)  {
        defaultOutputDeviceID = AudioDeviceID(0)
        var defaultOutputDeviceIDSize = UInt32(MemoryLayout.size(ofValue: defaultOutputDeviceID))
        
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
        var volumeSize = UInt32(MemoryLayout.size(ofValue: volume))
        
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
    func toggleMute(_ mute:Bool) {
      
        /* https://github.com/paulreimer/ofxAudioFeatures/blob/master/src/ofxAudioDeviceControl.mm */
        
        var defaultInputDeviceId = AudioDeviceID(0)
        getDefaultInputDevice(&defaultInputDeviceId)

        // set mute
        var address = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyMute),
            mScope: AudioObjectPropertyScope(kAudioDevicePropertyScopeInput),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        
        let size = UInt32(MemoryLayout<UInt32>.size)
        var mute:UInt32 = mute ? 1 : 0;
        
        let err = AudioObjectSetPropertyData(defaultInputDeviceId, &address, 0, nil, size, &mute)
    }
    
    func updateToggleTitle() {
        if (enable) {
            menuItemToggle.title = "Disable"
            statusItem.image = muteIcon
        } else {
            menuItemToggle.title = "Enable"
            statusItem.image = talkIcon
        }
    }
    
    // MARK: Menu item Actions
    @IBAction func toggleAction(_ sender: NSMenuItem) {
        enable = !enable
        toggleMute(enable)
        updateToggleTitle()
    }
    
    @IBAction func menuItemQuitAction(_ sender: NSMenuItem) {
        toggleMute(false)
        exit(0)
    }
}

