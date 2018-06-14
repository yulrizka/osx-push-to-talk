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
    case muted
    case speaking
}

extension MicrophoneStatus: AssociatedImage {
    func image() -> NSImage {
        switch self {
        case .muted:
            return NSImage(named: NSImage.Name(rawValue: "statusIconMute"))!
        case .speaking:
            return NSImage(named: NSImage.Name(rawValue: "statusIconTalk"))!
        }
    }

    func title() -> String {
        switch self {
        case .muted:
            return "Disable"
        case .speaking:
            return "Enable"
        }
    }
}
