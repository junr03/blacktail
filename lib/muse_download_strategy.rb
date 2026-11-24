require "cgi"
require "uri"
require "download_strategy"

# Meta publishes expiring CDN links, so resolve one only when Homebrew downloads.
class BlacktailMuseDownloadStrategy < CurlDownloadStrategy
  DOWNLOAD_PAGE = "https://ai.meta.com/muse/download/".freeze

  def self.download_url(page)
    links = page.scan(/href=["']([^"']+)["']/i).flatten
    link = links.map { |value| CGI.unescapeHTML(value) }.find do |value|
      uri = URI.parse(value)
      uri.scheme == "https" && uri.host&.end_with?(".fbcdn.net") &&
        uri.path.match?(%r{/Muse-[^/]+\.dmg\z})
    rescue URI::InvalidURIError
      false
    end
    raise "Meta's Muse download page has no Mac installer link" unless link

    link
  end

  private

  def resolve_url_basename_time_file_size(url, timeout: nil)
    if url == DOWNLOAD_PAGE
      # Meta's crawler rendering includes the download links without JavaScript.
      page = curl_output("--fail", "--location", "--silent", "--show-error",
                         "--max-time", (timeout || 60).to_s,
                         "--user-agent", "Googlebot", DOWNLOAD_PAGE)
      page.assert_success!
      url = self.class.download_url(page.stdout)
    end

    super(url, timeout: timeout)
  end
end
