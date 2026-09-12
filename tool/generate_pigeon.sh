#!/usr/bin/env bash
# Regenerates the Unplug channel contract for Dart, Swift and Kotlin.
#
# The generated files are checked in so a clean checkout compiles without a
# code-generation step. Run this after editing pigeons/unplug_api.dart, and
# commit the result — never edit a .g.dart, .g.swift or .g.kt by hand.
#
# Deliberately no `dart format` afterwards. Pigeon's own output is deterministic
# for a pinned pigeon version, but the formatter's style changes between Dart
# releases; formatting here would make the CI freshness check fail whenever CI's
# Dart differs from the developer's, which says nothing about whether the
# contract is stale.
set -euo pipefail
cd "$(dirname "$0")/.."
dart run pigeon --input pigeons/unplug_api.dart
echo "Regenerated the Unplug channel contract."
