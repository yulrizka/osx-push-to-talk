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
}

extension MicrophoneStatus: AssociatedImage {
    func image() -> NSImage {
        switch self {
        case .Muted:
            return NSImage(named: NSImage.Name(rawValue: "statusIconMute"))!
        case .Speaking:
            return NSImage(named: NSImage.Name(rawValue: "statusIconTalk"))!
        }
    }
    
    func title() -> String {
        switch self {
        case .Muted:
            return "Disable"
        case .Speaking:
            return "Enable"
        }
    }
}

