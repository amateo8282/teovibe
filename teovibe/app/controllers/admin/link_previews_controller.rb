require "net/http"
require "nokogiri"
require "uri"

module Admin
  class LinkPreviewsController < BaseController
    MAX_REDIRECTS = 3

    # GET /admin/link_preview?url=https://...
    def show
      url = params[:url]

      unless url.present? && valid_url?(url)
        return render json: { error: "유효하지 않은 URL입니다" }, status: :bad_request
      end

      meta = fetch_og_meta(url, MAX_REDIRECTS)
      render json: meta
    rescue => e
      Rails.logger.error "[LinkPreview] fetch 실패: #{e.message}"
      render json: { title: nil, description: nil, image_url: nil, site_name: nil }
    end

    private

    def valid_url?(url)
      uri = URI.parse(url)
      uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    rescue URI::InvalidURIError
      false
    end

    def fetch_og_meta(url, redirects_left)
      return { title: nil, description: nil, image_url: nil, site_name: nil } if redirects_left <= 0

      uri = URI.parse(url)
      response = Net::HTTP.start(uri.host, uri.port,
        use_ssl:      uri.scheme == "https",
        open_timeout: 5,
        read_timeout: 5
      ) do |http|
        req = Net::HTTP::Get.new(uri.request_uri)
        req["User-Agent"] = "Mozilla/5.0 (compatible; TeoVibeBot/1.0)"
        req["Accept"]     = "text/html,application/xhtml+xml"
        http.request(req)
      end

      if response.is_a?(Net::HTTPRedirection) && response["location"]
        redirect_url = URI.join(url, response["location"]).to_s
        return fetch_og_meta(redirect_url, redirects_left - 1)
      end

      return { title: nil, description: nil, image_url: nil, site_name: nil } unless response.is_a?(Net::HTTPSuccess)

      doc = Nokogiri::HTML(response.body.force_encoding("UTF-8"))

      title       = og(doc, "og:title")       || doc.at("title")&.text&.strip
      description = og(doc, "og:description") || doc.at('meta[name="description"]')&.[]("content")
      image_url   = og(doc, "og:image")
      site_name   = og(doc, "og:site_name")

      # 상대 경로 이미지 URL 절대 경로로 변환
      if image_url.present? && !image_url.start_with?("http")
        image_url = URI.join(url, image_url).to_s rescue nil
      end

      {
        title:       title&.strip,
        description: description&.strip,
        image_url:   image_url,
        site_name:   site_name,
      }
    end

    def og(doc, property)
      doc.at("meta[property='#{property}']")&.[]("content")&.presence
    end
  end
end
