require "openssl"
require "base64"
require "cgi"

# 포트원(PortOne) V2 결제 연동 — 결제 단건조회 검증 + 웹훅 서명검증(Standard Webhooks).
# 런타임 인증 = V2 API Secret(콘솔 결제연동 탭 발급). 미설정 시 결제 비활성(안전 기본값).
# 결제창 파라미터(store_id·channel_key)도 ENV 기반 — 승인 후 .env만 채우면 켜짐(ready-to-flip).
class PortoneService
  API = "https://api.portone.io".freeze

  # 결제 기능 활성 조건: 결제창에 필요한 3개 값이 모두 있어야 함.
  def self.configured?
    ENV["PORTONE_STORE_ID"].present? &&
      ENV["PORTONE_CHANNEL_KEY"].present? &&
      ENV["PORTONE_API_SECRET"].present?
  end

  def initialize(secret: ENV["PORTONE_API_SECRET"])
    @secret = secret
  end

  # 결제 단건조회. 반환: { status:, amount:, order_name:, custom_data:, raw: } | nil
  def fetch_payment(payment_id)
    return nil if @secret.blank? || payment_id.blank?

    conn = Faraday.new { |f| f.response :json }
    res = conn.get("#{API}/payments/#{CGI.escape(payment_id)}") do |req|
      req.headers["Authorization"] = "PortOne #{@secret}"
    end
    return nil unless res.status == 200 && res.body.is_a?(Hash)

    b = res.body
    {
      status: b["status"],                 # PAID / VIRTUAL_ACCOUNT_ISSUED / CANCELLED / FAILED ...
      amount: b.dig("amount", "total"),
      order_name: b["orderName"],
      custom_data: b["customData"],
      raw: b
    }
  rescue Faraday::Error => e
    Rails.logger.error("[PortoneService] fetch 실패: #{e.message}")
    nil
  end

  # Standard Webhooks 서명 검증 (포트원 V2 웹훅). secret = "whsec_..." (base64).
  # headers: { "webhook-id" =>, "webhook-timestamp" =>, "webhook-signature" => }
  def self.verify_webhook(payload:, headers:, secret: ENV["PORTONE_WEBHOOK_SECRET"])
    return false if secret.blank?

    id  = headers["webhook-id"] || headers["HTTP_WEBHOOK_ID"]
    ts  = headers["webhook-timestamp"] || headers["HTTP_WEBHOOK_TIMESTAMP"]
    sig = headers["webhook-signature"] || headers["HTTP_WEBHOOK_SIGNATURE"]
    return false if id.blank? || ts.blank? || sig.blank?

    key = Base64.decode64(secret.delete_prefix("whsec_"))
    signed = "#{id}.#{ts}.#{payload}"
    expected = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", key, signed))

    sig.split(" ").any? do |part|
      _version, value = part.split(",", 2)
      value && ActiveSupport::SecurityUtils.secure_compare(value, expected)
    end
  rescue StandardError => e
    Rails.logger.error("[PortoneService] webhook 검증 오류: #{e.message}")
    false
  end
end
