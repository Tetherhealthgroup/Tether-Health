#!/bin/sh
# Canonical Dart format check. Never rewrites files.
# Checks every .dart file under the repo root, found by walking the filesystem
# (tracked and untracked alike), except those under third_party/ (vendored,
# not reformatted), build/, and hidden directories such as .dart_tool/.
# Exits non-zero if any file would change, or if no Dart files are found.
set -eu

cd "$(dirname "$0")/.."

files=$(mktemp)
trap 'rm -f "$files"' EXIT

find . \
  \( -name third_party -o -name build -o -name '.?*' \) -prune -o \
  -type f -name '*.dart' -print0 > "$files"

if [ ! -s "$files" ]; then
  echo "check_format: no Dart files found" >&2
  exit 1
fi

xargs -0 dart format --output=none --set-exit-if-changed < "$files"
