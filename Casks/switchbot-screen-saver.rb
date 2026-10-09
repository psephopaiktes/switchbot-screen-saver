cask "switchbot-screen-saver" do
  version "1.0.0"
  sha256 "4d04d05ae7c0ceb5c87c0744c06e3bc3728eb3d05ccadc1f1dd36b5f8ba5e06e"

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
