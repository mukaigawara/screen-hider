#!/bin/bash
set -euo pipefail

APP_NAME="ScreenHider"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT_DIR/.build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"
AUTO_OPEN=true

for arg in "$@"; do
  case "$arg" in
    --no-open) AUTO_OPEN=false ;;
  esac
done

stop_app() {
  if pgrep -x "$APP_NAME" > /dev/null 2>&1; then
    echo "Stopping running $APP_NAME..."
    pkill -x "$APP_NAME" || true
    for _ in {1..25}; do
      if ! pgrep -x "$APP_NAME" > /dev/null 2>&1; then
        return 0
      fi
      sleep 0.1
    done
    echo "Warning: $APP_NAME did not exit cleanly."
    pkill -9 -x "$APP_NAME" 2>/dev/null || true
  fi
}

# 起動中のプロセスが古いバイナリを掴んでいると差し替えできない
stop_app

chmod +x "$ROOT_DIR/scripts/generate-app-icon.sh"
"$ROOT_DIR/scripts/generate-app-icon.sh"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

SWIFT_SOURCES=(
  "$ROOT_DIR/ScreenHider/ScreenHiderApp.swift"
  "$ROOT_DIR/ScreenHider/AppDelegate.swift"
  "$ROOT_DIR/ScreenHider/OverlayManager.swift"
  "$ROOT_DIR/ScreenHider/OverlayWindow.swift"
  "$ROOT_DIR/ScreenHider/HotKeyManager.swift"
  "$ROOT_DIR/ScreenHider/HintView.swift"
)

SWIFT_FLAGS=(
  -framework AppKit
  -framework SwiftUI
  -framework Combine
  -framework Carbon
  -framework QuartzCore
  -parse-as-library
)

if [ "${BUILD_UNIVERSAL:-}" = "1" ]; then
  swiftc "${SWIFT_SOURCES[@]}" \
    -o "$MACOS_DIR/${APP_NAME}_arm64" \
    "${SWIFT_FLAGS[@]}" \
    -target arm64-apple-macos13.0
  swiftc "${SWIFT_SOURCES[@]}" \
    -o "$MACOS_DIR/${APP_NAME}_x86_64" \
    "${SWIFT_FLAGS[@]}" \
    -target x86_64-apple-macos13.0
  lipo -create \
    "$MACOS_DIR/${APP_NAME}_arm64" \
    "$MACOS_DIR/${APP_NAME}_x86_64" \
    -output "$MACOS_DIR/$APP_NAME"
  rm -f "$MACOS_DIR/${APP_NAME}_arm64" "$MACOS_DIR/${APP_NAME}_x86_64"
else
  swiftc "${SWIFT_SOURCES[@]}" \
    -o "$MACOS_DIR/$APP_NAME" \
    "${SWIFT_FLAGS[@]}" \
    -target "$(uname -m)-apple-macos13.0"
fi

cp "$ROOT_DIR/ScreenHider/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ROOT_DIR/ScreenHider/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

echo "Built: $APP_DIR"

if [ "$AUTO_OPEN" = true ]; then
  echo "Launching: $APP_DIR"
  open "$APP_DIR"
fi
