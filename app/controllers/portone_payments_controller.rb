require "securerandom"

# 포트원(PortOne) V2 결제 — 한국 고객용 결제 경로(Polar와 병행).
# 흐름: create(pending 생성→SDK 파라미터) → 브라우저 SDK 결제창 → complete(서버 단건조회 검증→자격부여).
# webhook = 가상계좌 입금/취소·환불 등 비동기 상태 반영. 미설정(.env 비어있음) 시 결제 비활성.
class PortonePaymentsController < ApplicationController
  allow_unauthenticated_access only: :webhook
  skip_forgery_protection only: :webhook

  # POST /courses/:slug/checkout — 결제 시작(로그인 필수). pending Payment 생성 후 SDK 파라미터 반환.
  def create
    course = Course.published.find_by!(slug: params[:slug])
    return render_error("무료 강의입니다.", :unprocessable_entity) unless course.paid?
    return render_error("결제 준비 중입니다.", :service_unavailable) unless PortoneService.configured?
    return render json: { already: true, redirect: course_path(course) } if current_user.entitled_to?(course)

    pid = "tv_#{course.slug}_#{SecureRandom.hex(12)}"
    current_user.payments.create!(course: course, payment_id: pid, amount: course.price, status: :pending)

    render json: {
      payment_id:  pid,
      store_id:    ENV["PORTONE_STORE_ID"],
      channel_key: ENV["PORTONE_CHANNEL_KEY"],
      order_name:  course.title,
      amount:      course.price,
      currency:    "CURRENCY_KRW"
    }
  end

  # POST /payments/:payment_id/complete — 결제 완료 검증(로그인 필수).
  # 서버가 포트원에 단건조회로 status==PAID && 금액 일치 확인 후에만 자격 부여(위변조 방지).
  def complete
    payment = current_user.payments.find_by!(payment_id: params[:payment_id])
    return render json: { ok: true, redirect: course_path(payment.course) } if payment.paid?

    info = PortoneService.new.fetch_payment(payment.payment_id)
    return render_error("결제 정보를 확인할 수 없습니다.", :bad_gateway) unless info

    unless info[:status] == "PAID" && info[:amount].to_i == payment.amount
      payment.failed!
      return render_error("결제가 완료되지 않았거나 금액이 일치하지 않습니다.", :unprocessable_entity)
    end

    grant!(payment)
    render json: { ok: true, redirect: course_path(payment.course) }
  end

  # POST /webhooks/portone — 비동기 상태(가상계좌 입금/취소·환불) 반영.
  def webhook
    body = request.body.read
    return head :unauthorized unless PortoneService.verify_webhook(payload: body, headers: request.headers)

    event = JSON.parse(body)
    pid = event.dig("data", "paymentId") || event.dig("data", "payment_id")
    payment = pid && Payment.find_by(payment_id: pid)
    return head :ok unless payment

    type = event["type"].to_s.downcase
    if type.include?("cancel")
      revoke!(payment)
    elsif type.include?("paid")
      info = PortoneService.new.fetch_payment(pid)
      grant!(payment) if info && info[:status] == "PAID" && info[:amount].to_i == payment.amount
    end
    head :ok
  rescue JSON::ParserError
    head :bad_request
  end

  private

  def grant!(payment)
    payment.paid! unless payment.paid?
    ent = payment.user.entitlements.find_or_initialize_by(course: payment.course)
    ent.assign_attributes(source: :purchase, status: :active, revoked_at: nil)
    ent.save!
  end

  def revoke!(payment)
    payment.cancelled! unless payment.cancelled?
    payment.user.entitlements.where(course: payment.course, source: :purchase).find_each(&:revoke!)
  end

  def render_error(msg, status)
    render json: { ok: false, error: msg }, status: status
  end
end
