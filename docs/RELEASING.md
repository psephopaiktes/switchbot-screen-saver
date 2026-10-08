# リリース手順

利用者向けの案内は[English](../README.md) / [日本語](../README.ja.md)。READMEのダウンロード先は常に[Releases](https://github.com/psephopaiktes/switchbot-screen-saver/releases)です。

1. `Resources/ScreenSaver-Info.plist`の`CFBundleShortVersionString`と`CFBundleVersion`を更新し、変更をPRにまとめます。ログのバージョン表記も合わせます。
2. macOS CIのビルド・テストが成功したリリース対象のコミットを選びます。通常はPRをmainに統合してから行います。
3. そのコミットにバージョンタグを付けてpushします（例は`v0.3.1`）。

```sh
git tag v0.3.1 <リリース対象のコミット>
git push origin v0.3.1
```

タグをpushするとReleaseワークフローが起動します。タグとバンドルのバージョン一致を確認した後、既存のmacOS 15 / 26 / 27 CIを呼び出します。すべて成功するとmacOS 15で作成したarm64 / x86_64のZIPをReleaseへ添付し、公開状態にします。ZIPのファイル名は毎回`SwitchBotScreenSaver-macos.zip`です。OGP画像は利用者が後で追加予定です。

アップロード中はdraftにし、ZIPの添付後に公開します。公開済みの同じタグのReleaseは上書きしません。添付に失敗してdraftが残った場合はワークフローを再実行できます。コードを変更する場合はバージョンとタグを更新してください。

リポジトリがprivateの間はReleaseもリポジトリの閲覧権限がある人だけに見えます。Release作成はリポジトリの公開設定を変更しません。一般向けの公開範囲とライセンスは別途決定します。

配布物は無料・ad-hoc署名で、Developer ID署名・Apple公証は行いません。ダウンロード後の個別許可とインストールをMacで確認してください。証明書や利用者のToken・SecretをCIへ登録する必要はありません。
