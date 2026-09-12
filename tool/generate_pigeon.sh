#!/usr/bin/env bash
# Regenerates the Unplug channel contract for Dart, Swift and Kotlin.
#
# The generated files are checked in so a clean checkout compiles without a
# code-generation step. Run this after editing pigeons/unplug_api.dart, and
# commit the result — never edit a .g.dart, .g.swift or .g.kt by hand.
set -euo pipefail
cd "$(dirname "$0")/.."
dart run pigeon --input pigeons/unplug_api.dart
dart format \
  lib/unplug/platform/unplug_api.g.dart
echo "Regenerated the Unplug channel contract."
