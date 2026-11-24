require "minitest/autorun"

# Test the resolver without loading Homebrew or making network requests.
class CurlDownloadStrategy
  attr_reader :resolved_url, :curl_arguments

  def resolve_url_basename_time_file_size(url, timeout: nil)
    @resolved_url = url
    [url, "Muse-13.1.dmg", nil, nil, nil, false]
  end
end
$LOADED_FEATURES << "download_strategy.rb"
require_relative "../lib/muse_download_strategy"

class MuseDownloadStrategyTest < Minitest::Test
  URL = "https://scontent-sea5-2.xx.fbcdn.net/v/installer/Muse-13.1.dmg?oe=123&oh=signature".freeze

  def test_extracts_and_decodes_the_official_mac_link
    page = <<~HTML
      <a href="https://apps.apple.com/us/app/muse-from-meta/id6760173601">iOS</a>
      <a href="#{URL.gsub('&', '&amp;')}">Download for macOS</a>
    HTML
    assert_equal URL, BlacktailMuseDownloadStrategy.download_url(page)
  end

  def test_rejects_unexpected_download_hosts_and_artifacts
    ["https://fbcdn.net.evil.example/Muse-13.1.dmg",
     "https://evil.example/Muse-13.1.dmg",
     "http://scontent.xx.fbcdn.net/Muse-13.1.dmg",
     "https://scontent.xx.fbcdn.net/Other.app.zip"].each do |url|
      assert_raises(RuntimeError) { BlacktailMuseDownloadStrategy.download_url(%(<a href="#{url}">)) }
    end
  end

  def test_reports_a_missing_installer
    error = assert_raises(RuntimeError) { BlacktailMuseDownloadStrategy.download_url("<html></html>") }
    assert_match(/no Mac installer link/, error.message)
  end

  def test_skips_malformed_links_before_the_installer
    page = %(<a href="https://bad host/"><a href="#{URL}">)
    assert_equal URL, BlacktailMuseDownloadStrategy.download_url(page)
  end

  def test_stops_when_the_download_page_cannot_be_fetched
    strategy = BlacktailMuseDownloadStrategy.new
    result = Object.new
    result.define_singleton_method(:assert_success!) { raise "Download page failed" }
    strategy.define_singleton_method(:curl_output) { |*_args| result }

    error = assert_raises(RuntimeError) do
      strategy.send(:resolve_url_basename_time_file_size, BlacktailMuseDownloadStrategy::DOWNLOAD_PAGE)
    end
    assert_equal "Download page failed", error.message
    assert_nil strategy.resolved_url
  end

  def test_resolves_at_download_time_and_passes_through_other_urls
    strategy = BlacktailMuseDownloadStrategy.new
    result = Struct.new(:stdout) do
      def assert_success!; end
    end.new(%(<a href="#{URL}">))
    strategy.define_singleton_method(:curl_output) do |*args|
      @curl_arguments = args
      result
    end

    strategy.send(:resolve_url_basename_time_file_size, BlacktailMuseDownloadStrategy::DOWNLOAD_PAGE, timeout: 20)
    assert_equal URL, strategy.resolved_url
    assert_includes strategy.curl_arguments, "20"

    strategy.send(:resolve_url_basename_time_file_size, URL)
    assert_equal URL, strategy.resolved_url
  end
end
