//
//  AppDelegate.swift
//  PushToTalk
//
//  Created by Ahmy Yulrizka on 17/03/15.
//  Copyright (c) 2015 yulrizka. All rights reserved.
//
// Modified by Denis Smolyar on 13.12.2025
// добавил мониторинг микрофона, если его включила сторонняя программа.
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
    let microphoneMonitor = MicrophoneMonitor.shared

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

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
            self.statusItem.button?.image = status.image()
        }
        self.microphone.status = .Muted
        self.refreshDevices(nil);

        // Setup microphone monitoring
        self.setupMicrophoneMonitoring()
    }

    // MARK: - Microphone Monitoring Setup

    func setupMicrophoneMonitoring() {
        // Handle microphone status changes (running/stopped)
        microphoneMonitor.onMicrophoneStatusChanged = { [weak self] isRunning, deviceName in
            guard let self = self else { return }

            NSLog("Microphone '\(deviceName)' is \(isRunning ? "active" : "inactive")")

            // Only update status if not in HotKeySet mode
            if self.microphone.status != .HotKeySet {
                if isRunning {
                    // Microphone is being used by external app
                    // Only switch to ExternalControl if we're not controlling it ourselves
                    if self.microphone.status != .Speaking {
                        self.microphone.status = .ExternalControl
                    }
                } else {
                    // Microphone is not in use
                    // Only switch to Muted if we're in ExternalControl mode
                    if self.microphone.status == .ExternalControl {
                        self.microphone.status = .Muted
                    }
                }
            }
        }

        // Handle microphone mute changes
        microphoneMonitor.onMicrophoneMuteChanged = { [weak self] isMuted, deviceName in
            guard let self = self else { return }

            NSLog("Microphone '\(deviceName)' mute status changed: \(isMuted ? "muted" : "unmuted")")

            // Only update status if not in HotKeySet mode
            if self.microphone.status != .HotKeySet {
                if !isMuted {
                    // Microphone is unmuted (active) by external app
                    // Only switch to ExternalControl if we're not controlling it ourselves
                    if self.microphone.status != .Speaking {
                        self.microphone.status = .ExternalControl
                    }
                } else {
                    // Microphone is muted
                    // Only switch to Muted if we're in ExternalControl mode
                    if self.microphone.status == .ExternalControl {
                        self.microphone.status = .Muted
                    }
                }
            }
        }

        // Handle new microphone connected
        microphoneMonitor.onMicrophoneAdded = { [weak self] deviceName in
            NSLog("New microphone connected: '\(deviceName)'")
            // Refresh device list when new microphone is added
            self?.refreshDevices(nil)
        }

        // Handle microphone disconnected
        microphoneMonitor.onMicrophoneRemoved = { [weak self] deviceName in
            NSLog("Microphone removed: '\(deviceName)'")
            // Refresh device list when microphone is removed
            self?.refreshDevices(nil)
        }

        // Start monitoring
        microphoneMonitor.startMonitoring()
        NSLog("Microphone monitoring initialized")
    }

    // MARK: - Menu item Actions
    @IBAction func toggleAction(_ sender: NSMenuItem) {
        self.hotkey!.toggle()
    }
    
    @IBAction func menuItemQuitAction(_ sender: NSMenuItem) {
        self.microphone.status = .Speaking
        microphoneMonitor.stopMonitoring()
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

