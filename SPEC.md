# 仕様: macOSスクリーンセーバー

## 要件と現在の構成

- 黒背景に室温・湿度を表示するSwiftUI + ScreenSaverのネイティブスクリーンセーバー。アプリ独自の時計は表示せず、OSの時計を利用する。
- SF Symbolsの温度計・湿度アイコン、余白を持ったカード、大きな数値、小さい`°C`／`%`を使う。
- スタイルは設定から「ミニマル」「Liquid Glass」を選択。Liquid GlassはmacOS 26・Xcode 26以降、旧SDK／OSでは通常表示にフォールバックする。背景は黒で固定。
- `.saver`単独で設定可能。ScreenSaverViewの`hasConfigureSheet`／`configureSheet`によるオプションにToken・Secret、機器選択、スタイル、サンプル表示を用意する。
- Token・SecretはSecureFieldで入力し、Keychainの1つのgeneric password項目に保存する。個人の認証情報は配布物、UserDefaults、ログ、リポジトリに含めない。
- `GET /v1.1/devices`で温湿度対応の機器を一覧表示し、`GET /v1.1/devices/{deviceId}/status`で取得を確認してから認証情報と選択を保存する。機器IDの手入力は要求しない。
- 署名はToken + ミリ秒timestamp + nonceのHMAC-SHA256をBase64化。TLS検証を維持し、認証ヘッダーを他ホストへ転送しないようリダイレクトを拒否する。
- APIクライアントとUIを分離し、HTTPステータスとAPI本文のstatusCodeの両方を判定する。サーバー本文や低レベル通信エラーを画面・ログにそのまま出さない。
- 5分ごとに非同期取得する。画面がすべて停止したらキャンセル。同一ホストプロセス内の複数画面で取得を共有する。OSが別プロセスでホストする場合のプロセス間共有は未対応。
- 未取得の値は「—」。通信失敗時には最後の値、最終取得時刻、更新停止を表示する。サンプル表示は25.9℃・49%で「サンプルデータ」と明示する。現在の実測値として扱わない。
- 非秘密の表示設定と選択機器はScreenSaverDefaultsに保存する。サンプル表示は初期状態でオン。認証情報を削除するとサンプル表示に戻る。

## ビルド・配布

- Xcodeプロジェクトに`.saver`、プレビューアプリ、XCTestの3ターゲット。
- deployment targetは検証用macOS 13、Swift 5言語モード。製品の最低対応OSは未確定。
- `scripts/package.sh`でReleaseのarm64 / x86_64ビルド、ad-hoc署名検証、別プロセスのBundle読み込み・principal class生成を確認してZIPを作る。ZIPには`.saver`と短いインストール案内を同梱する。
- macOS 15と26のCIでパッケージとXCTestを検証し、ZIPを成果物として保存する。一般公開リリースはまだ作成しない。
- 最終的な一般配布にはDeveloper ID署名・公証・Gatekeeper、アップデート後のKeychainアクセスの検証が必要。署名用資格情報は未提供。公開範囲・ライセンス・課金・App Store配布は未決定。
- [インストール](docs/INSTALL.md) / [Macでの検証](docs/MACOS_VALIDATION.md)。

## 確認済みの進捗

- 2026-09-17: 要件ドキュメントを作成。
- 2026-10-07（引き継ぎ受領日）: ユーザーのローカルでSwitchBot API v1.1認証・機器一覧取得・Hub 2の温湿度取得が成功済み。室温25.9℃・湿度49%は接続確認時の値で、測定日時は未共有。クラウドの実測ではない。
- 2026-10-07: 初期サンプルのソース`4934a3d`について[macOS CI](https://github.com/psephopaiktes/switchbot-screen-saver/actions/runs/37609639481)でXcode 16.4、ReleaseビルドとXCTest 3件が成功。
- 2026-10-08: ユーザーが手元のMacで初期版を確認し、見た目は良いとの報告を受領。詳細なOS・機種、Keychain・API統合やスリープ復帰等の結果は未共有。
- 2026-10-08: ユーザーの希望に合わせて時計を削除し、温湿度デザイン、選択式Liquid Glass、設定・Keychain・API連携、試用ZIP生成と短いREADMEを追加。今回の変更は自動検証と実機確認の結果を分けて記録する。
- 2026-10-08: ユーザー提供のMacビルドログとCIで、設定保存コールバックのMainActor隔離エラーを確認し、コールバックの型を`@MainActor`に修正。
- 2026-10-08: ソース`35c4b2a`の[CI](https://github.com/psephopaiktes/switchbot-screen-saver/actions/runs/37720647396)でmacOS 15 / Xcode 16.4とmacOS 26 / Xcode 26.6の両方が成功。各環境でReleaseのarm64 / x86_64ビルド、署名検証、別プロセスのバンドル読み込み、XCTest 8件（失敗0）、試用ZIPの生成を確認。実測通信と実際のOSホストからのKeychainアクセスは未検証。

## 次の確認と未解決事項

1. 自動検証は上記CIで成功。ユーザー提供のmacOS 27 SDK環境では修正後の再ビルド結果を確認する。
2. Macのシステム設定「オプション」で本人のToken・Secretを入力し、機器選択と実測取得を確認。チャットへ送らせない。以前の認証成功を最初からやり直す必要はない。
3. プレビューアプリ、設定ホスト、実際のスクリーンセーバーホスト間のKeychainアクセスを検証。実行主体の違いにより許可が必要になる可能性があり、CIのモック成功では確認済みとしない。
4. macOS 26でのLiquid Glass、OSホスト内の描画、起動・停止、スリープ復帰、複数画面、通信失敗・復帰を手動確認。
5. インストール・更新・削除のUXと署名・公証を検証し、製品の対応OSと一般配布方式を決定。

## 参考資料

- [SwitchBot公式API](https://github.com/OpenWonderLabs/SwitchBotAPI)：署名と機器仕様を今回再確認。
- [Apple Screen Saver](https://developer.apple.com/documentation/screensaver)：設定シートの実装・終了方法を再確認。
- [Apple Liquid Glass](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:))：macOS 26での利用を確認。
- [remo-portal](https://github.com/psephopaiktes/remo-portal)：UX参考。コード再利用時はライセンスを確認。
