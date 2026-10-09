#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/ScreenSaver-Info.plist)"
python3 scripts/update-cask.py --version "$version" \
  --archive build/SwitchBotScreenSaver-macos.tar.gz --output build/switchbot-screen-saver.rb
ruby -c Casks/switchbot-screen-saver.rb
ruby -c build/switchbot-screen-saver.rb

# A temporary tap and local server test the just-built archive, not the previous release.
export HOMEBREW_NO_AUTO_UPDATE=1
brew tap-new codex/saver-ci
mkdir -p "$(brew --repository codex/saver-ci)/Casks"
python3 - <<'PY' > build/homebrew-http.log 2>&1 &
from functools import partial
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
server = ThreadingHTTPServer(('127.0.0.1', 0), partial(SimpleHTTPRequestHandler, directory='build'))
Path('build/homebrew-port').write_text(str(server.server_port))
server.serve_forever()
PY
saver_http_pid=$!
trap 'kill "$saver_http_pid" 2>/dev/null || true; brew untap codex/saver-ci >/dev/null 2>&1 || true' EXIT
for attempt in {1..50}; do
  [[ -s build/homebrew-port ]] && break
  sleep 0.1
done
port="$(cat build/homebrew-port)"
python3 scripts/update-cask.py --version "$version" \
  --archive build/SwitchBotScreenSaver-macos.tar.gz \
  --url "http://127.0.0.1:$port/SwitchBotScreenSaver-macos.tar.gz" \
  --output "$(brew --repository codex/saver-ci)/Casks/switchbot-screen-saver.rb"
brew install --cask --screen-saverdir="$repo_root/build/brew-installed" codex/saver-ci/switchbot-screen-saver
cmp Resources/thumbnail.png build/brew-installed/SwitchBotScreenSaver.saver/Contents/Resources/thumbnail.png
cmp Resources/thumbnail@2x.png build/brew-installed/SwitchBotScreenSaver.saver/Contents/Resources/thumbnail@2x.png
/usr/bin/codesign --verify --deep --strict build/brew-installed/SwitchBotScreenSaver.saver
brew uninstall --cask codex/saver-ci/switchbot-screen-saver
[[ ! -e build/brew-installed/SwitchBotScreenSaver.saver ]]
echo 'Homebrew checksum verification / screen saver installation / uninstall OK'
