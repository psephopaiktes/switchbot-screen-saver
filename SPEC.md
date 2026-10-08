# 仕様: macOSスクリーンセーバー

## 要件と現在の構成

- 黒背景に時計・温度・湿度・日付を表示するSwiftUI + ScreenSaverのネイティブスクリーンセーバー。4項目を独立したトグルで選択する。初期値はすべてオン。既存の認証・機器設定は引き継ぐ。
- 参考画像に合わせ、中央の四角い枠に選んだ時計・温湿度を横並び、日付を画面下部に配置する。SF Symbols、大きなDIN系数値、小さい`°C`／`%`。DIN Condensed／DIN AlternateはOSのフォントを使い、未利用ならシステムフォントへ切り替える。フォントファイルは同梱しない。温湿度のSF Symbolは数値に対して上下中央に配置する。
- 時計は24時間（初期値）または12時間（英語AM／PMを小さく併記）。時計・日付は毎秒更新し、OSのタイムゾーンに従う。日付はOSの地域・カレンダー設定に合わせてyMdの並びと区切りをローカライズし、曜日は英語略称（Mon等）に固定する。スラッシュ区切りの場合は前後にスペースを入れる（例: `2026 / 9 / 15 Tue`）。
- 温度・湿度が両方オフならAPI取得を停止し、認証情報なしで時計・日付を保存できる。全オフは黒画面、日付のみの場合は枠を表示しない。
- 背景は黒。Liquid GlassはOSの時計のような見た目を確認できず、ユーザーの希望に沿って設定・実装を削除。Appleの公開Glass APIが使用不可能と判断したものではない。
- `.saver`単独で設定可能。ScreenSaverViewの`hasConfigureSheet`／`configureSheet`によるオプションにToken・Secret、機器選択、サンプル表示を用意する。「表示」「SwitchBot」の2タブに分ける。
- Token・SecretはSecureFieldで入力し、Keychainの1つのgeneric password項目に保存する。個人の認証情報は配布物、UserDefaults、ログ、リポジトリに含めない。
- `GET /v1.1/devices`で温湿度対応の機器を一覧表示し、`GET /v1.1/devices/{deviceId}/status`で取得を確認してから認証情報と選択を保存する。機器IDの手入力は要求しない。
- 署名はToken + ミリ秒timestamp + nonceのHMAC-SHA256をBase64化。TLS検証を維持し、認証ヘッダーを他ホストへ転送しないようリダイレクトを拒否する。
- APIクライアントとUIを分離し、HTTPステータスとAPI本文のstatusCodeの両方を判定する。サーバー本文や低レベル通信エラーを画面・ログにそのまま出さない。
- 5分ごとに非同期取得する。画面がすべて停止したらキャンセル。同一ホストプロセス内の複数画面で取得を共有する。OSが別プロセスでホストする場合のプロセス間共有は未対応。
- 未取得の値は「—」。通信失敗時には最後の値と更新停止・エラーを表示する。最終取得時刻は内部で保持するが画面には表示しない。サンプル表示は25.9℃・49%で「サンプルデータ」と明示する。現在の実測値として扱わない。
- 非秘密の表示設定と選択機器はScreenSaverDefaultsに保存する。サンプル表示は初期状態でオン。認証情報を削除するとサンプル表示に戻る。
- 設定保存時にrevisionを更新し、秘密情報を含まないプロセス間通知を送る。表示側は通知受信・起動時・フレーム更新時（最大毎秒）に設定を確認し、変更時だけ認証情報を読み直して取得を再開する。
- 設定パネルは同じウィンドウを保持し、終了時に親のシートまたはNSApplicationのモーダル処理を終了する。次の表示で保存設定と認証情報を読み直す。

## ビルド・配布

- Xcodeプロジェクトに`.saver`、プレビューアプリ、XCTestの3ターゲット。
- deployment targetは検証用macOS 13、Swift 5言語モード。製品の最低対応OSは未確定。
- `scripts/package.sh`でReleaseのarm64 / x86_64ビルド、ad-hoc署名検証、別プロセスのBundle読み込み・principal class生成を確認してZIPを作る。ZIPには`.saver`と日本語・英語のインストール案内を同梱する。
- macOS 15、26、27（`xcode-27`イメージ）のCIでパッケージとXCTestを検証する。`vX.Y.Z`タグのpushで既存CIを呼び出し、全環境が成功したらZIPをGitHub Releaseへ添付する。ダウンロード先は固定のReleasesページ。README.mdは英語、README.ja.mdは日本語で初見ユーザー向けの説明に絞る。OGP.pngと一覧サムネイルはユーザー提供のPNGを使用する。
- 無料ダウンロード配布とし、有料Apple Developer Programへの加入・Developer ID署名・公証は行わない。ad-hoc署名の配布物をOSの「このまま開く」で個別に許可する手順をREADMEに記載する。GitHubリポジトリとReleaseをPublicで無料配布する方針。公開設定の変更は連携の管理権限不足（HTTP 403）で未完了。ライセンス・App Store配布は未決定。更新後の許可操作とKeychainアクセスは実機で確認する。
- [インストール](docs/INSTALL.md) / [Macでの検証](docs/MACOS_VALIDATION.md) / [リリース手順](docs/RELEASING.md)。

## 確認済みの進捗

- 2026-09-17: 要件ドキュメントを作成。
- 2026-10-07（引き継ぎ受領日）: ユーザーのローカルでSwitchBot API v1.1認証・機器一覧取得・Hub 2の温湿度取得が成功済み。室温25.9℃・湿度49%は接続確認時の値で、測定日時は未共有。クラウドの実測ではない。
- 2026-10-07: 初期サンプルのソース`4934a3d`について[macOS CI](https://github.com/psephopaiktes/switchbot-screen-saver/actions/runs/37609639481)でXcode 16.4、ReleaseビルドとXCTest 3件が成功。
- 2026-10-08: ユーザーが手元のMacで初期版を確認し、見た目は良いとの報告を受領。詳細なOS・機種、Keychain・API統合やスリープ復帰等の結果は未共有。
- 2026-10-08: ユーザーの希望に合わせて時計を削除し、温湿度デザイン、選択式Liquid Glass、設定・Keychain・API連携、試用ZIP生成と短いREADMEを追加。今回の変更は自動検証と実機確認の結果を分けて記録する。
- 2026-10-08: ユーザー提供のMacビルドログとCIで、設定保存コールバックのMainActor隔離エラーを確認し、コールバックの型を`@MainActor`に修正。
- 2026-10-08: ソース`35c4b2a`の[CI](https://github.com/psephopaiktes/switchbot-screen-saver/actions/runs/37720647396)でmacOS 15 / Xcode 16.4とmacOS 26 / Xcode 26.6の両方が成功。各環境でReleaseのarm64 / x86_64ビルド、署名検証、別プロセスのバンドル読み込み、XCTest 8件（失敗0）、試用ZIPの生成を確認。実測通信と実際のOSホストからのKeychainアクセスは未検証。
- 2026-10-08: ユーザーから「オプションを押しても何も起きない」との報告を受領。設定シートを参照するたびに作成していた処理を、NSWindowControllerで保持する同一のNSPanelに変更。NSHostingControllerと固定サイズを使い、表示後にKeychainを読むよう変更。プレビュー側でウィンドウ接続前に表示要求を消費しないよう修正。0.2.1（build 3）として更新。
- 2026-10-08: ソース`9296227`の[CI](https://github.com/psephopaiktes/switchbot-screen-saver/actions/runs/37721513781)でmacOS 15 / 26のビルド・ZIP生成と各9テスト（失敗0）が成功。同じシートを返すこと、実際のNSWindowへのシート表示・終了・再表示を確認。ユーザーのシステム設定ホストでの症状解消は再確認待ち。
- 2026-10-08: ユーザーから、症状はmacOS 27のシステム設定内のスクリーンセーバー「オプション…」で発生すると確認。画像はリポジトリに保存しない。ホストからの`configureSheet`呼び出しとウィンドウの生成・フォーカスのみを静的メッセージで記録する診断を追加。Token・Secret、機器情報はログに出さない。
- 2026-10-08: 0.2.2（build 4）、ソース`c3a4275`の[CI](https://github.com/psephopaiktes/switchbot-screen-saver/actions/runs/37721972270)でmacOS 15.7.9 / Xcode 16.4、26.6.2 / Xcode 26.6、27.0 / Xcode 27.0の各環境のビルド・ZIP生成・9テスト（失敗0）が成功。OS 27のAppKitシート表示・終了・再表示は確認済み。ただしシステム設定の実際のオプションボタンからの動作は未確認。

- 2026-10-08: ユーザーのmacOS 27でオプションが開き、Token・Secretによる機器一覧取得が成功。機器選択後に「保存」を押して画面が閉じてもサンプルのまま、再度オプションが開かないことがあるとの報告を受領。設定アプリ再起動で開けるが、OSの問題とは未確定。
- 2026-10-08: 0.2.3（build 5）で、別プロセスの設定変更を表示側が読み直す処理と、設定終了時にモーダル処理を終了する処理を追加。希望する見た目になっていないLiquid Glassを削除。設定反映・別プロセス書き込み・モーダル再表示の回帰テストを追加。実測通信の成功は実機再確認待ち。

- 2026-10-08: ソース`90b483e`の[CI](https://github.com/psephopaiktes/switchbot-screen-saver/actions/runs/37724153663)でmacOS 15 / Xcode 16.4、26 / Xcode 26.6、27 / Xcode 27.0のビルド・署名検証・別プロセスのバンドル読み込み・試用ZIP生成、各12テスト（失敗0）が成功。別プロセスの設定変更と通知による表示更新、モーダルの終了・再表示を確認。実際のシステム設定ホストの再オープンと本人の機器の実測表示は再確認待ち。

- 2026-10-08: ユーザーから0.2.3について「いい感じ」との報告を受領。新たに時計・温度・湿度・日付の個別トグル、12／24時間、地域設定に沿う日付と英語の曜日、参考画像に沿ったDIN系デザインを依頼。0.3.0（build 6）として実装し、設定の移行・保存、日付・時刻、温湿度非表示時の通信停止を検証する。

- 2026-10-08: ソース`2de98d3`の[CI](https://github.com/psephopaiktes/switchbot-screen-saver/actions/runs/37741321315)でmacOS 15 / Xcode 16.4、26 / Xcode 26.6、27 / Xcode 27.0のビルド・署名検証・別プロセスのバンドル読み込み・ZIP生成、各17テスト（失敗0）が成功。4項目の設定保存・旧設定の移行、12／24時間、米国・ドイツ・日本の日付、時差による日付・曜日の一致、時計のみの認証不要動作と取得停止を確認。Mac CIのサンプル描画を大きい表示と320×200で確認し、参考画像の字幅に合わせてDIN Alternateを優先。OSホスト内での新しい設定操作・描画は実機確認待ち。

- 2026-10-08: ユーザーが0.3.0のZIPをインストールしたが一覧に出ないと報告。ファイルが保存先に存在し、Appleが検証できないという警告が出たことを確認。Gatekeeperの個別許可で起動できたとの報告を受領。CIの署名整合性・読み込み検証と、ダウンロード後のOSの許可・一覧登録は区別する。
- 2026-10-08: ユーザーは有料Developer Programに加入せず無料配布する方針を決定。READMEと同梱案内に、OSの「このまま開く」による許可と設定アプリ再起動の手順を追加。
- 2026-10-08: デザインの差を調整するため、[Figmaの指定ノード](https://www.figma.com/design/owZ7CvGMLmZ9LSI4ipncN6/Stargate?node-id=11974-1071)の正確な値を使うよう依頼。現在の環境にはFigma連携がなく、URLへの接続もプロキシで403となり、寸法・フォント等は未取得。現行の表示値は参考画像からの調整であり、Figmaの値ではない。指定フレームのSVG等による値の取得後に調整する。

- 2026-10-08: ユーザーの具体的なデザイン指摘に対応し、0.3.1（build 7）でSF Symbolの上下中央揃え、日付のスラッシュ前後の空白、最終取得時刻の非表示を実装。OSの地域ごとの日付順と英語の曜日は維持する。Figmaの寸法等は引き続き未取得で、今回の修正はユーザーの明示した要件に基づく。

- 2026-10-08: 0.3.1、ソース`ff28cc6`の[CI](https://github.com/psephopaiktes/switchbot-screen-saver/actions/runs/37744711757)でmacOS 15 / 26 / 27のビルド・署名検証・バンドル読み込み・ZIP生成と各17テスト（失敗0）が成功。日本・米国のスラッシュ前後の空白と、ドイツの区切りを維持することを確認。macOS 27のネイティブ描画画像でアイコンの上下中央揃え、空白付きの日付、モック通信で取得成功後に最終取得表示がないことを確認。ユーザーのMacでの表示は再確認待ち。

- 2026-10-08: ユーザーの公開準備依頼に基づき、英語READMEと日本語READMEを初見ユーザー向けに整理。固定のReleasesページへ誘導し、SwitchBot公式手順に基づくアプリv9以降のProfile → Preferences → About、バージョン10回タップ、Developer Options → Get Tokenを記載。タグごとのビルド・検証・ReleaseへのZIP添付を整備。リポジトリの公開設定は変更しない。

- 2026-10-08: ソース`63f590c`の[PR CI](https://github.com/psephopaiktes/switchbot-screen-saver/actions/runs/37746341167)でmacOS 15 / 26 / 27の各17テストが成功。`v0.3.1`タグを同じコミットに作成し、[Releaseワークフロー](https://github.com/psephopaiktes/switchbot-screen-saver/actions/runs/37746562876)のバージョン検証・3環境の既存CI呼び出し・ZIP添付・Release公開状態への切り替えがすべて成功。[v0.3.1](https://github.com/psephopaiktes/switchbot-screen-saver/releases/tag/v0.3.1)から実際にZIPをダウンロードし、CRC、バンドルのバージョン、arm64 / x86_64、英語・日本語の案内とToken取得手順を確認。リポジトリはprivateで、一般向けの公開設定は未変更。初回Releaseは検証済みPRブランチのコミットから作成し、mainへのPR統合は未実施。
- 2026-10-08: ユーザーがスクリーンセーバー一覧のサムネイルを用意する意向。PNGの`thumbnail.png`と`thumbnail@2x.png`の同梱方式を調査し、推奨制作サイズ180×116 / 360×232を案内。固定のOS必須サイズとは扱わず、macOS 27の表示は画像受領後に確認する。画像はチャットへのZIP添付またはmainのResources/へ、OGPはリポジトリ直下へ配置する。[画像の受け渡し](docs/ASSETS.md)参照。画像自体は未受領で、ダミー画像は作成しない。

- 2026-10-08: ユーザー提供ZIPのOGP.png（12801×7201）、thumbnail.png（180×116）、thumbnail@2x.png（360×232）を受領。元のPNGを加工せず、OGPを英日READMEの共通画像、サムネイル2枚をスクリーンセーバーのCopy Bundle Resourcesへ登録。COMBINE_HIDPI_IMAGESをNOにしてPNG名を維持。0.3.2（build 8）として準備。LinuxではPNGの整合性・元ファイルとの一致・Xcode登録・Swift構文を検証する。macOS CIのビルド・バンドル画像読み込みと、macOS 27の実際の一覧サムネイル表示は別途確認する。GitHub認証が一時失敗したが接続が復旧。この変更のpush後にmacOS CIで検証し、0.3.2のReleaseを作成する。既存v0.3.1は上書きしない。

- 2026-10-08: 画像追加ソース`af7f5d4`の[CI](https://github.com/psephopaiktes/switchbot-screen-saver/actions/runs/37748071570)でmacOS 15 / 26 / 27のビルド・署名検証・バンドルからのサムネイル2枚のAppKit読み込み・各17テスト（失敗0）が成功。`v0.3.2`タグの[Releaseワークフロー](https://github.com/psephopaiktes/switchbot-screen-saver/actions/runs/37748208346)も成功し、[0.3.2のRelease](https://github.com/psephopaiktes/switchbot-screen-saver/releases/tag/v0.3.2)へZIPを添付。実際のRelease ZIPをダウンロードし、CRC、0.3.2（build 8）、サムネイル2枚が元PNGとバイト単位で一致すること、TIFFへ変換されていないことを確認。OGPはタグ付き英日READMEの参照先に存在。PR #2へ反映済み。macOS 27のシステム設定一覧でのサムネイル表示は実機確認待ち。mainの統合・private設定は変更していない。

- 2026-10-08: ユーザーがPR #2をmainへマージし、1.0のReleaseとPublicへの変更を指示。マージコミット`37987d8`から1.0.0（build 9）へ更新し、ログのバージョンと配布ドキュメントを揃える。新機能の変更はない。macOS CIの成功後にmainのリリースコミットへ`v1.0.0`タグを付け、既存ReleaseワークフローでZIPを配布する。

## 次の確認と未解決事項

1. システム設定を終了し、0.3.1に差し替えて再起動する。保存済みの設定を読み直してサンプルから実測値へ切り替わること、「オプション」を閉じて再度開けることを確認する。OSの不具合と断定しない。
2. 機器一覧取得はmacOS 27のオプションで成功済み。本人の認証情報を再入力させる前に、保存設定とKeychainアクセスを確認する。チャットへ送らせない。
3. プレビューアプリ、設定ホスト、実際のスクリーンセーバーホスト間のKeychainアクセスを検証。実行主体の違いによるアクセス許可は、CIのモックでは確認できない。
4. OSホスト内の描画、起動・停止、スリープ復帰、複数画面、通信失敗・復帰を手動確認。
5. 無料・未公証の配布物のインストール・更新・削除、個別許可のUXを確認。ライセンス・製品の対応OSを決定。
6. 指定Figmaノードの寸法・フォント名／ウェイト・文字サイズ・余白・線幅・色を取得し、実装へ反映。取得前に推測値を正確な値と扱わない。

## 参考資料

- [SwitchBot公式API](https://github.com/OpenWonderLabs/SwitchBotAPI)：署名と機器仕様を今回再確認。
- [Apple Screen Saver](https://developer.apple.com/documentation/screensaver)：設定シートの実装・終了方法を再確認。
- [Apple Liquid Glass](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:))：macOS 26での利用を確認。
- [remo-portal](https://github.com/psephopaiktes/remo-portal)：UX参考。コード再利用時はライセンスを確認。
