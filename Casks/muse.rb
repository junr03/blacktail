require_relative "../lib/muse_download_strategy"

cask "muse" do
  version :latest
  sha256 :no_check

  url "https://ai.meta.com/muse/download/", using: BlacktailMuseDownloadStrategy
  name "Muse"
  desc "Personal AI agent from Meta"
  homepage "https://muse.ai/"

  auto_updates true
  depends_on macos: :sequoia

  app "Muse.app"

  uninstall quit: "com.meta.endo"
end
