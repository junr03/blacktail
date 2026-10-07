cask "lightcraft" do
  version "0.2.1"
  sha256 "d40c7ea8a3b840227229eaabf573242d173195acba8e25be16259e15cb65dfbb"

  url "https://github.com/storytold/lightcraft/releases/download/v#{version}/lightcraft-#{version}-macos-universal.dmg"
  name "LightCraft"
  desc "Photo library and raw developer"
  homepage "https://github.com/storytold/lightcraft"

  app "LightCraft.app"
end
