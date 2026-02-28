class LikesController < ApplicationController
  before_action :set_likeable

  def create
    @like = @likeable.likes.find_or_create_by(user: Current.user)
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@likeable, :like), partial: "likes/button", locals: { likeable: @likeable }) }
      format.html { redirect_back fallback_location: root_path }
    end
  end

  def destroy
    @like = @likeable.likes.find_by(user: Current.user)
    @like&.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@likeable, :like), partial: "likes/button", locals: { likeable: @likeable }) }
      format.html { redirect_back fallback_location: root_path }
    end
  end

  private

  def set_likeable
    if params[:post_slug]
      @likeable = Post.find_by!(slug: params[:post_slug])
    elsif params[:comment_id]
      @likeable = Comment.find(params[:comment_id])
    end
  end
end
