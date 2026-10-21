#!/usr/bin/env bash
# Regenerates the Unplug channel contract for Dart, Swift and Kotlin from
# pigeons/unplug_api.dart.
#
# The generated files are checked in so a clean checkout compiles without a
# code-generation step. Run this after editing the input, and commit the
# result — never edit a .g.dart, .g.swift or .g.kt by hand.
#
# The generated Dart is passed through `dart format`, because
# tool/check_format.sh checks every Dart file under lib/ and Pigeon's raw
# output is not formatted. Run it with the Flutter version CI pins
# (.github/workflows/flutter-ci.yml): the formatter's style changes between
# Dart releases, and CI regenerates with the pinned version and fails on any
# difference.
set -euo pipefail
cd "$(dirname "$0")/.."
dart run pigeon --input pigeons/unplug_api.dart
dart format lib/unplug/platform/unplug_api.g.dart
echo "Regenerated the Unplug channel contract."
