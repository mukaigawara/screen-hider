# ScreenHider

接続中のすべてのディスプレイ（内蔵・外付け）を暗くする、macOS メニューバー常駐アプリです。

## 必要環境

- macOS 13 (Ventura) 以降
- Apple Silicon / Intel 両対応

## インストール

### 1. ダウンロード

[Releases](https://github.com/mukaigawara/screen-hider/releases) から最新版の **ScreenHider-x.x.x.dmg** をダウンロードします。

### 2. アプリを入れる

1. ダウンロードした DMG を開く
2. **ScreenHider.app** を **Applications** フォルダへドラッグ
3. DMG を閉じる

ZIP 版を使う場合は、展開して `ScreenHider.app` を Applications に移動してください。

### 3. 初回起動

1. **Applications** から ScreenHider を起動する
2. メニューバー（画面上部）右側に **太陽のアイコン** が表示されます

> **注意:** ScreenHider はメニューバー常駐アプリです。起動してもウィンドウや Dock アイコンは出ません。メニューバー右側のアイコンを探してください。

初回のみ、macOS のセキュリティ警告が出ることがあります。

**「Appleは…マルウェアが含まれていないことを検証できませんでした」などと表示された場合**

| 方法 | 手順 |
|------|------|
| ターミナル（推奨） | `xattr -dr com.apple.quarantine /Applications/ScreenHider.app` を実行後、通常起動 |
| 右クリックで開く | ScreenHider.app を **右クリック** → **開く** → ダイアログで **開く** |
| システム設定 | **システム設定** → **プライバシーとセキュリティ** → **このまま開く** |

右クリック → 開く で 2 回目の「開く」が出ない場合は、ターミナルでの quarantine 解除を試してください。

2 回目以降は通常どおり起動できます。

## 使い方

メニューバーのアイコンをクリックしてメニューを開きます。

| 項目 | 説明 |
|------|------|
| 画面を暗くする / 明るくする | 暗転の ON / OFF |
| アニメーション | **なし**（即時） / **あり**（フェード） |
| ScreenHiderを終了 | アプリを終了（⌘Q） |

### 暗転中の解除方法

メニューバーは覆われるため、次のいずれかで解除できます。

- 暗い画面を **クリック**
- **Esc** キー
- **⌘⇧D**

画面右上に解除方法のヒントが表示されます。

## 開発者向け

```bash
# ビルドして起動
./build.sh

# 配布用 DMG / ZIP を作成
./package.sh
```

### 配布用コード署名・公証（任意）

Apple Developer Program がある場合、GitHub Actions の Secrets に以下を設定すると Release 時に Developer ID 署名と公証が行われ、利用者側の Gatekeeper 警告を回避できます。

| Secret | 内容 |
|--------|------|
| `MACOS_CERTIFICATE` | Developer ID Application 証明書（.p12 を base64 化） |
| `MACOS_CERTIFICATE_PASSWORD` | .p12 のパスワード |
| `CODESIGN_IDENTITY` | 例: `Developer ID Application: Your Name (TEAMID)` |
| `APPLE_ID` | Apple ID |
| `APPLE_APP_SPECIFIC_PASSWORD` | App 用パスワード |
| `APPLE_TEAM_ID` | Team ID |

Secrets 未設定時は ad-hoc 署名のみ行います（v1.0.4 以前より起動しやすくなりますが、初回は quarantine 解除が必要な場合があります）。

## License

Private / 未設定
