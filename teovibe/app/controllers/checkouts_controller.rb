class CheckoutsController < ApplicationController
  before_action :require_authentication
  before_action :set_skill_pack

  def show
    # 무료 스킬팩은 체크아웃 불필요
    if @skill_pack.price.zero?
      redirect_to skill_pack_path(@skill_pack), alert: "무료 스킬팩입니다."
      return
    end

    # pending 상태의 기존 주문이 있으면 재사용, 없으면 신규 생성
    @order = Order.find_or_create_by(
      user: Current.user,
      skill_pack: @skill_pack,
      status: :pending
    ) do |o|
      o.amount = @skill_pack.price
    end

    # payment_customer_key가 없으면 생성 후 저장 (기존 User에 컬럼이 없던 경우 대비)
    if Current.user.payment_customer_key.blank?
      Current.user.update!(payment_customer_key: SecureRandom.uuid)
    end

    @client_key = Rails.application.credentials.dig(:toss_payments, :client_key)
    @customer_key = Current.user.payment_customer_key
  end

  def success
    payment_key = params[:paymentKey]
    order_id = params[:orderId]

    # 주문 조회 (현재 사용자의 주문만 허용)
    order = Order.find_by!(toss_order_id: order_id, user: Current.user)

    # 금액 위변조 방지: 프론트엔드에서 전달한 amount와 DB Order의 amount 비교
    if params[:amount].to_i != order.amount
      order.update!(status: :failed)
      redirect_to fail_skill_pack_checkout_path(@skill_pack), alert: "금액이 일치하지 않습니다."
      return
    end

    # secret_key nil 방어 (credentials 미설정 시 로그 출력 후 실패 처리)
    secret_key = Rails.application.credentials.dig(:toss_payments, :secret_key)
    if secret_key.blank?
      Rails.logger.error("[CheckoutsController] toss_payments.secret_key가 credentials에 설정되지 않았습니다.")
      order.update!(status: :failed)
      redirect_to fail_skill_pack_checkout_path(@skill_pack), alert: "결제 확인에 실패했습니다."
      return
    end

    # 토스페이먼츠 서버사이드 confirm API 호출
    service = PaymentService.new(secret_key)
    result = service.confirm(payment_key: payment_key, order_id: order_id, amount: order.amount)

    if result[:success]
      # 결제 확정: Order 상태 paid로 업데이트 + paymentKey 저장
      order.update!(status: :paid, payment_event_id: payment_key)
      # 다운로드 권한 부여 (이미 있으면 find, 없으면 create)
      @skill_pack.downloads.find_or_create_by(user: Current.user)
      redirect_to skill_pack_path(@skill_pack), notice: "결제가 완료되었습니다."
    else
      # confirm 실패: Order 상태 failed로 업데이트
      order.update!(status: :failed)
      redirect_to fail_skill_pack_checkout_path(@skill_pack), alert: "결제 확인에 실패했습니다."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to skill_packs_path, alert: "주문을 찾을 수 없습니다."
  end

  def fail
    # fail.html.erb에서 params[:code], params[:message] 표시
  end

  private

  def set_skill_pack
    @skill_pack = SkillPack.published.find(params[:skill_pack_id] || params[:id])
  end
end
