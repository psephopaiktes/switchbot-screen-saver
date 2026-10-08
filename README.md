# SwitchBot Screen Saver

黒背景に時計・温度・湿度・日付を表示するmacOSスクリーンセーバー。DIN系フォントとSF Symbolsを使った横並びのデザインです。

## 使い方

1. [CIの試用ZIP](https://github.com/psephopaiktes/switchbot-screen-saver/actions/runs/37741321315/artifacts/11533723905)をダウンロードして展開（成果物内のZIPも展開）し、`.saver`をダブルクリックしてインストール。
2. システム設定で選択し、「オプション」を開く。
3. サンプル表示をオフにしてToken・Secretを入力 → 機器を取得・選択 →「保存して表示に反映」。

「表示」タブで4項目を個別にオン／オフ。時計は12／24時間、日付はMacの地域設定に合わせ、曜日は英語の略称で表示します。

認証情報はKeychainに保存。5分ごとに更新します。サンプル表示なら認証情報は不要です。

現在のZIPは試用用のad-hoc署名です。一般配布向けのDeveloper ID署名・公証は未対応です。[インストールと更新](docs/INSTALL.md)

## 開発

`SwitchBotScreenSaver.xcodeproj`を開き、`SwitchBotSaverPreview`を実行。配布用ZIPはMacで`./scripts/package.sh`を実行して作成します。CIにもビルド済みZIPを保存します。

[Macでの検証](docs/MACOS_VALIDATION.md) · [仕様・進捗](SPEC.md) · [開発指示](AGENTS.md)
