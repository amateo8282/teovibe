class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "잠시 후 다시 시도해주세요." }
  before_action :set_noindex, only: %i[new]

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url, notice: "로그인되었습니다."
    else
      redirect_to new_session_path, alert: "이메일 또는 비밀번호를 확인해주세요."
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, notice: "로그아웃되었습니다.", status: :see_other
  end

  private

  # 검색엔진이 로그인 페이지를 색인하지 않도록 noindex 메타태그 설정
  def set_noindex
    set_meta_tags noindex: true
  end
end
