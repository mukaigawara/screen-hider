#!/bin/bash
set -euo pipefail

APP_NAME="ScreenHider"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="$ROOT_DIR/dist"
DMG_STAGING_DIR="$ROOT_DIR/.dmg-staging"
DMG_BACKGROUND="$ROOT_DIR/assets/dmg-background.png"
CREATE_DMG="$ROOT_DIR/scripts/create-dmg/create-dmg"

"$ROOT_DIR/build.sh" --no-open

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" \
  "$ROOT_DIR/.build/$APP_NAME.app/Contents/Info.plist")

rm -rf "$DIST_DIR" "$DMG_STAGING_DIR"
mkdir -p "$DIST_DIR" "$DMG_STAGING_DIR"

swift "$ROOT_DIR/scripts/generate-dmg-background.swift" "$DMG_BACKGROUND"

cp -R "$ROOT_DIR/.build/$APP_NAME.app" "$DMG_STAGING_DIR/"

ZIP_PATH="$DIST_DIR/${APP_NAME}-${VERSION}.zip"
DMG_PATH="$DIST_DIR/${APP_NAME}-${VERSION}.dmg"

ditto -c -k --keepParent "$ROOT_DIR/.build/$APP_NAME.app" "$ZIP_PATH"

chmod +x "$CREATE_DMG"
"$CREATE_DMG" \
  --volname "$APP_NAME" \
  --volicon "$ROOT_DIR/ScreenHider/Resources/AppIcon.icns" \
  --background "$DMG_BACKGROUND" \
  --window-pos 200 120 \
  --window-size 660 400 \
  --icon-size 128 \
  --text-size 12 \
  --icon "$APP_NAME.app" 168 185 \
  --hide-extension "$APP_NAME.app" \
  --app-drop-link 492 185 \
  "$DMG_PATH" \
  "$DMG_STAGING_DIR"

rm -rf "$DMG_STAGING_DIR"

cat > "$DIST_DIR/INSTALL.txt" <<'EOF'
ScreenHider インストール手順
==========================

【DMG から】
1. ScreenHider-x.x.dmg を開く
2. ScreenHider.app を Applications フォルダへドラッグ
3. Applications から ScreenHider を起動

【ZIP から】
1. ZIP を展開
2. ScreenHider.app を Applications フォルダへ移動
3. Applications から ScreenHider を起動

初回起動で「開発元を確認できない」と出た場合
------------------------------------------
1. 右クリック（または Control+クリック）→「開く」
2. ダイアログで「開く」を選択

または: システム設定 → プライバシーとセキュリティ →「このまま開く」

使い方
------
メニューバー（画面上部）の太陽/月アイコンをクリック。
暗転中の解除: 画面クリック / Esc / ⌘⇧D
EOF

echo ""
echo "Package created:"
echo "  $ZIP_PATH"
echo "  $DMG_PATH"
echo "  $DIST_DIR/INSTALL.txt"
echo ""
echo "配布: dist/ 内の ZIP または DMG を共有してください（GitHub Releases など）。"
