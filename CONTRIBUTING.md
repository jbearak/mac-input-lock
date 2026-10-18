# Contributing

Keep this a small native utility with local input processing and a single
Accessibility permission. The app has no network activity or external dependencies.

Run `swift test`, then `SIGNING_IDENTITY=- ./Scripts/build-app.sh`. See the README
for Command Line Tools builds. Never commit signing certificates or credentials.

Changes to the event tap, shortcut, lock state, or unlock behavior need real-device
verification with a different app focused:

1. Keyboard input, clicks, scrolling, and dragging are suppressed.
2. The configured unlock word restores keyboard and pointer input.
3. Control–Option–Command–D locks and unlocks reliably.
4. Cancelling the countdown leaves input active.

Keep unit tests for pure logic. Describe any manual verification that could not
be completed because of macOS permission state. Updates are built from this fork;
there is no upstream binary update channel.
