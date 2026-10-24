#!/bin/sh
# Canonical Dart format check. Never rewrites files.
# Checks every .dart file under the repo root, found by walking the filesystem
# (tracked and untracked alike), except those under third_party/,
# specs-and-design/tether_ui/, specs-and-design/archive/ and build/ (anchored
# to the repo root, so first-party dirs of the same name deeper in the tree are
# still checked) and hidden directories at any depth, such as .dart_tool/.
# specs-and-design/tether_ui/ is generated code, not dart-formatted; the CI
# regeneration diff check keeps it identical to the generator output.
# Requires `flutter pub get` to have run: without .dart_tool/package_config.json
# dart format cannot resolve the language version and reports false changes, so
# the script exits 2 in that case.
# Exits 1 if any file would change or no Dart files are found.
set -eu

trap 'exit 130' INT
trap 'exit 143' TERM

cd "$(dirname "$0")/.."

if [ ! -f .dart_tool/package_config.json ]; then
  echo "check_format: run 'flutter pub get' first (language version unresolved)" >&2
  exit 2
fi

files=$(mktemp)
trap 'rm -f "$files"' EXIT

find . \
  \( -path ./third_party -o -path ./specs-and-design/tether_ui -o -path ./build -o -path ./specs-and-design/archive -o -name '.?*' \) -prune -o \
  -type f -name '*.dart' -print0 > "$files"

if [ ! -s "$files" ]; then
  echo "check_format: no Dart files found" >&2
  exit 1
fi

xargs -0 dart format --output=none --set-exit-if-changed < "$files"
