//
//  MicrophoneStatus.swift
//  PushToTalk
//
//  Created by Chris Nielubowicz on 12/5/16.
//  Copyright © 2016 yulrizka. All rights reserved.
//

import AppKit

enum MicrophoneStatus {
    case muted
    case speaking
    case disabled
    case recordingHotKey

    var isMuted: Bool { self == .muted || self == .recordingHotKey }

    var toggleTitle: String { self == .disabled ? "Enable" : "Disable" }

    var image: NSImage {
        let (symbol, color, label): (String, NSColor?, String) = switch self {
        case .muted: ("mic.slash.fill", nil, "Microphone muted")
        case .speaking: ("mic.fill", .systemGreen, "Microphone live")
        case .disabled: ("mic.fill", .systemGray, "PushToTalk disabled, microphone open")
        case .recordingHotKey: ("keyboard", nil, "Waiting for a new hotkey")
        }
        var configuration = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        if let color { configuration = configuration.applying(.init(paletteColors: [color])) }
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)!.withSymbolConfiguration(configuration)!
        // Template images follow the menu bar appearance; colored ones must not be templates.
        image.isTemplate = color == nil
        return image
    }
}
