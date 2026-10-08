# SwitchBot Screen Saver

[English](README.md) | [日本語](README.ja.md)

![OGP](OGP.png)

時計・日付・SwitchBot機器の温度と湿度を表示する、無料のmacOSスクリーンセーバーです。

## ダウンロード・インストール

1. [Releases](https://github.com/psephopaiktes/switchbot-screen-saver/releases)から **SwitchBotScreenSaver-macos.zip** をダウンロードして展開し、**SwitchBotScreenSaver.saver** をダブルクリック。「このユーザのみ」にインストールします。
2. Macのスクリーンセーバー設定で **SwitchBot Screen Saver** を選択します。Appleが検証できないという警告が出た場合は「完了」で閉じ、**システム設定 → プライバシーとセキュリティ**で、このスクリーンセーバーの **「このまま開く」** を押してOSの確認に従います。
3. システム設定を **⌘Q** で終了して開き直し、スクリーンセーバーを選択 → **「オプション」** を開きます。

Appleの公証は行っていないため、更新時にも許可が必要になる場合があります。macOSのセキュリティ機能全体を無効にする必要はありません。

## SwitchBotとの接続

最新版のSwitchBotスマホアプリで **Open Token** と **Secret** を取得します。

1. ログインし、**プロフィール（Profile）→ 設定（Preferences）→ About（アプリ情報）** を開きます。
2. **アプリのバージョン（App Version）を10回タップ**して、**開発者向けオプション（Developer Options）** を表示します。
3. **Developer Options → Get Token** を開き、**Token** と **Secret** の両方をコピーします。

スクリーンセーバーの **「オプション」→「SwitchBot」** で「サンプルデータで表示」をオフにし、**Open Token** と **Secret** を入力。「接続して機器を取得」→ 機器を選択 → **「保存して表示に反映」** を押します。SwitchBotのクラウドAPIで温湿度を取得できる機器が必要です。

認証情報はMacのKeychainに保存されます。他の人と共有しないでください。温湿度は5分ごとに更新します。サンプル表示や時計・日付のみの表示には認証情報は不要です。

画面名はアプリのバージョンにより異なる場合があります。[SwitchBot公式の取得手順](https://github.com/OpenWonderLabs/SwitchBotAPI#getting-started)

## 表示の設定

**「オプション」→「表示」** で時計・温度・湿度・日付を個別にオン／オフでき、時計は12／24時間表示を選べます。日付はMacの地域設定に合わせ、曜日は英語の略称で表示します。

更新時はシステム設定とスクリーンセーバーを終了し、新しい`.saver`で置き換えてください。保存済みの設定は引き継ぎます。
