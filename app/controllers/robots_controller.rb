class RobotsController < ApplicationController
  # 인증 없이 접근 가능 (공개 크롤링 정책 파일)
  allow_unauthenticated_access

  def show
    # 6시간 캐시 (CDN/프록시 포함)
    expires_in 6.hours, public: true
    respond_to :text
  end
end
