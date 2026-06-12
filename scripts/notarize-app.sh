#!/bin/bash
set -euo pipefail

APP_PATH="${1:?Usage: notarize-app.sh /path/to/App.app}"

if [[ -z "${NOTARY_KEYCHAIN_PROFILE:-}" ]]; then
  echo "Error: NOTARY_KEYCHAIN_PROFILE is not set" >&2
  exit 1
fi

ZIP_PATH="$(mktemp -t screenhider-notarize.XXXXXX).zip"
trap 'rm -f "$ZIP_PATH"' EXIT

ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo "Submitting for notarization..."
xcrun notarytool submit "$ZIP_PATH" \
  --keychain-profile "$NOTARY_KEYCHAIN_PROFILE" \
  --wait

echo "Stapling notarization ticket..."
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"

echo "Notarized: $APP_PATH"
