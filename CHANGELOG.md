# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

## [0.2.0](https://github.com/BrainRTP/osx-push-to-talk/compare/v0.1.5...v0.2.0) (2026-10-26)

### Features

* native Apple Silicon support: universal binary, macOS 14 or newer, Swift 6 language mode, Xcode 27 project settings
* sticky mute: mute is re-applied every 0.2 s while muted, so other apps cannot unmute the microphone
* the app controls the system default input device or a pinned device remembered by UID; devices refresh on hot-plug
* the hotkey is ignored while other modifiers are held
* the input volume of the controlled device is shown in the status menu
* SF Symbol status icons with a distinct disabled state
* sounds on mute and unmute (Pop and Tink); after a short tap the mute sound waits for the double-tap window so a double tap sounds once
* input volume slider with Lock input volume; sound levels as submenus with presets
* separate levels for the live and muted sounds (0% turns a sound off)
* double tap toggles the lock; single presses never release it
* `prefDoubleTapInterval` overrides the double-tap window
* tools/taptimer.swift measures hotkey timings

### Bug Fixes

* the device selected at launch was never muted although the icon showed muted
* crash when no input device is present
* the microphone went live while recording a new hotkey
* the keyboard icon stayed up after recording a hotkey, caps lock could become a hotkey that never released, and Right Command had no label
* Enable/Disable needed two clicks after a double-tap lock
* the microphone stayed muted after logout, shutdown or a system-initiated quit (Quit used exit(0) and skipped the termination hook); a killed process still leaves it muted, see the README
* devices without a mute control are listed disabled instead of being muted silently
* the app no longer asks for microphone access it does not need
* the double-tap lock used a fixed 0.2 s window; the default is now 0.3 s

### Chores

* CI: current actions, newest Xcode on the runner, universal binary check
* removed the unused DMG assets, tracked Xcode user data and placeholder tests

### [0.1.5](https://github.com/yulrizka/osx-push-to-talk/compare/v0.1.4...v0.1.5) (2020-10-17)


### Features

* HotKey as text, add image status HotKeySet ([#24](https://github.com/yulrizka/osx-push-to-talk/issues/24)) ([d75713f](https://github.com/yulrizka/osx-push-to-talk/commit/d75713fefb217a2ffeb454cebf98825375ccd17f))
* persist hotkey ([#23](https://github.com/yulrizka/osx-push-to-talk/issues/23)) ([585e2da](https://github.com/yulrizka/osx-push-to-talk/commit/585e2da145035e25f5a670d05fa43eb022078021))

### [0.1.4](https://github.com/yulrizka/osx-push-to-talk/compare/v0.1.3...v0.1.4) (2020-10-16)


### Features

* update status image and support dark mode ([#21](https://github.com/yulrizka/osx-push-to-talk/issues/21)) ([044d33f](https://github.com/yulrizka/osx-push-to-talk/commit/044d33f8fa45dd1e4ebb84f19966fb95a388c8d8))

### [0.1.3](https://github.com/yulrizka/osx-push-to-talk/compare/v0.1.2...v0.1.3) (2020-10-15)


### Features

* adding double tap hotkey detection to hold mic open ([#20](https://github.com/yulrizka/osx-push-to-talk/issues/20)) ([f0956bb](https://github.com/yulrizka/osx-push-to-talk/commit/f0956bb09dacff42a354ad440e5ba2119f0864e4))

### 0.1.2 (2020-05-22)


### Features

* Updated to support Catalina and multiple devices. ([#14](https://github.com/yulrizka/osx-push-to-talk/issues/14)) ([940784b](https://github.com/yulrizka/osx-push-to-talk/commit/940784b08662d77c1cf1a400bee64a054cc0e92f))

# 0.1.0

ADDED
* Main functionality to toggle microphone
* App dmg creator format
* Add application and dmg Icons
