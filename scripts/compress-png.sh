#!/bin/bash
# PNG を圧縮（pngquant があれば優先、なければ pngcrush / sips）
set -euo pipefail

file="$1"
ROOT_DIR="$(cd "$(dirname "$0")/../" && pwd)"
tmp="${file}.compress.tmp"

if [[ ! -f "$file" ]]; then
  exit 0
fi

if command -v pngquant >/dev/null 2>&1; then
  pngquant --quality=60-85 --speed 1 --force --skip-if-larger --output "$tmp" "$file"
  mv "$tmp" "$file"
  exit 0
fi

if command -v pngcrush >/dev/null 2>&1; then
  pngcrush -rem alla -reduce -brute "$file" "$tmp" >/dev/null
  mv "$tmp" "$file"
  exit 0
fi

# フォールバック: sips で PNG 再エンコード
if sips -s format png "$file" --out "$tmp" >/dev/null 2>&1; then
  mv "$tmp" "$file"
else
  rm -f "$tmp"
fi
