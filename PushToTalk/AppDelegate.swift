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
    
    func toggleMic(enable:Bool) {
        if (enable) {
            statusItem.image = talkIcon
        } else {
            statusItem.image = muteIcon
        }
    }

    

    func mute() {
        /*
        var defaultOutputDeviceID = AudioDeviceID(0)
        var defaultOutputDeviceIDSize = UInt32(sizeofValue(defaultOutputDeviceID))
        
        var getDefaultOutputDevicePropertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDefaultInputDevice),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        
        let status1 = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &getDefaultOutputDevicePropertyAddress,
            0,
            nil,
            &defaultOutputDeviceIDSize,
            &defaultOutputDeviceID)
        
        var volume = Float32(0.50) // 0.0 ... 1.0
        var volumeSize = UInt32(sizeofValue(volume))
        
        var volumePropertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwareServiceDeviceProperty_VirtualMasterVolume),
            mScope: AudioObjectPropertyScope(kAudioDevicePropertyScopeOutput),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        
        let status2 = AudioHardwareServiceSetPropertyData(
            defaultOutputDeviceID,
            &volumePropertyAddress,
            0,
            nil,
            volumeSize,
            &volume)
        */
      
        /* https://github.com/paulreimer/ofxAudioFeatures/blob/master/src/ofxAudioDeviceControl.mm */
        var defaultOutputDeviceID = AudioDeviceID(0)
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

        var volume = Float32(0.50) // 0.0 ... 1.0
        var volumeSize = UInt32(sizeofValue(volume))
        
        var volumePropertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyVolumeScalar),
            mScope: AudioObjectPropertyScope(kAudioDevicePropertyScopeInput),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        
        AudioObjectGetPropertyData(defaultOutputDeviceID, &volumePropertyAddress, 0, nil, &volumeSize, &volume)

        println(volume)
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
        updateToggleTitle()
    }
    
    @IBAction func menuItemQuitAction(sender: NSMenuItem) {
        exit(0)
    }
}

