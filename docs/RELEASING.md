# リリース手順

利用者向けの案内は[English](../README.md) / [日本語](../README.ja.md)。READMEのダウンロード先は常に[Releases](https://github.com/psephopaiktes/switchbot-screen-saver/releases)です。

1. `Resources/ScreenSaver-Info.plist`の`CFBundleShortVersionString`と`CFBundleVersion`を更新し、変更をPRにまとめます。ログのバージョン表記も合わせます。
2. macOS CIのビルド・テストが成功したリリース対象のコミットを選びます。通常はPRをmainに統合してから行います。
3. そのコミットにバージョンタグを付けてpushします（例は`v1.0.0`）。

```sh
git tag v1.0.0 <リリース対象のコミット>
git push origin v1.0.0
```

タグをpushするとReleaseワークフローが起動します。タグとバンドルのバージョン一致を確認した後、既存のmacOS 15 / 26 / 27 CIを呼び出します。すべて成功するとmacOS 15で作成したarm64 / x86_64のZIPをReleaseへ添付し、公開状態にします。ZIPのファイル名は毎回`SwitchBotScreenSaver-macos.zip`です。OGPと一覧サムネイルにはユーザー提供画像を使用します。

アップロード中はdraftにし、ZIPの添付後に公開します。公開済みの同じタグのReleaseは上書きしません。添付に失敗してdraftが残った場合はワークフローを再実行できます。コードを変更する場合はバージョンとタグを更新してください。

ユーザーの指示によりリポジトリはPublicで配布します。Release作成のワークフロー自体はリポジトリの公開設定を変更しません。ライセンスは未決定です。

配布物は無料・ad-hoc署名で、Developer ID署名・Apple公証は行いません。ダウンロード後の個別許可とインストールをMacで確認してください。証明書や利用者のToken・SecretをCIへ登録する必要はありません。
