#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter was not found on PATH."
  echo "Install it from https://docs.flutter.dev/get-started/install"
  exit 1
fi

case "$(uname -s)" in
  Darwin)
    breathefree_platforms="macos"
    ;;
  Linux)
    breathefree_platforms="linux"
    ;;
  *)
    echo "Use tool/setup_windows.bat on Windows."
    exit 1
    ;;
esac

# flutter create . rewrites .metadata and re-resolves pubspec.lock to newer
# package versions. Keep copies and put them back before flutter pub get, so
# setup analyzes and tests the locked versions and leaves both files unchanged.
# This does not need git.
create_backup="$(mktemp -d "${TMPDIR:-/tmp}/tetherhealth-setup.XXXXXX")"
restore_pending=0

restore_create_files() {
  for file in pubspec.lock .metadata; do
    if [ -f "$create_backup/$file" ]; then
      cp -p "$create_backup/$file" "$file"
    fi
  done
  restore_pending=0
}

cleanup() {
  # If flutter create fails or is interrupted, still put the files back.
  if [ "$restore_pending" = 1 ]; then
    restore_create_files
  fi
  rm -rf "$create_backup"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for file in pubspec.lock .metadata; do
  if [ -f "$file" ]; then
    cp -p "$file" "$create_backup/$file"
  fi
done
restore_pending=1

flutter create . \
  --project-name tetherhealth \
  --org com.TetherHealthLLC \
  --platforms="$breathefree_platforms"
restore_create_files
flutter pub get
flutter analyze
flutter test

echo "BreatheFree setup passed for $breathefree_platforms."
echo "Run flutter devices, then flutter run -d DEVICE_ID."
