# 仕様: macOSスクリーンセーバー

## 目的・要件

- Macのスクリーンセーバーで現在時刻、室温、湿度を表示。
- SwitchBotの温湿度取得に対応したデバイスを利用者が選択。
- SwiftUIでネイティブUIを構築。既存のremo-portalはUXの参考とし、WebView方式の移植を前提にしない。
- 背景と時計を複数パターンから選択。候補は単色／グラデーション背景とデジタル／アナログ時計。具体的なデザインは未決定。
- 利用者自身のToken・Secretを設定できる設定画面。
- 将来はApp Storeなどで配布したい。ストア配布可能と断定せず、構成と審査条件を確認する。

## 実装方針案

- SwiftUI描画をScreenSaverViewとNSHostingViewで組み込む小さな検証から始める。プレビューと実際のスクリーンセーバーホスト両方で確認する。
- 必要に応じて設定用のmacOSアプリを別ターゲットにする。
- 認証情報はKeychainを基本とする。設定アプリとスクリーンセーバーホスト間でのアクセス可否は先に検証する。
- GET /v1.1/devices で対象を選び、GET /v1.1/devices/{deviceId}/status で表示データを取得する。
- 時計の描画更新とAPI取得を分離。APIポーリングは初期案5分間隔とし、複数画面での重複取得を避ける。
- 通信失敗時も時計を表示し、温湿度には最終取得時刻／更新停止を表示。未取得値を0として扱わない。
- 終了・スリープ時にポーリングを停止。ネットワーク処理で描画を止めない。

## 次の作業・受け入れ確認

1. API設定と実機の温湿度取得可否を確認（ユーザーのローカルで成功済み）。
2. ScreenSaver + SwiftUIの最小表示、プレビュー、起動／停止を実機検証（サンプル表示の実装を追加。Macでの検証は未実施）。
3. 認証情報の保存・ホストからの利用を検証。
4. 時計と温湿度、エラー表示、設定画面を実装。
5. 複数テーマ、複数ディスプレイ、スリープ復帰を確認。
6. 署名・公証・インストール・アップデート方法とストア配布可否を調査。

最低OS、対象機種、初期テーマ、配布方式は未決定。

## 最小プロトタイプの構成

- `SwitchBotScreenSaver.xcodeproj`に`.saver`バンドル、プレビューアプリ、XCTestの3ターゲットを用意。
- `SwitchBotScreenSaverView`をObjective-Cのクラス名として公開し、Info.plistの`NSPrincipalClass`から読み込む。`NSHostingView`内のSwiftUIで時計と温湿度を描画する。
- サンプル値は`RoomReading.sample`に分離。25.9℃・49%を固定表示し、「サンプルデータ · Hub 2接続確認時の値」と明示する。現在の実測値や取得日時として扱わない。
- 時計はOSホストの`animateOneFrame()`で毎秒現在時刻を更新し、開始時も更新する。停止中のコールバックは無視する。スクリーンセーバー自身に独自タイマーやAPIポーリングは追加しない。
- プレビューアプリは実際の`ScreenSaverView`を埋め込み、プレビュー側のタイマーでOSホストのフレーム通知を再現する。停止・ビュー破棄時にタイマーを解除する。
- 起動・停止・リサイズ・小さいプレビューの確認手順は[Macでの検証手順](docs/MACOS_VALIDATION.md)に記載。プレビューアプリでの成功だけではOSホストでの成功としない。
- 検証用にmacOS 13.0をdeployment target、Swift 5を言語モードとした。Xcode 16以降での確認を想定するが、製品の対応要件を確定したものではない。
- ローカル検証用のad-hoc署名設定。Developer ID署名・公証・ストア配布の検証は未実施。

## APIと設定の前提

- SwitchBot Open API v1.1。認証にはOpen TokenとSecretの両方が必要。
- 利用者が認証情報を入力した後、デバイス一覧から対象を選択する。デバイスIDの手入力を通常フローにしない。
- 初回は読み取りで接続を確認し、機種・Hub・クラウド連携の必要条件を実機で確認する。
- 設定案内はユーザーの進捗に合わせて1ステップずつ行う。認証情報はチャットに送らせない。
- 公式資料に個人利用の範囲と商用・大規模利用時の相談条件がある。一般配布・収益化前に適用条件を確認する。

## 引き継ぎ状況

- 2026-09-17: 要件ドキュメントを作成。アプリ実装・認証情報取得・実機接続確認は未着手。
- 2026-10-07（引き継ぎ受領日）: ユーザーのローカルでSwitchBot API v1.1の認証と機器一覧取得が成功済み。Hub 2から室温25.9℃・湿度49%を取得できた。これは接続確認時の値で、測定日時は未共有。クラウドから再取得した結果ではない。
- 2026-10-07: サンプル表示のSwiftUI + ScreenSaver、プレビューアプリ、Xcode構成、macOS用CI、XCTestを追加。LinuxクラウドではSwift構文・プロジェクト構造・plist・スキームの静的検証を実施。
- 2026-10-07: [macOS CI](https://github.com/psephopaiktes/switchbot-screen-saver/actions/runs/37609639481)でソースコミット`4934a3d`を検証。Xcode 16.4（16F6）・macOS 15.5 SDKで`.saver`のReleaseビルド（arm64 / x86_64）とプレビューアプリのDebugビルドが成功。XCTest 3件、失敗0件。描画の目視確認、OSホストでの読み込み、macOS 13実機での互換性は未検証。
- 次の作業はMacでのアプリ内プレビューの目視確認とOSホストの確認。必要に応じてローカルのビルド・XCTestも実行し、環境と結果を記録してからKeychainとAPIクライアントの統合へ進む。Token・Secretをこのタスクで入力する必要はない。
- ユーザーはMac版とAndroid版を別々のタスクで開発する予定。

## 参考資料

- [SwitchBot公式API](https://github.com/OpenWonderLabs/SwitchBotAPI)
- [Apple Screen Saver](https://developer.apple.com/documentation/screensaver)
- [remo-portal](https://github.com/psephopaiktes/remo-portal): READMEでWebView方式を確認。コード再利用時はライセンスを確認。
