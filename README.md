# switchbot-screen-saver

現在時刻・室温・湿度を表示する、SwiftUI中心のmacOSスクリーンセーバー。

背景と時計のデザインを複数から選べるようにし、将来的な一般配布を目指す。

## 現在の状態

SwiftUIとScreenSaverを組み合わせた最小プロトタイプを追加しました。現在時刻と、固定サンプルの室温25.9℃・湿度49%を表示します。温湿度はHub 2の接続確認時の値であり、現在の実測値ではありません。画面にもサンプルと表示します。

SwitchBot API v1.1の認証・機器一覧取得・Hub 2の温湿度取得はユーザーのローカル環境で成功済みです。このプロトタイプにAPI通信やToken・Secretの入力機能はありません。

- [仕様と次の作業](SPEC.md)
- [開発エージェント向け指示](AGENTS.md)
- [Macでのビルド・検証手順](docs/MACOS_VALIDATION.md)
- 参考: [従来のremo-portal](https://github.com/psephopaiktes/remo-portal)

## 開発方針

Swift / SwiftUIを採用し、macOS標準のスクリーンセーバーとして動くことを重視します。現在の検証用ビルド設定はmacOS 13.0以降・Swift 5言語モードで、Xcode 16以降での確認を想定しています。製品としての最低対応OS・Xcodeバージョン・配布方式は実機検証後に決定します。

## Macで開発を始める

`SwitchBotScreenSaver.xcodeproj`をXcodeで開き、`SwitchBotSaverPreview`スキームを選択して実行します。通常のアプリウィンドウ内で実際の`ScreenSaverView`を確認できます。「時計を更新」で起動・停止、「小さいプレビュー」で設定画面相当のサイズを切り替えます。

`SwitchBotScreenSaver`スキームは`.saver`バンドルを生成します。インストールとOSのスクリーンセーバーホストでの確認は[検証手順](docs/MACOS_VALIDATION.md)を参照してください。

LinuxクラウドではXcodeプロジェクト、plist、スキームの整合性とSwift構文を静的に確認しています。別途[macOS CI（Xcode 16.4）](https://github.com/psephopaiktes/switchbot-screen-saver/actions/runs/37609639481)で`.saver`とプレビューアプリのビルド、XCTest 3件が成功しました。描画の目視確認とOSのスクリーンセーバーホストでの動作は、Macでの手動確認が必要です。
