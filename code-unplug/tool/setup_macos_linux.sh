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
    breathefree_platforms="android,ios,web,macos"
    ;;
  Linux)
    breathefree_platforms="android,web,linux"
    ;;
  *)
    echo "Use tool/setup_windows.bat on Windows."
    exit 1
    ;;
esac

flutter create . \
  --project-name tether_health \
  --org com.TetherHealthLLC \
  --platforms="$breathefree_platforms"
flutter pub get
flutter analyze
flutter test

echo "BreatheFree setup passed for $breathefree_platforms."
echo "Run flutter devices, then flutter run -d DEVICE_ID."
