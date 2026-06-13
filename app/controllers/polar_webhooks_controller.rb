# Polar 웹훅 — 결제 시 회원 계정에 자격 부여, 환불 시 회수.
# 활성화 조건: Polar 대시보드에 엔드포인트 등록 + ENV["POLAR_WEBHOOK_SECRET"] 설정.
# (미설정 시 verify 실패로 401 — 안전한 기본값. 라이선스 키 unlock 경로는 웹훅 없이도 동작.)
class PolarWebhooksController < ApplicationController
  allow_unauthenticated_access
  skip_forgery_protection

  def create
    payload = request.body.read
    unless PolarService.verify_webhook(payload: payload, headers: request.headers)
      return head :unauthorized
    end

    event = JSON.parse(payload)
    handle(event)
    head :ok
  rescue JSON::ParserError
    head :bad_request
  end

  private

  def handle(event)
    data = event["data"] || {}
    case event["type"]
    when "order.paid", "order.created"
      grant(data)
    when "order.refunded", "benefit_grant.revoked", "subscription.revoked"
      revoke(data)
    end
  end

  def grant(data)
    email = data.dig("customer", "email") || data["customer_email"]
    benefit_id = extract_benefit_id(data)
    return if email.blank? || benefit_id.blank?

    course = Course.find_by(polar_benefit_id: benefit_id)
    user = User.find_by(email_address: email.to_s.downcase)
    return unless course && user

    ent = user.entitlements.find_or_initialize_by(course: course)
    ent.assign_attributes(source: :purchase, status: :active, revoked_at: nil, polar_order_id: data["id"])
    ent.save!
  end

  def revoke(data)
    order_id = data["id"] || data["order_id"]
    return if order_id.blank?
    Entitlement.where(polar_order_id: order_id).find_each(&:revoke!)
  end

  def extract_benefit_id(data)
    data["benefit_id"] ||
      data.dig("product", "benefits")&.first&.dig("id") ||
      Array(data["benefits"]).first&.dig("id")
  end
end
