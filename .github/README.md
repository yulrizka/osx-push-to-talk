# OSX PushToTalk

OSX PushToTalk mutes and unmutes the microphone via a keypress. This globally works for multiple video conference solutions (Google meet, Zoom, Skype, etc).

![usage animation](https://user-images.githubusercontent.com/117752/96354725-0eabff00-10da-11eb-9539-6e159e7d588b.gif)

Features:

- Hold a hotkey (default to **Right-⌥**) to unmute and release to mute
- Double tap the hotkey to disable the app. It will unmute until the hotkey is pressed again
- Configurable hotkey
- Configurable device
- Tested with Mojave & Catalina

The icon indicator will become ![red mic](../PushToTalk/Images.xcassets/statusIconTalk.imageset/talk1x.png) if the microphone is live (**NOT** muted).

## Installation

If you run into issues when installing, ensure you have opened XCode at least once and installed the "additional required components."

### HomeBrew

```
$ brew install yulrizka/tap/pushtotalk
```

or 

```
$ brew tap yulrizka/tap # to update the tap repo
$ brew install pushtotalk
```

Read the Caveats
```
==> Caveats
The application was only built in "/usr/local/opt/pushtotalk/PushToTalk.app"

To make it available in the Application folder, create a symlink with:

    ln -s "/usr/local/opt/pushtotalk/PushToTalk.app" "/Applications/PushToTalk.app"
```



### Build from source
```
$ git clone git@github.com:yulrizka/osx-push-to-talk.git
$ cd osx-push-to-talk
$ xcodebuild -target "PushToTalk" -configuration Release
```

This requires you to have `Xcode` installed. Once The building process is finished, you will have the application in `build/Release/` folder.
Move the `PushToTalk.app` to `Applications` directory.

## Troubleshooting

### The app is from an unidentified developer

The main reason the app is not signed is due to the costly yearly subscription of the Apple developer program.
I do not obtain it my self since I am not mainly an Apple developer.

To enable an exception for this app, follow https://support.apple.com/kb/PH11436?locale=en_US

If you want to be sure, just compile the project, Archive & export PushToTalk.app

### Uninstall

Delete `PushToTalk.app` in `Applications` directory

## Acknowledgement

- Status Icon by [jeff](https://thenounproject.com/jeff955/) (CC)
- Keyboard Caps by [Arthur Shlain](https://thenounproject.com/ArtZ91/) (CC)
