#!/usr/bin/env bash
# Regenerates the channel contracts for Dart, Swift and Kotlin.
#
# There are two, and they stay separate: pigeons/unplug_api.dart is the Unplug
# module's screen-time boundary, and pigeons/tether_store_api.dart is the
# shell's key/value store. They are regenerated together because forgetting one
# is the failure this script exists to prevent, but neither knows about the
# other.
#
# The generated files are checked in so a clean checkout compiles without a
# code-generation step. Run this after editing either input, and commit the
# result — never edit a .g.dart, .g.swift or .g.kt by hand.
#
# Deliberately no `dart format` afterwards. Pigeon's own output is deterministic
# for a pinned pigeon version, but the formatter's style changes between Dart
# releases; formatting here would make the CI freshness check fail whenever CI's
# Dart differs from the developer's, which says nothing about whether the
# contract is stale.
set -euo pipefail
cd "$(dirname "$0")/.."
dart run pigeon --input pigeons/unplug_api.dart
dart run pigeon --input pigeons/tether_store_api.dart
echo "Regenerated the Unplug and Tether store channel contracts."
