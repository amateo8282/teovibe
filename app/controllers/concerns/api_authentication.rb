module ApiAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :require_api_token
  end

  private

  def require_api_token
    token = request.headers["Authorization"]&.sub(/\ABearer\s+/, "")
    @current_api_user = User.find_by(api_token: token) if token.present?
    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_api_user
  end

  def current_api_user
    @current_api_user
  end
end
