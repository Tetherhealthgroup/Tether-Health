# Local flutter_tts patches

This directory vendors `flutter_tts` 4.2.5 because it is the latest pub.dev
release and still triggers upcoming Flutter build errors on current toolchains.
The Dart API and platform behavior are otherwise unchanged.

Applied compatibility changes:

- iOS Swift Package Manager metadata and source layout, based on upstream
  `dlutton/flutter_tts` pull request #657.
- Built-in Kotlin and the modern Kotlin compiler DSL with Flutter 3.44/Dart
  3.12 minimums, based on upstream pull request #656 and Flutter's migration
  guide.

Remove this vendored copy and restore a hosted dependency once an upstream
release includes both fixes.
