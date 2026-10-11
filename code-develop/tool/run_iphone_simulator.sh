#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "iPhone builds require macOS with Xcode."
  exit 1
fi

open -a Simulator
echo "Waiting for the iOS Simulator..."
sleep 4
flutter devices
flutter run
