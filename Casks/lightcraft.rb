cask "lightcraft" do
  version "0.21.1"
  sha256 "b70f46cac01390154c9adfa06822e6691b95fc270c507b0ed220a00dc588bb1e"

  url "https://github.com/storytold/lightcraft/releases/download/v#{version}/lightcraft-#{version}-macos-universal.dmg"
  name "LightCraft"
  desc "Photo library and raw developer"
  homepage "https://github.com/storytold/lightcraft"

  app "LightCraft.app"
end
