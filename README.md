# SwitchBot Screen Saver

[English](README.md) | [日本語](README.ja.md)

![OGP](OGP.png)

A free macOS screen saver with a clock, date, and temperature and humidity from your SwitchBot device.

## Install

Use [Homebrew](https://brew.sh/):

```sh
brew tap psephopaiktes/switchbot-screen-saver https://github.com/psephopaiktes/switchbot-screen-saver
brew install --cask psephopaiktes/switchbot-screen-saver/switchbot-screen-saver
```

If you previously installed the `.saver` manually, add `--force` to the install command to replace it.

Select **SwitchBot Screen Saver** in your Mac's screen saver settings. If Apple cannot verify it, click **Done** and allow it in **System Settings → Privacy & Security → Open Anyway**. Quit System Settings with **⌘Q**, reopen it, then open **Options** to configure the screen saver.

This screen saver is not notarized by Apple. Homebrew installation may still require this permission.

## Connect SwitchBot

To get your **Open Token** and **Secret** in the latest SwitchBot mobile app:

1. Sign in and open **Profile → Preferences → About**.
2. Tap **App Version** **10 times** to reveal **Developer Options**.
3. Open **Developer Options → Get Token** and copy both **Token** and **Secret**.

In the screen saver's **Options → SwitchBot** tab, turn off sample data (`サンプルデータで表示`), enter your **Open Token** and **Secret**, then click **Fetch devices** (`接続して機器を取得`). Select your device and click **Save** (`保存して表示に反映`). Your device must support temperature/humidity readings through the SwitchBot cloud API.

Credentials are stored in your Mac's Keychain. Do not share them. Readings update every five minutes. Sample mode and clock/date-only displays do not require credentials.

The app's menu names may vary by version. See the [official SwitchBot guide](https://github.com/OpenWonderLabs/SwitchBotAPI#getting-started).

## Customize

In **Options → Display** (`表示`), toggle the clock, temperature, humidity, and date individually, and choose a 12- or 24-hour clock. Dates follow your Mac's region settings; weekdays use English abbreviations.

## Update and uninstall

Quit System Settings and the screen saver before updating. Your saved settings are kept.

```sh
brew update
brew upgrade --cask psephopaiktes/switchbot-screen-saver/switchbot-screen-saver
```

To uninstall:

```sh
brew uninstall --cask psephopaiktes/switchbot-screen-saver/switchbot-screen-saver
```

Brewfile:

```ruby
tap "psephopaiktes/switchbot-screen-saver", "https://github.com/psephopaiktes/switchbot-screen-saver"
cask "psephopaiktes/switchbot-screen-saver/switchbot-screen-saver"
```
