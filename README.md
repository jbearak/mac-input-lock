# Mac Input Lock

A small native Mac app that blocks keyboard, mouse, and trackpad input while video
and audio keep playing. Open the menu-bar padlock, press **Lock input**, and wait
five seconds. Type **`sesame`** to unlock, or choose your own word in the panel.

**Control–Option–Command–D** locks or unlocks immediately. The panel also opens
when you launch the app again, even if the padlock is hidden behind the notch.

## Setup

Requires macOS 14 or later. Enable **Mac Input Lock** in **System Settings →
Privacy & Security → Accessibility**. No other permission is needed.

## Build and install

```sh
SIGNING_IDENTITY=- ./Scripts/build-app.sh
./Scripts/install.sh
```

For this Mac's standalone Command Line Tools, prefix the build with
`DEVELOPER_DIR=/Library/Developer/CommandLineTools`. The script uses the installed
macOS 26.5 SDK to avoid the newer SDK's missing SwiftUI macro plugin. Override
`SDKROOT` or `SWIFT_BUILD_SYSTEM` if needed. Full Xcode also works.

The installer replaces the app in `/Applications`, keeps a temporary backup,
and launches the new build. Pass another Applications directory as its first
argument to install elsewhere. An ad-hoc rebuild may need to be removed and
re-added in Accessibility settings because its signing identity changes.

## Development

Run `swift test` with full Xcode selected. Tests cover unlock matching, the global
shortcut, menu-bar recovery, feedback, and saved preferences. The build has no
external dependencies.

The app makes no network requests. There is no updater, account, telemetry, or
paid download flow. Update your installation by pulling this repository and
building again. The app identifier is `com.jbearak.MacInputLock`.

Test the unlock word before using the app. The physical power button remains
active. If unlocking fails, hold it to shut down; unsaved work can be lost.

## Attribution

This personal fork is maintained at [jbearak/mac-input-lock](https://github.com/jbearak/mac-input-lock),
based on [nickdoesntwantspam/mac-input-lock](https://github.com/nickdoesntwantspam/mac-input-lock).
Licensed under MIT; see [LICENSE](LICENSE).
