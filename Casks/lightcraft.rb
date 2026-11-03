cask "lightcraft" do
  version "0.18.0"
  sha256 "sha256:f3cb326a202a2d6f89bd2d08ccd8b108e8efe103bb9da88c2a38e52a29f93e5a"

  url "https://github.com/storytold/lightcraft/releases/download/v#{version}/lightcraft-#{version}-macos-universal.dmg"
  name "LightCraft"
  desc "Photo library and raw developer"
  homepage "https://github.com/storytold/lightcraft"

  app "LightCraft.app"
end
