require "base64"

# 토스페이먼츠 서버사이드 결제 확인(confirm) API 호출 서비스
# 공식 문서: https://docs.tosspayments.com/reference/using-api/authorization
class PaymentService
  TOSS_CONFIRM_URL = "https://api.tosspayments.com/v1/payments/confirm"

  def initialize(secret_key)
    @secret_key = secret_key
  end

  # 토스페이먼츠 confirm API 호출
  # @param payment_key [String] 토스페이먼츠 paymentKey (결제 고유 키)
  # @param order_id [String] 우리 서버의 toss_order_id
  # @param amount [Integer] 결제 금액 (원 단위)
  # @return [Hash] { success: true, data: ... } 또는 { success: false, error: ... }
  def confirm(payment_key:, order_id:, amount:)
    conn = Faraday.new do |f|
      f.request :json
      f.response :json
      f.response :raise_error
    end

    # Basic auth: secret_key + 콜론을 base64 인코딩 (토스페이먼츠 인증 방식)
    encoded = Base64.strict_encode64("#{@secret_key}:")

    response = conn.post(TOSS_CONFIRM_URL) do |req|
      req.headers["Authorization"] = "Basic #{encoded}"
      req.headers["Content-Type"] = "application/json"
      req.body = {
        paymentKey: payment_key,
        orderId: order_id,
        amount: amount
      }.to_json
    end

    { success: true, data: response.body }
  rescue Faraday::Error => e
    Rails.logger.error("[PaymentService] confirm 실패: #{e.message}")
    { success: false, error: e.message }
  end
end
