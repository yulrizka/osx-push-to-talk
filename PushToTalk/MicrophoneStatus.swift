//
//  MicrophoneStatus.swift
//  PushToTalk
//
//  Created by Chris Nielubowicz on 12/5/16.
//  Copyright © 2016 yulrizka. All rights reserved.
//

import Cocoa

protocol AssociatedImage {
    func image() -> NSImage
    func title() -> String
}

enum MicrophoneStatus {
    case Muted
    case Speaking
    case HotKeySet
    case ExternalControl
}

extension MicrophoneStatus: AssociatedImage {
    func image() -> NSImage {
        switch self {
        case .Muted:
            return NSImage(named: "statusIconMute")!
        case .Speaking:
            return NSImage(named: "statusIconTalk")!
        case .HotKeySet:
            return NSImage(named: "statusIconHotKeySet")!
        case .ExternalControl:
            return NSImage(named: "statusIconTalk")!
        }
    }
    
    func title() -> String {
        switch self {
        case .Muted:
            return "Disable"
        case .Speaking:
            return "Enable"
        case .HotKeySet:
            return "Set HotKey"
        case .ExternalControl:
            return "In Use (External App)"
        }
    }
}

