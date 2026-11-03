cask "lightcraft" do
  version "0.17.0"
  sha256 "656a4dbe34edabe478f6ba1c838f718ea67e5ca7c61c1591c7be08dc3621a14b"

  url "https://github.com/storytold/lightcraft/releases/download/v#{version}/lightcraft-#{version}-macos-universal.dmg"
  name "LightCraft"
  desc "Photo library and raw developer"
  homepage "https://github.com/storytold/lightcraft"

  app "LightCraft.app"
end
