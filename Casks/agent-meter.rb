cask "agent-meter" do
  version "2805d3ae0742ed35a93961f1d27baf9fbf95eec1"
  sha256 "60ce63fd130ba0369bd2f388b1b6cdfaa8a854ad284c46d9728df69ff795f94b"

  url "https://codeload.github.com/amazingyyc/AgentMeter/tar.gz/#{version}"
  name "Agent Meter"
  desc "Menu bar monitor for coding agents in Rex and Ghostty"
  homepage "https://github.com/amazingyyc/AgentMeter"

  depends_on macos: :sonoma

  preflight do
    system_command "/bin/zsh",
                   args: ["#{staged_path}/AgentMeter-#{version}/scripts/build-app.sh"]
  end

  app "AgentMeter-#{version}/build/Agent Meter.app"

  uninstall quit: "dev.yyc.AgentMeter"

  caveats <<~EOS
    Agent Meter builds from source during installation and requires Swift 6.0 or later from Xcode Command Line Tools.
  EOS
end
