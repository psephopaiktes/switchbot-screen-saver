# SwitchBot Screen Saver

黒背景に室温・湿度を表示するmacOSスクリーンセーバー。SF Symbols、大きな数値、小さな単位で見やすく表示します。時計はOS側をご利用ください。

## 使い方

1. [CIの試用ZIP](https://github.com/psephopaiktes/switchbot-screen-saver/actions/runs/37721972270/artifacts/11525613090)をダウンロードして展開（成果物内のZIPも展開）し、`.saver`をダブルクリックしてインストール。
2. システム設定で選択し、「オプション」を開く。
3. サンプル表示をオフにしてToken・Secretを入力 → 機器を取得・選択 → 保存。

認証情報はKeychainに保存。5分ごとに更新します。サンプル表示なら認証情報は不要です。「ミニマル」／「Liquid Glass」（macOS 26以降）を選べます。

現在のZIPは試用用のad-hoc署名です。一般配布向けのDeveloper ID署名・公証は未対応です。[インストールと更新](docs/INSTALL.md)

## 開発

`SwitchBotScreenSaver.xcodeproj`を開き、`SwitchBotSaverPreview`を実行。配布用ZIPはMacで`./scripts/package.sh`を実行して作成します。CIにもビルド済みZIPを保存します。

[Macでの検証](docs/MACOS_VALIDATION.md) · [仕様・進捗](SPEC.md) · [開発指示](AGENTS.md)
