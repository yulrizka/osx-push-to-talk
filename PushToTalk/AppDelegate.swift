//
//  AppDelegate.swift
//  PushToTalk
//
//  Created by Ahmy Yulrizka on 17/03/15.
//  Copyright (c) 2015 yulrizka. All rights reserved.
//

import Cocoa
import AudioToolbox

@NSApplicationMain

class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var menuItemToggle: NSMenuItem!

    let microphone = Microphone()

    let statusItem = NSStatusBar.system.statusItem(withLength: -1)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem.menu = statusMenu
        self.microphone.statusUpdated = { (status) in
            self.menuItemToggle.title = status.title()
            self.statusItem.image = status.image()
        }

        self.microphone.status = .muted
    }

    // MARK: Menu item Actions
    @IBAction func toggleAction(_ sender: NSMenuItem) {
        self.microphone.toggle()
    }

    @IBAction func menuItemQuitAction(_ sender: NSMenuItem) {
        self.microphone.status = .speaking
        exit(0)
    }
}
