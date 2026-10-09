#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/ScreenSaver-Info.plist)"
python3 scripts/update-cask.py --version "$version" \
  --archive build/SwitchBotScreenSaver-macos.tar.gz --output build/switchbot-screen-saver.rb
ruby -c Casks/switchbot-screen-saver.rb
ruby -c build/switchbot-screen-saver.rb

# A temporary tap tests the just-built archive, not the previous release.
export HOMEBREW_NO_AUTO_UPDATE=1
brew tap-new codex/saver-ci
mkdir -p "$(brew --repository codex/saver-ci)/Casks"
trap 'brew untap codex/saver-ci >/dev/null 2>&1 || true' EXIT
archive_url="$(python3 -c 'from pathlib import Path; print(Path("build/SwitchBotScreenSaver-macos.tar.gz").resolve().as_uri())')"
python3 scripts/update-cask.py --version "$version" \
  --archive build/SwitchBotScreenSaver-macos.tar.gz \
  --url "$archive_url" \
  --output "$(brew --repository codex/saver-ci)/Casks/switchbot-screen-saver.rb"
brew install --cask --screen-saverdir="$repo_root/build/brew-installed" codex/saver-ci/switchbot-screen-saver
cmp Resources/thumbnail.png build/brew-installed/SwitchBotScreenSaver.saver/Contents/Resources/thumbnail.png
cmp Resources/thumbnail@2x.png build/brew-installed/SwitchBotScreenSaver.saver/Contents/Resources/thumbnail@2x.png
/usr/bin/codesign --verify --deep --strict build/brew-installed/SwitchBotScreenSaver.saver
brew uninstall --cask codex/saver-ci/switchbot-screen-saver
[[ ! -e build/brew-installed/SwitchBotScreenSaver.saver ]]
echo 'Homebrew checksum verification / screen saver installation / uninstall OK'
