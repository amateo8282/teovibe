module Admin
  class BaseController < ApplicationController
    before_action :require_admin!
    layout "admin"

    private

    def require_admin!
      unless Current.user&.admin?
        redirect_to root_path, alert: "관리자만 접근할 수 있습니다."
      end
    end
  end
end
