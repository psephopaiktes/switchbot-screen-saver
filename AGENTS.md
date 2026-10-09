# 開発エージェント向け指示

## 作業の進め方

- 最初にこのファイルとREADME.mdを読む。今後も必要な決定事項・検証結果・未解決事項はこのファイルを更新して引き継ぐ。過去の作業履歴はGit・PR・CI・Releaseで確認する。
- 回答・開発ドキュメントは原則日本語。利用者向けREADME.mdは英語、README.ja.mdは日本語。両方の冒頭はタイトル、言語リンク、OGP.png参照を揃え、短い利用手順を中心に保つ。
- PRはタイトルに[Codex]を付け、本文にもCodexが実装・検証して作成した旨を明記する。
- API仕様とOS仕様は実装時に[SwitchBot公式API](https://github.com/OpenWonderLabs/SwitchBotAPI)・[Apple ScreenSaver](https://developer.apple.com/documentation/screensaver)等の公式資料で再確認し、仮定と実機確認済みの事項を区別する。
- Token、Secret、個人のデバイスIDをコード、ログ、スクリーンショット、コミットに含めない。認証情報をクラウドやチャットへ入力させない。アプリは利用者自身のToken・Secretで動かし、開発者の認証情報を配布しない。
- ユーザーへのAPI設定の案内は1ステップずつ、完了を確認してから次へ進む。ローカルで成功済みのAPI設定を最初からやり直させない。

## 表示と設定の仕様

- SwiftUI + ScreenSaverのネイティブ`.saver`。黒背景で、中央の四角い枠に時計・温湿度を横並び、日付を画面下部に表示する。
- 時計・温度・湿度・日付は独立したトグルで選択し、初期値はすべてオン。全オフは黒画面、日付のみの場合は枠を表示しない。既存の表示・認証・機器設定は更新後も引き継ぐ。
- DIN Alternate／DIN CondensedはOSのフォントを使い、未利用ならシステムフォントへ切り替える。フォントファイルは同梱しない。温湿度はSF Symbols、大きい数値、小さい`°C`／`%`で表示し、アイコンは数値の上下中央に揃える。
- 時計は24時間が初期値で、12時間では小さい英語AM／PMを併記する。時計・日付は毎秒更新し、OSのタイムゾーンに従う。日付はOSの地域・カレンダー設定に沿うyMdの並びと区切り、曜日は英語略称。スラッシュ前後に空白を入れる（例: `2026 / 9 / 15 Tue`）。
- 最終取得時刻は内部で保持し、画面に表示しない。Liquid Glassはユーザーの希望に沿って削除済みで、Appleの公開Glass APIが使用不可能と判断したものではない。
- `.saver`単独で`hasConfigureSheet`／`configureSheet`によるオプションを開ける。「表示」「SwitchBot」の2タブで表示項目と認証・機器・サンプルを設定する。
- Token・SecretはSecureFieldで入力し、Keychainの1つのgeneric password項目に保存する。非秘密の表示設定と選択機器だけをScreenSaverDefaultsへ保存する。
- 設定保存時にrevisionを更新し、秘密情報を含まないプロセス間通知を送る。表示側は通知・起動時・フレーム更新時（最大毎秒）に設定を確認し、変更時だけ認証情報を読み直して取得を再開する。
- 設定パネルは同じウィンドウを保持し、終了時に親のシートまたはNSApplicationのモーダル処理を終了する。次の表示で保存設定と認証情報を読み直す。保存してもサンプルのまま／再度オプションが開かない症状の回帰を防ぐ。
- OGPとサムネイルはユーザー提供のPNGを加工・再生成せず使う。`Resources/thumbnail.png`と`Resources/thumbnail@2x.png`をCopy Bundle Resourcesで同梱し、スクリーンセーバーのCOMBINE_HIDPI_IMAGESはNOにしてPNG名を維持する。[画像の扱い](docs/ASSETS.md)参照。

## SwitchBot連携

- APIクライアントとUIを分離し、モックでUIを開発可能にする。
- API v1.1の`GET /v1.1/devices`で温湿度対応機器を一覧表示し、`GET /v1.1/devices/{deviceId}/status`の取得を確認してから認証情報と選択を保存する。機器IDの手入力は要求しない。
- Token + ミリ秒timestamp + nonceのHMAC-SHA256をBase64化して署名する。TLS検証を維持し、認証ヘッダーを他ホストへ転送しないようリダイレクトを拒否する。
- HTTPステータスとAPI本文のstatusCodeの両方を判定する。サーバー本文や低レベル通信エラーを画面・ログにそのまま出さない。
- 5分ごとに非同期取得し、画面がすべて停止したらキャンセルする。同一ホストプロセス内の複数画面で取得を共有する。別プロセスのホスト間の取得共有は未対応。
- 温度・湿度が両方オフならAPI取得を停止し、時計・日付のみなら認証情報なしで保存できる。
- 未取得は「—」。通信失敗時は最後の値と更新停止・エラーを表示する。サンプルは25.9℃・49%で「サンプルデータ」と明示し、現在の実測値として扱わない。サンプルは初期状態でオン、認証情報を削除するとサンプルへ戻る。

## ビルド・配布・検証

- Xcodeプロジェクトには`.saver`、プレビューアプリ、XCTestの3ターゲットがある。deployment targetは検証用macOS 13、Swift 5言語モード。製品の最低対応OSは未確定。
- `scripts/package.sh`でReleaseのarm64／x86_64ビルド、ad-hoc署名検証、別プロセスのBundle読み込み・principal class生成・サムネイル読み込みを確認してHomebrew用のtar.gzを作る。アーカイブには`.saver`だけを入れ、ZIP・同梱案内は生成しない。
- `.github/workflows/macos.yml`はPR／mainのビルド・XCTest・Homebrewのインストール／削除・アーカイブ生成をmacOS 15／26／27（`xcode-27`）で検証する。`release.yml`は`vX.Y.Z`タグとバンドルのバージョン一致を確認し、同じCIが全環境で成功したらtar.gzをGitHub Releaseへ添付し、SHA-256固定のCaskをmainへ更新する。公開済みの同じタグのアセットは上書きしない。
- READMEはHomebrewでのインストール・更新・削除を案内する。Tapは同じリポジトリのCasks/で管理し、初回brew tapではリポジトリURLを指定する。リポジトリはPublic（2026-10-09確認済み）で無料配布する。ライセンス・App Store配布は未決定。
- 有料Apple Developer Programへの加入・Developer ID署名・公証は行わない方針。GatekeeperはOSの「このまま開く」で個別に許可し、全体のセキュリティを無効化しない。Developer ID署名・公証済みと断定しない。
- 必要な検証は署名、レスポンス処理、主要操作など挙動を保証するものに絞る。Linuxでの構文・参照確認、macOS CIの自動検証、実機でのAPI・Keychain・OSホスト検証を区別する。[Macでの検証](docs/MACOS_VALIDATION.md)・[リリース手順](docs/RELEASING.md)参照。
- 最新の確認済みReleaseは[v1.0.0](https://github.com/psephopaiktes/switchbot-screen-saver/releases/tag/v1.0.0)（build 9）。[PR CI](https://github.com/psephopaiktes/switchbot-screen-saver/actions/runs/37763919776)で3環境のビルド・バンドル／画像読み込み・各17テストが成功し、[Releaseワークフロー](https://github.com/psephopaiktes/switchbot-screen-saver/actions/runs/37764098429)も成功。実際の配布ZIPのCRC・バージョン・arm64／x86_64・元のサムネイル2枚・英日案内を確認済み。

- 2026-10-09: ユーザーの希望によりHomebrew前提の配布へ変更。英日READMEをHomebrewとBrewfileの案内へ更新し、同梱案内2ファイルを削除。Homebrew用の1.0.1（build 10）を準備。新しいReleaseはCI成功後にtar.gzを添付し、同じリポジトリのCaskを更新する。Homebrewのインストール／削除と、OSのGatekeeper・Keychain許可は区別する。

## 実機での確認済み事項と残る課題

- ユーザーのローカルでAPI v1.1認証・機器一覧・Hub 2の温湿度取得が成功済み。25.9℃・49%は接続確認時の値で、測定日時は未共有。macOS 27のオプション表示・機器一覧取得・Gatekeeperの個別許可による起動も確認済み。
- 更新後のOSホスト内の実測表示・オプション再オープン・サムネイル表示、プレビュー／設定／スクリーンセーバーホスト間のKeychainアクセスは実機で確認する。CIのモックやAppKitの成功だけでOSホストでの動作を断定しない。認証情報の再入力を求める前に保存設定とKeychainを確認し、OSの不具合と断定しない。
- 起動・停止、スリープ復帰、複数画面、通信失敗・復帰、インストール・更新・削除と更新後の許可操作を実機で確認する。
- [Figmaの指定ノード](https://www.figma.com/design/owZ7CvGMLmZ9LSI4ipncN6/Stargate?node-id=11974-1071)の正確な寸法・フォント・余白・線幅・色は未取得。現行デザインは参考画像とユーザーの具体的な指示に基づく。調整時はFigmaか書き出しデータで値を確認し、画像からの推測値を取得済みと扱わない。
