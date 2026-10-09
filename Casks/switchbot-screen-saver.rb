cask "switchbot-screen-saver" do
  version "1.0.1"
  sha256 "72124a7b432b1f373256b9dcf0f8302f4971584236050598c0cfb9f1204c87a5"

  url "https://github.com/psephopaiktes/switchbot-screen-saver/releases/download/v#{version}/SwitchBotScreenSaver-macos.tar.gz"
  name "SwitchBot Screen Saver"
  desc "Clock, date, and SwitchBot temperature and humidity screen saver"
  homepage "https://github.com/psephopaiktes/switchbot-screen-saver"

  depends_on macos: :ventura

  screen_saver "SwitchBotScreenSaver.saver"

  caveats <<~EOS
    Quit System Settings and the screen saver before upgrading.
    This screen saver is not notarized by Apple. If blocked, allow it in
    System Settings > Privacy & Security > Open Anyway, then reopen System Settings.
  EOS
end
