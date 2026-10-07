# Macでのビルド・検証

## 前提と検証範囲

MacとXcode 16以降を想定した検証用構成です。XcodeのCommand Line Toolsを使用できる状態にしてください。検証用deployment targetはmacOS 13.0ですが、製品の最低OSや実機互換性は未確定です。外部パッケージ、SwitchBotのToken・Secret、個人のデバイスIDは不要です。

Linuxクラウドで確認したのはSwiftの構文と、Xcodeプロジェクトの参照・ターゲット構成、plistと共有スキームの整合性です。macOS SDKによる型チェックやリンク、XCTest、描画、OSホストによる読み込みの代わりにはなりません。

macOS用GitHub Actionsには以下のビルドとXCTestを登録しています。[2026-10-07のCI](https://github.com/psephopaiktes/switchbot-screen-saver/actions/runs/37609639481)で、ソースコミット`4934a3d`の`.saver`のReleaseビルドとプレビューアプリのDebugビルド、XCTest 3件（失敗0件）が成功しました。使用環境はXcode 16.4（16F6）・macOS 15.5 SDKで、Releaseはarm64 / x86_64をビルドしています。macOS 13の実機互換性は確認していません。

CIの成功も、システム設定内のプレビューや実際のスクリーンセーバーの動作確認の代わりにはなりません。

## ビルドとXCTest

リポジトリのルートで実行します。

```sh
xcodebuild -version
xcodebuild -project SwitchBotScreenSaver.xcodeproj \
  -scheme SwitchBotScreenSaver -configuration Release \
  -derivedDataPath DerivedData build

xcodebuild -project SwitchBotScreenSaver.xcodeproj \
  -scheme SwitchBotSaverPreview -configuration Debug \
  -destination 'platform=macOS' -parallel-testing-enabled NO \
  -derivedDataPath DerivedData test
```

`SwitchBotScreenSaver.saver`は`DerivedData/Build/Products/Release/`に生成されます。ReleaseはApple SiliconとIntel向けの標準アーキテクチャ、Debugは実行するMacのアーキテクチャを対象にします。署名はローカル検証用のad-hoc署名です。

XCTestは次の3テストを実行します。実行件数と失敗の有無を確認してください。

- 接続確認時のサンプル温湿度。
- 指定した時刻への時計モデルの更新。
- 通常表示とプレビューモードのホスト生成、開始、フレーム更新、停止後の更新抑止、再開、リサイズ。

## アプリ内プレビュー

Xcodeで`SwitchBotSaverPreview`スキームを実行します。確認対象は、通常アプリ内に埋め込んだ実際の`ScreenSaverView`です。

1. 時計が現在時刻を表示し、秒が進むこと。
2. 室温25.9℃・湿度49%と「サンプルデータ」の表示があること。
3. 「時計を更新」をオフにして数秒待ち、時計が止まること。オンに戻すと現在時刻に追いついて更新が再開すること。
4. ウィンドウをリサイズして背景が追従し、文字が欠けないこと。
5. 「小さいプレビュー」をオンにして320×200の表示を確認すること。切り替えを繰り返して時計が正常に動くこと。
6. ウィンドウを閉じ、再度開いて起動・停止に問題がないこと。

## OSのスクリーンセーバーホスト

ビルドしたバンドルをFinderで開き、インストール先の選択はOSの案内に従います。同名の既存バンドルがある場合は内容を確認してから置き換えてください。

```sh
open DerivedData/Build/Products/Release/SwitchBotScreenSaver.saver
```

1. システム設定のスクリーンセーバーで「SwitchBot Screen Saver」が選択できること。
2. 設定画面のプレビューに時計・温湿度・サンプル表示が描画されること。
3. OSのプレビュー／スクリーンセーバー開始操作で全画面表示し、秒が進むこと。
4. 終了して再開したとき、表示が現在時刻に更新されること。
5. スリープ復帰後の再開、複数ディスプレイでの表示を確認すること。これらのOS固有の挙動はアプリ内テストだけでは保証できません。

読み込み失敗時はXcodeのビルドログとConsoleでスクリーンセーバーホストのエラーを確認します。OSのセキュリティ設定を無効化して動作を成立させないでください。Developer ID署名・公証・一般配布の手順は別途検討します。

## 検証結果の記録

確認後、SPEC.mdの引き継ぎにMacの機種・OS・Xcodeバージョン、ビルド結果、XCTest件数、アプリ内プレビューとOSホストそれぞれの結果を追記してください。未実行・失敗・成功を区別し、未確認の挙動を確認済みと記載しないでください。現在は描画とOSホストについてMacでの手動確認待ちです。
