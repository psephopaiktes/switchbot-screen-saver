# Macでの検証

## ビルドと自動テスト

プロジェクトはmacOS 13以降・Swift 5言語モード。Liquid Glassを含むビルドにはXcode 26以降を使います。Xcode 16ではGlass部分をコンパイルせず、通常表示にフォールバックします。

リポジトリのルートで実行します。

```sh
./scripts/package.sh
xcodebuild -project SwitchBotScreenSaver.xcodeproj \
  -scheme SwitchBotSaverPreview -configuration Debug \
  -destination 'platform=macOS' -parallel-testing-enabled NO \
  -derivedDataPath DerivedData test
```

パッケージ作成はReleaseのarm64 / x86_64ビルド、署名検証、別プロセスでのバンドル読み込み・principal class生成を確認し、`build/SwitchBotScreenSaver-macos.zip`を生成します。これはOSの実際のスクリーンセーバーホストの検証とは区別します。

XCTestでは架空の認証情報とモック通信を使い、HMAC署名、対応機器の選択、HTTP／API本文エラー、欠損値、キャンセル、取得の共有・停止、最後の値の保持、接続確認後の設定保存を検証します。実際の認証情報をCIに登録する必要はありません。

LinuxクラウドではSwift構文・Xcode参照・plist・シェル構文を確認します。macOS用CIではビルド・XCTest・パッケージ生成を実行します。CIの成功と、実機の描画・認証・OSホストの動作を区別してください。

## 手動で確認すること

1. `SwitchBotSaverPreview`を実行し、時計がなく、黒背景にSF Symbolsと温湿度、数値より小さい`°C`／`%`が表示されること。
2. 「設定」でミニマル／Liquid Glassを切り替える。GlassはmacOS 26以降で確認する。小さいプレビューやウィンドウサイズ変更でも文字が欠けないこと。
3. [インストール手順](INSTALL.md)に沿ってZIPから`.saver`をインストールする。システム設定内のプレビューと全画面表示の両方を確認する。
4. システム設定の「オプション」でサンプルをオフにし、利用者自身のToken・Secretを入力、機器を取得・選択して保存する。機器一覧と実測値を確認する。認証情報・機器ID・個人の機器名をログやスクリーンショットに残さない。
5. 設定を閉じてから実際のOSホストで実測値を取得できること。Keychainの許可が必要な場合はOSの案内を確認する。プレビューアプリ、設定画面、OSホストの実行主体が異なる場合のアクセスは実機確認が必要。
6. 接続を切って更新を待ち、最後の値・最終取得時刻・更新停止が表示されること。未取得の値を0として表示しないこと。接続復帰後の更新も確認する。
7. 起動・停止、スリープ復帰、複数ディスプレイを確認する。同一プロセス内では取得を共有するが、OSが別プロセスを作る構成での重複取得は未対策。
8. 「認証情報を削除」でサンプルに戻ること。インストールしたバンドルの更新・削除も確認する。

Macの機種・OS・Xcodeバージョン、CIと手動確認の結果をSPEC.mdに記録してください。ユーザーからは初期サンプルの見た目が良いとの確認を受領済みですが、今回のAPI・Keychain・Liquid Glassは別途確認が必要です。

## 一般配布に向けて

CIのZIPは試用用です。一般配布前にDeveloper ID署名・公証・Gatekeeper、更新後のKeychainアクセス、対応OSを検証します。署名用の認証情報はチャットやリポジトリに入れず、安全なビルド設定に登録する必要があります。今回の段階では公開リリースを作成しません。
