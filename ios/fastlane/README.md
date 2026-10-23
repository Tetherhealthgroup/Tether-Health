fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios preflight

```sh
[bundle exec] fastlane ios preflight
```

Check the machine and the Xcode project can produce a distributable build

### ios match_bootstrap

```sh
[bundle exec] fastlane ios match_bootstrap
```

One-time: create/fetch distribution certs and profiles for all four targets

### ios match_development

```sh
[bundle exec] fastlane ios match_development
```

Fetch development certs and profiles for all four targets

### ios print_export_options

```sh
[bundle exec] fastlane ios print_export_options
```

Print the export options plist that would be handed to xcodebuild

### ios build

```sh
[bundle exec] fastlane ios build
```

Build a signed App Store IPA (no upload)

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build and upload to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Build and upload to App Store Connect for review

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
