module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[show edit update]

    def index
      @users = User.order(created_at: :desc)
      @pagy, @users = pagy(:offset, @users, limit: 20)
    end

    def show
    end

    def edit
    end

    def update
      if @user.update(user_params)
        redirect_to admin_users_path, notice: "사용자 정보가 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:nickname, :role, :bio)
    end
  end
end
