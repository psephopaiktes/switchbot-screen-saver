# switchbot-screen-saver

現在時刻・室温・湿度を表示する、SwiftUI中心のmacOSスクリーンセーバー。

背景と時計のデザインを複数から選べるようにし、将来的な一般配布を目指す。

## 現在の状態

企画段階。ドキュメントのみで、起動・ビルドできるアプリはまだありません。

- [仕様と次の作業](SPEC.md)
- [開発エージェント向け指示](AGENTS.md)
- 参考: [従来のremo-portal](https://github.com/psephopaiktes/remo-portal)

## 開発方針

Swift / SwiftUIを採用予定。macOS標準のスクリーンセーバーとして動くことを重視し、ScreenSaverフレームワークとの統合を先に検証します。最低対応OS、Xcodeバージョン、配布方式はその結果から決定します。
