fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android preflight

```sh
[bundle exec] fastlane android preflight
```

Check flutter, signing and the Play key are all present

### android build

```sh
[bundle exec] fastlane android build
```

Build the release app bundle without uploading

### android beta

```sh
[bundle exec] fastlane android beta
```

Build an AAB and upload it to the Play internal testing track

### android release

```sh
[bundle exec] fastlane android release
```

Build an AAB and upload it to the Play production track

### android promote

```sh
[bundle exec] fastlane android promote
```

Promote an already-uploaded build between tracks without rebuilding

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
