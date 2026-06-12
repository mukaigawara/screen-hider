#!/bin/bash
set -euo pipefail

APP_PATH="${1:?Usage: codesign-app.sh /path/to/App.app}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENTITLEMENTS="$ROOT_DIR/ScreenHider/ScreenHider.entitlements"
IDENTITY="${CODESIGN_IDENTITY:--}"

SIGN_ARGS=(--force --sign "$IDENTITY")

if [[ "$IDENTITY" != "-" ]]; then
  SIGN_ARGS+=(--options runtime --timestamp)
  if [[ -f "$ENTITLEMENTS" ]]; then
    SIGN_ARGS+=(--entitlements "$ENTITLEMENTS")
  fi
fi

codesign "${SIGN_ARGS[@]}" "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "Signed: $APP_PATH (identity: $IDENTITY)"
