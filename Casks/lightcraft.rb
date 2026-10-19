cask "lightcraft" do
  version "0.9.1"
  sha256 "5e3fde7755d0fd0fa91114fc58ef51093a81b6177dcd9aece0142b4ec10e1c5a"

  url "https://github.com/storytold/lightcraft/releases/download/v#{version}/lightcraft-#{version}-macos-universal.dmg"
  name "LightCraft"
  desc "Photo library and raw developer"
  homepage "https://github.com/storytold/lightcraft"

  app "LightCraft.app"
end
