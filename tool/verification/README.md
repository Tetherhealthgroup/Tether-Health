# On-device verification

Persistence is the one part of the shell a widget test cannot prove. Under
`flutter test` there is no platform side at all: `SessionStore.open` finds no
host, falls back to memory, and every assertion passes without a byte crossing
the channel. The fourteen tests in `test/tether_persistence_test.dart` prove the
Dart is right — they do not prove that `TetherStore.swift` is registered, that
the Pigeon channel names match on both sides, or that anything survives a
relaunch.

`persistence_on_device_test.dart.txt` does prove those. It is parked here as a
`.txt` rather than living in `integration_test/`, and that is deliberate.

## Why it is not a permanent dev dependency

Adding `integration_test` to `dev_dependencies` puts
`integration_test.framework` inside **release** builds. Verified on this
project with Flutter 3.44.2:

    $ flutter build ios --release --no-codesign
    $ ls build/ios/iphoneos/Runner.app/Frameworks/
    App.framework  Flutter.framework  integration_test.framework

`.flutter-plugins-dependencies` correctly marks it `dev_dependency: true`, but
`packages/flutter_tools/bin/podhelper.rb` contains no dev-dependency handling —
`flutter_install_all_ios_pods` installs every plugin into every configuration.
Shipping a test harness inside a patient-facing health app is not a trade worth
making for the convenience of leaving a dependency declared.

## Running it

    cp tool/verification/persistence_on_device_test.dart.txt \
       integration_test/persistence_on_device_test.dart

Add to `dev_dependencies` in `pubspec.yaml`:

    integration_test:
      sdk: flutter

Then, against a booted simulator or a connected device:

    flutter pub get
    flutter test integration_test/persistence_on_device_test.dart -d <device-id>

Afterwards, revert both changes and confirm the release bundle is clean again:

    flutter build ios --release --no-codesign
    ls build/ios/iphoneos/Runner.app/Frameworks/   # App + Flutter only

## Last run

iPhone 17 simulator, iOS 26.5, Flutter 3.44.2 — all three tests passed:

- the platform store is actually there (`isDurable` is true, so the native
  store answered rather than the in-memory fallback)
- a session survives being closed and reopened
- deleting everything clears the device too

## Android, checked by hand

The same store was verified on a Pixel 8 (API 34) emulator by driving the real
app rather than by running this file, and the check was better than the one it
replaces: the emulator ran out of resources mid-session and Android killed the
process outright. On a cold relaunch the joined program was still there,
showing "ACTIVE · WEEK 1".

That is a stronger result than a graceful close, because nothing got the chance
to flush on the way out — the debounced write had already reached
`SharedPreferences` before the process died.
