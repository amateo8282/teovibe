# 커스텀 에러 페이지 컨트롤러
# ActionController::Base 직접 상속 — DB 에러 시에도 안전하게 렌더링
class ErrorsController < ActionController::Base
  layout "application"

  def not_found
    render status: :not_found
  end

  def internal_server_error
    # 500은 DB가 다운된 상황일 수 있으므로 navbar DB 쿼리를 피하기 위해 별도 레이아웃 사용
    render status: :internal_server_error, layout: "error"
  end

  def unprocessable_entity
    render status: :unprocessable_entity
  end
end
