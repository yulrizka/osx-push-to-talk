# OSX PushToTalk

OSX PushToTalk mutes and unmutes the microphone via a keypress.

![screenshoot](assets/screenshoot.png)

Features:

- Hold a hotkey (default to **Right option**) to unmute and release to mute
- Configurable hotkey ([@jeremyellison](https://github.com/yulrizka/osx-push-to-talk/commits?author=jeremyellison))
- Configurable device ([@jeremyellison](https://github.com/yulrizka/osx-push-to-talk/commits?author=jeremyellison))
- Tested with Mojave & Catalina

The icon indicator will be translucent if the microphone is muted.

Application Installer (dmg) can be downloaded in the [Release](https://github.com/yulrizka/osx-push-to-talk/releases) Section

## Troubleshooting

### Support for Catalina

Catalina does not allow application from unsigned developer. The next section will only work for OSX before catalina.

To run this on Catalina, build the application yourself

```
$ git clone git@github.com:yulrizka/osx-push-to-talk.git
$ cd osx-push-to-talk
$ xcodebuild -target "PushToTalk" -configuration Release
```

This requires you to have `Xcode` installed. Once The building process is finished, you will have the application in `build/Release/` folder.
Move the `PushToTalk.app` to `Applications` directory.

### The app is from an unidentified developer

The main reason the app is not signed is due to the costly yearly subscription of the Apple developer program.
I do not obtain it my self since I am not mainly an Apple developer.

To enable an exception for this app, follow https://support.apple.com/kb/PH11436?locale=en_US

If you want to be sure, just compile the project, Archive & export PushToTalk.app

### Uninstall

Delete `PushToTalk.app` in `Applications` directory

## Acknowledgement

Status Icon by [jeff](https://thenounproject.com/jeff955/) (CC)
