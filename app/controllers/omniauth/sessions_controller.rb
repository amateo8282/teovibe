module Omniauth
  class SessionsController < ApplicationController
    allow_unauthenticated_access

    def create
      auth = request.env["omniauth.auth"]
      connected_service = ConnectedService.find_by(provider: auth.provider, uid: auth.uid)

      if connected_service
        # 기존 소셜 계정으로 로그인
        start_new_session_for connected_service.user
        redirect_to after_authentication_url, notice: "로그인되었습니다."
      elsif Current.user
        # 로그인 상태에서 소셜 계정 연결
        Current.user.connected_services.create!(
          provider: auth.provider,
          uid: auth.uid,
          access_token: auth.credentials.token
        )
        redirect_to me_path, notice: "#{auth.provider} 계정이 연결되었습니다."
      else
        # 새 사용자 생성
        user = User.create!(
          email_address: auth.info.email,
          nickname: auth.info.name || auth.info.email.split("@").first,
          avatar_url: auth.info.image,
          password: SecureRandom.hex(16)
        )
        user.connected_services.create!(
          provider: auth.provider,
          uid: auth.uid,
          access_token: auth.credentials.token
        )
        start_new_session_for user
        redirect_to root_path, notice: "회원가입이 완료되었습니다!"
      end
    end

    def failure
      redirect_to new_session_path, alert: "소셜 로그인에 실패했습니다. 다시 시도해주세요."
    end
  end
end
