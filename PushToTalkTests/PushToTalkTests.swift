//
//  PushToTalkTests.swift
//  PushToTalkTests
//

import AppKit
import XCTest
@testable import PushToTalk

final class PushToTalkTests: XCTestCase {
    @MainActor func testHotKeyIgnoresExtraModifiers() {
        XCTAssertTrue(HotKey.matches([.option], hotkey: .option))
        XCTAssertTrue(HotKey.matches([.option, .capsLock], hotkey: .option), "caps lock state is not a held modifier")
        XCTAssertFalse(HotKey.matches([.option, .command], hotkey: .option))
        XCTAssertFalse(HotKey.matches([], hotkey: .option))
    }

    @MainActor func testOnlyMutedStatesMuteTheDevice() {
        XCTAssertTrue(MicrophoneStatus.muted.isMuted)
        XCTAssertTrue(MicrophoneStatus.recordingHotKey.isMuted)
        XCTAssertFalse(MicrophoneStatus.speaking.isMuted)
        XCTAssertFalse(MicrophoneStatus.disabled.isMuted)
    }

    @MainActor func testDefaultHotKeyIsRightOption() {
        XCTAssertEqual(KeyCodeHelper.keyChars(keyCode: 61), "Right-⌥")
    }
}
