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
    amount = params[:amount].to_i

    # Plan 03에서 confirm 로직 추가 예정
    # 현재는 안내 메시지만 표시
    flash[:notice] = "결제 확인 처리 중입니다. (orderId: #{order_id})"
    redirect_to skill_pack_path(@skill_pack)
  end

  def fail
    code = params[:code]
    message = params[:message]
    flash[:alert] = "결제에 실패했습니다. [#{code}] #{message}"
    redirect_to skill_pack_checkout_path(@skill_pack)
  end

  private

  def set_skill_pack
    @skill_pack = SkillPack.published.find(params[:skill_pack_id] || params[:id])
  end
end
