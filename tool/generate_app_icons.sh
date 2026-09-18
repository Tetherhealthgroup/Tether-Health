#!/usr/bin/env bash
# Rasterises design/app-icon.svg into every iOS and Android launcher slot.
#
# The rendered icons are checked in because both platforms want them as PNGs in
# fixed locations. Re-run this after editing the source, and commit the result.
#
# Requires rsvg-convert (brew install librsvg).
set -euo pipefail
cd "$(dirname "$0")/.."
SRC=design/app-icon.svg
command -v rsvg-convert >/dev/null || { echo "rsvg-convert not found"; exit 1; }

ios=ios/Runner/Assets.xcassets/AppIcon.appiconset
# size in points x scale = pixels, per the appiconset's Contents.json
for spec in \
  "20 1" "20 2" "20 3" "29 1" "29 2" "29 3" "40 1" "40 2" "40 3" \
  "60 2" "60 3" "76 1" "76 2"; do
  set -- $spec; pt=$1; scale=$2
  px=$(( pt * scale ))
  suffix=$([ "$scale" = 1 ] && echo "@1x" || echo "@${scale}x")
  rsvg-convert -w $px -h $px "$SRC" -o "$ios/Icon-App-${pt}x${pt}${suffix}.png"
done
rsvg-convert -w 167 -h 167 "$SRC" -o "$ios/Icon-App-83.5x83.5@2x.png"
rsvg-convert -w 1024 -h 1024 "$SRC" -o "$ios/Icon-App-1024x1024@1x.png"

# Android launcher densities: mdpi 48dp baseline, scaling by the usual factors.
declare -a and=( "mdpi 48" "hdpi 72" "xhdpi 96" "xxhdpi 144" "xxxhdpi 192" )
for entry in "${and[@]}"; do
  set -- $entry; density=$1; px=$2
  rsvg-convert -w $px -h $px "$SRC" \
    -o "android/app/src/main/res/mipmap-${density}/ic_launcher.png"
done

# The web build's favicon and PWA icons come from the same source.
rsvg-convert -w 512 -h 512 "$SRC" -o web/icons/Icon-512.png
rsvg-convert -w 192 -h 192 "$SRC" -o web/icons/Icon-192.png
rsvg-convert -w 512 -h 512 "$SRC" -o web/icons/Icon-maskable-512.png
rsvg-convert -w 192 -h 192 "$SRC" -o web/icons/Icon-maskable-192.png
rsvg-convert -w 32 -h 32 "$SRC" -o web/favicon.png

echo "Regenerated the application icons."
