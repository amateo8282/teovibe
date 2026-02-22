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
    # Plan 03에서 confirm 로직 추가 예정
    # 현재는 success.html.erb에서 안내 메시지만 표시
    # params[:paymentKey], params[:orderId], params[:amount]는 뷰에서 사용
  end

  def fail
    # fail.html.erb에서 params[:code], params[:message] 표시
  end

  private

  def set_skill_pack
    @skill_pack = SkillPack.published.find(params[:skill_pack_id] || params[:id])
  end
end
