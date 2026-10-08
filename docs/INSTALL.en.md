# Getting started

1. Double-click `SwitchBotScreenSaver.saver` and choose **Install for this user only**.
2. Select **SwitchBot Screen Saver** in System Settings' screen saver settings.
3. If Apple cannot verify the screen saver, click **Done**. In **System Settings → Privacy & Security**, choose **Open Anyway** for this screen saver and follow the prompts.
4. Quit System Settings with **⌘Q**, reopen it, and open the screen saver's **Options**.

This free download is not notarized by Apple. You may need to allow it again after an update. Do not disable macOS security globally.

## Get your SwitchBot credentials

In the latest SwitchBot mobile app, sign in and open **Profile → Preferences → About**. Tap **App Version** ten times to reveal **Developer Options**, then open **Developer Options → Get Token**. Copy both **Token** and **Secret**. Menu names may vary by version; see https://github.com/OpenWonderLabs/SwitchBotAPI#getting-started.

In **Options → SwitchBot**, turn off sample data (`サンプルデータで表示`), enter your **Open Token** and **Secret**, then fetch devices (`接続して機器を取得`), select your device, and save (`保存して表示に反映`). The device must support temperature/humidity readings through SwitchBot's cloud API.

Credentials are kept in your Mac's Keychain. Do not share them. Readings update every five minutes. You can use sample mode or display only the clock and date without credentials.

## Customize and update

In **Options → Display** (`表示`), toggle each item and choose a 12- or 24-hour clock. Dates follow your Mac's region settings; weekdays use English abbreviations.

To update, quit System Settings and the screen saver, then install the new `.saver` over the existing one. Your saved settings are kept.

Downloads: https://github.com/psephopaiktes/switchbot-screen-saver/releases
