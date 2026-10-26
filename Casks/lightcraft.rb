cask "lightcraft" do
  version "0.14.0"
  sha256 "cde8591da93f7b5aa7ad09137cc93c1ebf3b4748fe89e477bb036263d7c93e75"

  url "https://github.com/storytold/lightcraft/releases/download/v#{version}/lightcraft-#{version}-macos-universal.dmg"
  name "LightCraft"
  desc "Photo library and raw developer"
  homepage "https://github.com/storytold/lightcraft"

  app "LightCraft.app"
end
