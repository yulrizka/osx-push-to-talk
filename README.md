# 🎙️ PushToTalk

🇬🇧 English | 🇷🇺 [Русский](README_RU.md)

> A macOS menu bar app: the microphone is on only while the hotkey is held down

## 📖 Description

PushToTalk turns the microphone off and turns it back on for as long as you hold the hotkey. It works globally, in every app that records audio from the input device it controls (Google Meet, Zoom, Teams, Discord and others): the app toggles mute on the device itself, not in an individual program.

![Animation of the app at work](docs/demo.gif)

This is a fork of [yulrizka/osx-push-to-talk](https://github.com/yulrizka/osx-push-to-talk) with a native Apple Silicon build. The build is universal (arm64 + x86_64) and does not need Rosetta. This matters because from macOS 28 Rosetta will remain only for some older games, and Intel-only programs will not run there ([Apple](https://support.apple.com/en-us/102527)). The original does not build in Xcode 27: Xcode does not accept its deployment target 10.14. Some features were taken from forks and open pull requests of the original. The list is in the "Related projects" section.

What the app does:

- The hotkey (right ⌥ by default) turns the microphone on while it is held down and off again when it is released.
- A double press keeps the microphone on; the next double press turns it off. Single presses work as usual and do not release the lock.
- While other modifiers are held, the key is ignored, so combinations like ⌘⌥ do not turn the microphone on.
- While the microphone is off, mute is reapplied every 0.2 seconds (sticky mute): if another program resets the input device, the mute comes back.
- The app controls the default input device or the one you pinned in the menu. The choice is remembered, and the device list updates when devices are connected or disconnected.
- The menu shows the input volume (sensitivity) of the controlled device, with a slider to change it and a lock that restores it when another app changes it.
- The menu bar icon shows the state: microphone off, microphone on, app disabled, or waiting for a new key.
- A sound marks every change: Pop when the microphone goes live, Tink when it is muted. After a short tap the mute sound waits for the double-tap window, so a double press gives one sound. Each sound has its own level in the menu (0% turns it off).

## 🔧 Tech stack

| Layer    | Technology                                   |
|----------|----------------------------------------------|
| Language | Swift 6                                      |
| UI       | AppKit, menu bar app                         |
| Audio    | CoreAudio: device mute and input volume      |
| Build    | Xcode 26+, universal binary (arm64 + x86_64) |

## 🚀 Quick start

### Requirements

1. macOS 14 or newer to run the app.
2. Xcode 26 or newer to build it from source.
3. There are no third-party dependencies.

### Prebuilt build

1. Open the latest run of the [Build](https://github.com/BrainRTP/osx-push-to-talk/actions/workflows/Build.yaml) workflow and download the `PushToTalk.app` artifact.
2. Extract the archive and move `PushToTalk.app` to `/Applications`.
3. The app is ad hoc signed and not notarized, so macOS will not open the downloaded copy. Remove the quarantine flag with the command below or allow it in System Settings > Privacy & Security > Open Anyway.

```bash
# Remove the quarantine flag from the downloaded copy
xattr -dr com.apple.quarantine /Applications/PushToTalk.app
```

### Building from source

```bash
git clone https://github.com/BrainRTP/osx-push-to-talk.git
cd osx-push-to-talk

# Release build, output: build/Release/PushToTalk.app
xcodebuild -project PushToTalk.xcodeproj -target PushToTalk -configuration Release

# Install (ditto, not cp -R: cp would put the new bundle inside the one already installed)
rm -rf /Applications/PushToTalk.app && ditto build/Release/PushToTalk.app /Applications/PushToTalk.app
```

A copy built locally has no quarantine flag, so there is nothing to remove.

### Homebrew

The fork has no tap of its own. The original's tap (`brew install yulrizka/tap/pushtotalk`) builds the original version 0.1.5: it has none of the fork's changes, and it does not build in Xcode 27 because Xcode 27's minimum deployment target is macOS 12.

### Running and uninstalling

Launch `PushToTalk.app`: an icon appears in the menu bar. To uninstall the app, quit it (this lifts the mute) and delete `PushToTalk.app` from `/Applications`. Settings are stored in `~/Library/Preferences/com.yulrizka.PushToTalk.plist`.

## 🎛️ Usage

After launch the icon appears in the menu bar and the microphone is muted. The app does not ask for microphone access: it changes the mute property of the device through CoreAudio.

### Hotkey

- To set a new key, choose `Change HotKey` in the menu and press a modifier: ⌥, ⌘, ⌃, ⇧ or fn, left or right. Regular keys and Caps Lock do not work.
- The double-tap window is 0.3 seconds. To change it, run `defaults write com.yulrizka.PushToTalk prefDoubleTapInterval -float 0.35`, no restart needed.

### Menu bar icon

| Icon                      | State                                                                         |
|---------------------------|-------------------------------------------------------------------------------|
| 🔇 Crossed-out microphone | The microphone is off                                                         |
| 🟢 Green microphone       | The microphone is on: the key is held down or locked by a double press        |
| ⚪ Gray microphone        | The app is disabled and the microphone is on, or the input device has no mute |
| ⌨️ Keyboard               | The app is waiting for a new hotkey                                           |

### Menu

| Item                                               | What it does                                                                        |
|----------------------------------------------------|-------------------------------------------------------------------------------------|
| `Input volume: N%` + slider                        | Input volume (sensitivity) of the device, `n/a` if the device has no volume control |
| `Lock input volume`                                | Restores the volume when another app changes it. Turns off when the device changes  |
| `Sound when live (Pop)`, `Sound when muted (Tink)` | Sound levels for mute and unmute, 0% turns the sound off                            |
| `Disable` / `Enable`                               | Stops controlling the microphone and leaves it on / mutes it again                  |
| `Devices`                                          | `System Default` or a pinned device. Devices without mute cannot be selected        |
| `Refresh Devices`                                  | Refreshes the list by hand, normally it updates on its own                          |
| `Change HotKey (Right-⌥)`                          | Records a new key, the current one is in parentheses                                |
| `Quit PushToTalk`                                  | Quits the app and lifts the mute                                                    |

### Quitting and settings

Quitting the app, logging out or shutting down the Mac lifts the mute. Settings are stored in `~/Library/Preferences/com.yulrizka.PushToTalk.plist`.

## 🧪 Testing

```bash
# Unit tests (XCTest)
xcodebuild test -project PushToTalk.xcodeproj -scheme PushToTalk -destination 'platform=macOS'
```

CI ([Build](https://github.com/BrainRTP/osx-push-to-talk/actions/workflows/Build.yaml)) builds the universal app, checks both architectures and saves `PushToTalk.app` as an artifact. It does not run the tests.

`tools/taptimer.swift` helps pick the double-tap window: it measures how you press the hotkey and suggests a value. Press the key as usual, then Ctrl-C to see the result.

```bash
mkdir -p build && swiftc -O -o build/taptimer tools/taptimer.swift && build/taptimer
```

## 🩺 Troubleshooting

### The hotkey does nothing

Watching modifiers usually needs no permissions. If the app does not respond, add PushToTalk to System Settings > Privacy & Security > Input Monitoring (or Accessibility) and restart it. If the icon is gray and the menu shows the `Enable` item, the app is disabled: enable it.

### "PushToTalk is damaged and can't be opened" or "unidentified developer"

The app is ad hoc signed and not notarized. Remove the quarantine flag as described in the "Prebuilt build" section, or build the app from source.

### People can't hear me even though the icon is green

Check the input volume in the menu and raise it with the slider. If it keeps dropping, turn on `Lock input volume`: some apps lower the system input level automatically.

### The icon is gray, the tooltip says "The input device has no mute control"

The input device macOS uses has no mute control, for example the iPhone microphone via Continuity. The app will not pick another device on its own: muting a microphone that macOS is not using would leave the working one on. Switch the input in System Settings > Sound > Input to a device that has mute. The same icon and tooltip appear when there are no input devices at all.

### The microphone stayed muted after the app was killed

Quitting the app lifts the mute, and a killed process (for example, with Force Quit) cannot do that. Launch the app and quit it again.

### Mute is not applied

CoreAudio write errors (with an OSStatus code) go to the log under the subsystem `com.yulrizka.PushToTalk`:

```bash
log stream --predicate 'subsystem == "com.yulrizka.PushToTalk"'
```

## 🔗 Related projects

> Current as of 2026-10-26. Feature ideas were taken from the forks listed here.

| Project                                                                              | Relationship                                                                                                                                                                          |
|--------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [yulrizka/osx-push-to-talk](https://github.com/yulrizka/osx-push-to-talk)            | The original, the fork started from its version 0.1.5. Author: Ahmy Yulrizka                                                                                                          |
| [yulrizka/osx-push-to-talk#44](https://github.com/yulrizka/osx-push-to-talk/pull/44) | A pull request with microphone state monitoring, not merged into the original. The idea of refreshing devices on connect was reimplemented, without the vendored library from this PR |
| [12joan/push-to-talk](https://github.com/12joan/push-to-talk)                        | The idea of reapplying mute every 0.2 seconds                                                                                                                                         |
| [gerotakke/osx-push-to-talk](https://github.com/gerotakke/osx-push-to-talk)          | The idea of remembering the selected input device                                                                                                                                     |
| [arx8x/osx-push-to-talk](https://github.com/arx8x/osx-push-to-talk)                  | The idea of remembering the selected input device                                                                                                                                     |
| [RoryQ/osx-push-to-talk](https://github.com/RoryQ/osx-push-to-talk)                  | The idea of ignoring the hotkey when other modifiers are held                                                                                                                         |
| [darruda/osx-push-to-talk](https://github.com/darruda/osx-push-to-talk)              | The idea of colored state icons                                                                                                                                                       |
| [nielubowicz/osx-push-to-talk](https://github.com/nielubowicz/osx-push-to-talk)      | The idea of colored state icons                                                                                                                                                       |

## 🔗 Links

- [Original repository](https://github.com/yulrizka/osx-push-to-talk)
- [This fork](https://github.com/BrainRTP/osx-push-to-talk)
- [Build workflow in GitHub Actions](https://github.com/BrainRTP/osx-push-to-talk/actions/workflows/Build.yaml)
- [Apple: Using Intel-based apps on a Mac with Apple silicon](https://support.apple.com/en-us/102527): Rosetta works in macOS 27 and earlier, from macOS 28 only for some older games
- [Version history](CHANGELOG.md)
- [Authors and contributors](AUTHORS)
- [MIT license](LICENSE)
- App icon: [jeff](https://thenounproject.com/jeff955/) (CC)

## 👤 Maintainers

[@BrainRTP](https://github.com/BrainRTP) (Stanislav Panchenko), original author: Ahmy Yulrizka ([@yulrizka](https://github.com/yulrizka))
