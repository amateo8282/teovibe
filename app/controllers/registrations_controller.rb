class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  before_action :set_noindex, only: %i[new]

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)

    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: "회원가입이 완료되었습니다!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(:email_address, :nickname, :password, :password_confirmation)
  end

  # 검색엔진이 회원가입 페이지를 색인하지 않도록 noindex 메타태그 설정
  def set_noindex
    set_meta_tags noindex: true
  end
end
