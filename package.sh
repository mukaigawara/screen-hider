#!/bin/bash
set -euo pipefail

APP_NAME="ScreenHider"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="$ROOT_DIR/dist"
DMG_STAGING_DIR="$ROOT_DIR/.dmg-staging"
DMG_BACKGROUND="$ROOT_DIR/assets/dmg-background.png"
CREATE_DMG="$ROOT_DIR/scripts/create-dmg/create-dmg"

"$ROOT_DIR/build.sh" --no-open

APP_PATH="$ROOT_DIR/.build/$APP_NAME.app"

if [[ -n "${NOTARY_KEYCHAIN_PROFILE:-}" && "${CODESIGN_IDENTITY:--}" != "-" ]]; then
  chmod +x "$ROOT_DIR/scripts/notarize-app.sh"
  "$ROOT_DIR/scripts/notarize-app.sh" "$APP_PATH"
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" \
  "$ROOT_DIR/.build/$APP_NAME.app/Contents/Info.plist")

rm -rf "$DIST_DIR" "$DMG_STAGING_DIR"
mkdir -p "$DIST_DIR" "$DMG_STAGING_DIR"

swift "$ROOT_DIR/scripts/generate-dmg-background.swift" "$DMG_BACKGROUND"

cp -R "$ROOT_DIR/.build/$APP_NAME.app" "$DMG_STAGING_DIR/"

ZIP_PATH="$DIST_DIR/${APP_NAME}-${VERSION}.zip"
DMG_PATH="$DIST_DIR/${APP_NAME}-${VERSION}.dmg"

ditto -c -k --keepParent "$ROOT_DIR/.build/$APP_NAME.app" "$ZIP_PATH"

CREATE_DMG_ARGS=(
  --volname "$APP_NAME"
  --volicon "$ROOT_DIR/ScreenHider/Resources/AppIcon.icns"
  --background "$DMG_BACKGROUND"
  --window-pos 200 120
  --window-size 660 400
  --icon-size 128
  --text-size 12
  --icon "$APP_NAME.app" 168 185
  --hide-extension "$APP_NAME.app"
  --app-drop-link 492 185
)

if [[ -n "${CODESIGN_IDENTITY:-}" && "${CODESIGN_IDENTITY}" != "-" ]]; then
  CREATE_DMG_ARGS+=(--codesign "$CODESIGN_IDENTITY")
fi
if [[ -n "${NOTARY_KEYCHAIN_PROFILE:-}" ]]; then
  CREATE_DMG_ARGS+=(--notarize "$NOTARY_KEYCHAIN_PROFILE")
fi

chmod +x "$CREATE_DMG"
"$CREATE_DMG" "${CREATE_DMG_ARGS[@]}" "$DMG_PATH" "$DMG_STAGING_DIR"

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

起動後の見え方
--------------
ScreenHider はメニューバー常駐アプリです。
起動してもウィンドウや Dock アイコンは出ません。
画面上部メニューバー右側の太陽/月アイコンを探してください。

初回起動でセキュリティ警告が出た場合
------------------------------------
「Appleは…マルウェアが含まれていないことを検証できませんでした」
「開発元を確認できないため開けません」 など

方法 A（推奨）: ターミナルで quarantine を解除
  xattr -dr com.apple.quarantine /Applications/ScreenHider.app
  その後、Applications から通常どおり起動

方法 B: 右クリックで開く
  1. ScreenHider.app を右クリック（Control+クリック）→「開く」
  2. 表示されたダイアログで「開く」を選択
  ※ 2 回目の「開く」が出ない場合は方法 A を試してください

方法 C: システム設定
  システム設定 → プライバシーとセキュリティ →「このまま開く」

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
