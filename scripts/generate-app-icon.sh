#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../" && pwd)"
SOURCE="$ROOT_DIR/assets/AppIcon-1024.png"
ICONSET="$ROOT_DIR/AppIcon.iconset"
ICNS="$ROOT_DIR/ScreenHider/Resources/AppIcon.icns"

if [[ ! -f "$SOURCE" ]]; then
  echo "Error: $SOURCE not found" >&2
  exit 1
fi

rm -rf "$ICONSET"
mkdir -p "$ICONSET" "$(dirname "$ICNS")"

sips_args=(-s format png)
sips "${sips_args[@]}" -z 16 16     "$SOURCE" --out "$ICONSET/icon_16x16.png" >/dev/null
sips "${sips_args[@]}" -z 32 32     "$SOURCE" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips "${sips_args[@]}" -z 32 32     "$SOURCE" --out "$ICONSET/icon_32x32.png" >/dev/null
sips "${sips_args[@]}" -z 64 64     "$SOURCE" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips "${sips_args[@]}" -z 128 128   "$SOURCE" --out "$ICONSET/icon_128x128.png" >/dev/null
sips "${sips_args[@]}" -z 256 256   "$SOURCE" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips "${sips_args[@]}" -z 256 256   "$SOURCE" --out "$ICONSET/icon_256x256.png" >/dev/null
sips "${sips_args[@]}" -z 512 512   "$SOURCE" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips "${sips_args[@]}" -z 512 512   "$SOURCE" --out "$ICONSET/icon_512x512.png" >/dev/null
sips "${sips_args[@]}" -z 1024 1024 "$SOURCE" --out "$ICONSET/icon_512x512@2x.png" >/dev/null

iconutil -c icns "$ICONSET" -o "$ICNS"
rm -rf "$ICONSET"

echo "Generated: $ICNS"
