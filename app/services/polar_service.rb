require "openssl"
require "base64"

# Polar 결제 연동 서비스 — 라이선스 키 검증 + 웹훅 서명 검증.
# 앱 런타임은 Organization Access Token을 쓰지 않는다(검증 엔드포인트는 org_id만 쓰는 공개 customer-portal).
class PolarService
  def initialize(base: ENV["POLAR_BASE"], org_id: ENV["POLAR_ORG_ID"])
    @base = (base.presence || "https://api.polar.sh").chomp("/")
    @org_id = org_id
  end

  # 라이선스 키 검증. 반환: { granted: Boolean, benefit_id: String|nil }
  def validate_license_key(key)
    return { granted: false, benefit_id: nil } if @org_id.blank? || key.blank?

    conn = Faraday.new do |f|
      f.request :json
      f.response :json
    end
    res = conn.post("#{@base}/v1/customer-portal/license-keys/validate") do |req|
      req.body = { key: key, organization_id: @org_id }
    end

    if res.status == 200 && res.body.is_a?(Hash)
      { granted: res.body["status"] == "granted", benefit_id: res.body["benefit_id"] }
    else
      { granted: false, benefit_id: nil }
    end
  rescue Faraday::Error => e
    Rails.logger.error("[PolarService] validate 실패: #{e.message}")
    { granted: false, benefit_id: nil }
  end

  # Standard Webhooks 서명 검증 (Polar 웹훅). secret = "whsec_..." (base64).
  # headers: { "webhook-id" =>, "webhook-timestamp" =>, "webhook-signature" => }
  def self.verify_webhook(payload:, headers:, secret: ENV["POLAR_WEBHOOK_SECRET"])
    return false if secret.blank?

    id = headers["webhook-id"] || headers["HTTP_WEBHOOK_ID"]
    ts = headers["webhook-timestamp"] || headers["HTTP_WEBHOOK_TIMESTAMP"]
    sig_header = headers["webhook-signature"] || headers["HTTP_WEBHOOK_SIGNATURE"]
    return false if id.blank? || ts.blank? || sig_header.blank?

    key = Base64.decode64(secret.delete_prefix("whsec_"))
    signed = "#{id}.#{ts}.#{payload}"
    expected = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", key, signed))

    sig_header.split(" ").any? do |part|
      _version, value = part.split(",", 2)
      value && ActiveSupport::SecurityUtils.secure_compare(value, expected)
    end
  rescue StandardError => e
    Rails.logger.error("[PolarService] webhook 검증 오류: #{e.message}")
    false
  end
end
