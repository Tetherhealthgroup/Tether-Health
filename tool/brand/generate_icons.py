#!/usr/bin/env python3
"""Regenerate every app icon and store graphic from tool/brand/tether_mark.svg.

Usage (from anywhere):
    python3 tool/brand/generate_icons.py          # write all outputs
    python3 tool/brand/generate_icons.py --check  # exit 1 if any output differs

Needs rsvg-convert (librsvg) on PATH and Pillow. Nothing is downloaded and the
app's pubspec.yaml is not involved. The same inputs and tool versions give
byte-identical outputs; the feature graphic's wordmark also depends on the
installed "Helvetica Neue" Bold (the design's header font stack), so check it
by eye if you regenerate on another machine.

Outputs:
  ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png
      every image named in Contents.json, at size x scale pixels: the leaf on
      full-bleed brand teal, opaque (iOS applies its own mask; the 1024
      marketing icon must have no alpha).
  android/app/src/main/res/mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png
      legacy launcher icon (Android 7.1 and older): the round mark, 44 of 48dp.
  android/app/src/main/res/mipmap-anydpi-v26/ic_launcher*.xml
      adaptive icon (Android 8+): teal background, lime leaf foreground inside
      the 66dp safe zone, and a monochrome layer for themed icons (Android 13+).
      Vector drawables, so every density is exact.
  docs/store/play-icon-512.png       Google Play hi-res icon, full bleed.
  docs/store/feature-graphic.png     Google Play feature graphic, 1024 x 500.
"""

import argparse
import io
import json
import math
import os
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MASTER = os.path.join(ROOT, "tool", "brand", "tether_mark.svg")
IOS_SET = os.path.join(ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
ANDROID_RES = os.path.join(ROOT, "android", "app", "src", "main", "res")
STORE = os.path.join(ROOT, "docs", "store")

SVG_NS = "http://www.w3.org/2000/svg"
ANDROID_NS = "http://schemas.android.com/apk/res/android"

# Legacy launcher densities: folder -> 48dp in pixels.
LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}

# Adaptive icon: 108dp canvas, 72dp visible after the launcher's mask, 66dp
# safe zone. The mark's 32-unit circle maps onto the 72dp visible circle, so a
# round mask shows exactly the design's mark; the leaf's farthest point is
# about 27dp from the centre, inside the 33dp safe radius.
ADAPTIVE_CANVAS = 108.0
ADAPTIVE_SCALE = 72.0 / 32.0

# Welcome screen background (render_html.py .scr), used behind the lockup.
FEATURE_BG = ("#FBF8F0", "#F3F0E6")
WORDMARK = "Tether Health"
# Header lockup in the design: 32px mark, 10px gap, 20px weight-800 title.
LOCKUP_SCALE = 5.0


def read_master():
    tree = ET.parse(MASTER)
    disc = leaf = None
    for el in tree.iter():
        if el.get("id") == "disc":
            disc = el
        elif el.get("id") == "leaf":
            leaf = el
    if disc is None or leaf is None:
        sys.exit("tether_mark.svg must contain #disc and #leaf")
    root = tree.getroot()
    if root.get("viewBox") != "0 0 32 32":
        sys.exit("tether_mark.svg must use viewBox 0 0 32 32")
    return {
        "teal": disc.get("fill").upper(),
        "lime": leaf.get("fill").upper(),
        "leaf_d": leaf.get("d"),
        "disc": (float(disc.get("cx")), float(disc.get("cy")), float(disc.get("r"))),
    }


def svg_doc(width, height, view_box, body):
    return (
        f'<svg xmlns="{SVG_NS}" width="{width}" height="{height}" '
        f'viewBox="{view_box}">{body}</svg>'
    )


def leaf_el(m, fill=None):
    return f'<path fill="{fill or m["lime"]}" fill-rule="evenodd" d="{m["leaf_d"]}"/>'


def disc_el(m):
    cx, cy, r = m["disc"]
    return f'<circle cx="{cx:g}" cy="{cy:g}" r="{r:g}" fill="{m["teal"]}"/>'


def rasterize(svg, width, height):
    out = subprocess.run(
        ["rsvg-convert", "-w", str(width), "-h", str(height), "-f", "png"],
        input=svg.encode("utf-8"),
        capture_output=True,
        check=True,
    ).stdout
    img = Image.open(io.BytesIO(out))
    img.load()
    return img.convert("RGBA")


def png_bytes(img):
    buf = io.BytesIO()
    img.save(buf, format="PNG", optimize=True)
    return buf.getvalue()


def full_bleed_icon(m, px):
    """The leaf on a full-bleed teal square, opaque RGB."""
    body = f'<rect width="32" height="32" fill="{m["teal"]}"/>{leaf_el(m)}'
    return rasterize(svg_doc(px, px, "0 0 32 32", body), px, px).convert("RGB")


def round_mark(m, px):
    """The design's round mark, 44/48 of the canvas, transparent outside."""
    inset = 32.0 * 2.0 / 44.0  # 2dp of 48dp padding on each side
    vb = f"{-inset:g} {-inset:g} {32 + 2 * inset:g} {32 + 2 * inset:g}"
    return rasterize(svg_doc(px, px, vb, disc_el(m) + leaf_el(m)), px, px)


def feature_graphic(m):
    w, h = 1024, 500
    s = LOCKUP_SCALE
    mark = 32 * s
    gap = 10 * s
    font = 20 * s
    # Draw the lockup on a wide transparent canvas, measure it, then centre it.
    cw, ch = 2000, int(mark) + 40
    text_x = mark + gap
    body = (
        f'<g transform="translate(0 20) scale({s:g})">{disc_el(m)}{leaf_el(m)}</g>'
        f'<text x="{text_x:g}" y="{20 + mark / 2:g}" dominant-baseline="central" '
        f'font-family="Helvetica Neue, Nimbus Sans, Helvetica, Arial, sans-serif" '
        f'font-weight="800" font-size="{font:g}" fill="{m["teal"]}">{WORDMARK}</text>'
    )
    lockup = rasterize(svg_doc(cw, ch, f"0 0 {cw} {ch}", body), cw, ch)
    box = lockup.getbbox()
    lockup = lockup.crop(box)
    # CSS linear-gradient(160deg, ...): direction (sin 160, -cos 160), with the
    # CSS gradient-line length |w sin a| + |h cos a|.
    a = math.radians(160)
    half = (abs(w * math.sin(a)) + abs(h * math.cos(a))) / 2
    gx, gy = math.sin(a) * half, -math.cos(a) * half
    bg_svg = svg_doc(
        w,
        h,
        f"0 0 {w} {h}",
        '<defs><linearGradient id="g" gradientUnits="userSpaceOnUse" '
        f'x1="{w / 2 - gx:.1f}" y1="{h / 2 - gy:.1f}" x2="{w / 2 + gx:.1f}" y2="{h / 2 + gy:.1f}">'
        f'<stop offset="0" stop-color="{FEATURE_BG[0]}"/>'
        f'<stop offset="1" stop-color="{FEATURE_BG[1]}"/></linearGradient></defs>'
        f'<rect width="{w}" height="{h}" fill="url(#g)"/>',
    )
    bg = rasterize(bg_svg, w, h)
    x = (w - lockup.width) // 2
    y = (h - lockup.height) // 2
    bg.alpha_composite(lockup, (x, y))
    return bg.convert("RGB")


def vector_xml(m, layer):
    """Adaptive icon layer as an Android vector drawable (108dp canvas)."""
    c = ADAPTIVE_CANVAS
    offset = (c - 32 * ADAPTIVE_SCALE) / 2
    if layer == "background":
        inner = f'    <path android:fillColor="{m["teal"]}" android:pathData="M0,0h{c:g}v{c:g}h-{c:g}z" />\n'
    else:
        color = m["lime"] if layer == "foreground" else "#FFFFFFFF"
        inner = (
            f'    <group android:scaleX="{ADAPTIVE_SCALE:g}" android:scaleY="{ADAPTIVE_SCALE:g}"\n'
            f'        android:translateX="{offset:g}" android:translateY="{offset:g}">\n'
            f'        <path android:fillColor="{color}" android:fillType="evenOdd"\n'
            f'            android:pathData="{m["leaf_d"]}" />\n'
            f"    </group>\n"
        )
    return (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<!-- Generated by tool/brand/generate_icons.py from tool/brand/tether_mark.svg. -->\n"
        f'<vector xmlns:android="{ANDROID_NS}"\n'
        f'    android:width="{c:g}dp" android:height="{c:g}dp"\n'
        f'    android:viewportWidth="{c:g}" android:viewportHeight="{c:g}">\n'
        f"{inner}"
        "</vector>\n"
    ).encode("utf-8")


ADAPTIVE_ICON_XML = (
    '<?xml version="1.0" encoding="utf-8"?>\n'
    "<!-- Generated by tool/brand/generate_icons.py from tool/brand/tether_mark.svg. -->\n"
    f'<adaptive-icon xmlns:android="{ANDROID_NS}">\n'
    '    <background android:drawable="@mipmap/ic_launcher_background" />\n'
    '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
    '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />\n'
    "</adaptive-icon>\n"
).encode("utf-8")


def ios_outputs(m):
    with open(os.path.join(IOS_SET, "Contents.json"), encoding="utf-8") as f:
        contents = json.load(f)
    cache = {}
    for image in contents["images"]:
        size = float(image["size"].split("x")[0])
        scale = int(image["scale"].rstrip("x"))
        px = int(round(size * scale))
        if px not in cache:
            cache[px] = png_bytes(full_bleed_icon(m, px))
        yield os.path.join(IOS_SET, image["filename"]), cache[px]


def all_outputs():
    m = read_master()
    for path, data in ios_outputs(m):
        yield path, data
    for folder, px in LEGACY.items():
        yield os.path.join(ANDROID_RES, f"mipmap-{folder}", "ic_launcher.png"), png_bytes(round_mark(m, px))
    anydpi = os.path.join(ANDROID_RES, "mipmap-anydpi-v26")
    yield os.path.join(anydpi, "ic_launcher.xml"), ADAPTIVE_ICON_XML
    for layer in ("background", "foreground", "monochrome"):
        yield os.path.join(anydpi, f"ic_launcher_{layer}.xml"), vector_xml(m, layer)
    play = full_bleed_icon(m, 512).convert("RGBA")  # 32-bit PNG, fully opaque
    yield os.path.join(STORE, "play-icon-512.png"), png_bytes(play)
    yield os.path.join(STORE, "feature-graphic.png"), png_bytes(feature_graphic(m))


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="report outputs that differ; write nothing")
    args = parser.parse_args()
    if not re.search(r"\d", subprocess.run(["rsvg-convert", "--version"], capture_output=True, text=True).stdout):
        sys.exit("rsvg-convert not found")
    stale = []
    for path, data in all_outputs():
        rel = os.path.relpath(path, ROOT)
        old = open(path, "rb").read() if os.path.exists(path) else None
        if old == data:
            continue
        stale.append(rel)
        if not args.check:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "wb") as f:
                f.write(data)
    verb = "differ" if args.check else "written"
    print(f"{len(stale)} file(s) {verb}" + "".join(f"\n  {p}" for p in stale))
    return 1 if (args.check and stale) else 0


if __name__ == "__main__":
    sys.exit(main())
