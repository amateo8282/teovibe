class ProfilesController < ApplicationController
  def show
    @user = Current.user
  end

  def edit
    @user = Current.user
  end

  def points
    @user = Current.user
    @point_transactions = @user.point_transactions.order(created_at: :desc)
    @pagy, @point_transactions = pagy(:offset, @point_transactions, limit: 20)
  end

  def update
    @user = Current.user
    if @user.update(profile_params)
      redirect_to me_path, notice: "프로필이 업데이트되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:nickname, :bio, :avatar_url, :avatar, :github_url, :twitter_url, :website_url)
  end
end
