# リリース手順

利用者向けの案内は[English](../README.md) / [日本語](../README.ja.md)。Homebrew Caskは同じリポジトリの`Casks/switchbot-screen-saver.rb`で管理します。専用の別リポジトリは不要ですが、通常のTap名の規約に沿う名前ではないため、初回の`brew tap`にはREADMEのリポジトリURLを指定します。

1. `Resources/ScreenSaver-Info.plist`の`CFBundleShortVersionString`と`CFBundleVersion`を更新し、診断ログのバージョンも合わせてPRにまとめます。Caskはこの時点で更新しません。
2. macOS CIのビルド・テスト・Homebrewのインストール／削除が成功したら、PRをmainへ統合します。
3. そのコミットにバンドルと同じバージョンのタグを付けてpushします。

```sh
git tag v1.0.1 <リリース対象のコミット>
git push origin v1.0.1
```

ReleaseワークフローはmacOS 15／26／27で検証し、macOS 15で作成したarm64／x86_64の`SwitchBotScreenSaver-macos.tar.gz`をReleaseへ添付します。アーカイブには`.saver`だけを入れ、ZIPや同梱説明ファイルは作りません。利用者はHomebrewでインストールするため、自分で展開する必要はありません。

添付したアーカイブのバージョンと構成を検証し、SHA-256を固定したCaskを生成します。Releaseの公開後、ワークフローの`contents: write`権限でmainのCaskを更新します。利用者は`brew update`と`brew upgrade --cask psephopaiktes/switchbot-screen-saver/switchbot-screen-saver`で更新できます。

公開済みの同じタグのアセットは上書きしません。Cask更新は古いバージョンへの戻しや同じバージョンの内容変更を拒否し、GitHubのファイルSHAで同時更新の競合も検出します。mainの保護ルールがbotによるファイル更新を禁止する場合、Cask更新ジョブは失敗します。その場合はReleaseのアーカイブから`scripts/update-cask.py`でCaskを生成し、PRで更新してください。公開済みReleaseを作り直さないでください。

最初のHomebrew配布は、検証済みPRブランチから作成したv1.0.1です。初回CaskはReleaseワークフローがmainへ登録済みです。旧ZIPは過去のReleaseの記録として残しますが、新しい配布処理では生成しません。

リポジトリはPublicで無料配布します。ライセンスは未決定です。ad-hoc署名の配布物であり、Developer ID署名・Apple公証は行いません。Homebrew経由でもGatekeeperやKeychainの許可が不要になるとは扱わず、実機で確認してください。利用者のToken・Secretや証明書をCIに登録する必要はありません。
