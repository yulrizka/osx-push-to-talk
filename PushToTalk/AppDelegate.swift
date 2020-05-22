//
//  AppDelegate.swift
//  PushToTalk
//
//  Created by Ahmy Yulrizka on 17/03/15.
//  Copyright (c) 2015 yulrizka. All rights reserved.
//

import Cocoa
import AudioToolbox
import AVKit

@NSApplicationMain

class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var menuItemToggle: NSMenuItem!
    @IBOutlet weak var deviceMenu: NSMenu!
    @IBOutlet weak var hotkeyMenuItem: NSMenuItem!
    
    var microphone = Microphone()
    var hotkey: HotKey?
    
    let statusItem = NSStatusBar.system.statusItem(withLength: -1)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        self.hotkey = HotKey(microphone: microphone, menuItem: hotkeyMenuItem)
        
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .notDetermined: // The user has not yet been asked for camera access.
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    if !granted {
                        NSLog("Can't get access to the mic.")
                        exit(1)
                    }
                }
            
            case .denied: // The user has previously denied access.
                fallthrough
            case .restricted: // The user can't grant access due to restrictions.
                NSLog("Can't get access to the mic.")
                exit(1)
            default:
                print("Already has permission");
        }

        statusItem.menu = statusMenu
        self.microphone.statusUpdated = { (status) in
            self.menuItemToggle.title = status.title()
            self.statusItem.image = status.image()
        }
        self.microphone.status = .Muted
        self.refreshDevices(nil);
    }
    
    
    // MARK: Menu item Actions
    @IBAction func toggleAction(_ sender: NSMenuItem) {
        self.hotkey!.toggle()
    }
    
    @IBAction func menuItemQuitAction(_ sender: NSMenuItem) {
        self.microphone.status = .Speaking
        exit(0)
    }
    
    @IBAction func refreshDevices(_ sender: NSMenuItem?) {
        do {
            try self.microphone.setupDeviceMenu(menu: deviceMenu)
        } catch {
            print("Unexpected Error: \(error).")
            exit(1)
        }
    }
    
    @IBAction func recordNewHotKey(_ sender: NSMenuItem) {
        self.hotkey!.recordNewHotKey()
    }
}

