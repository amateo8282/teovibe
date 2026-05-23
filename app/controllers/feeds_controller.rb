class FeedsController < ApplicationController
  allow_unauthenticated_access

  def index
    @posts = Post.published.where(category: %i[blog tutorial]).order(created_at: :desc).limit(20)
    respond_to do |format|
      format.atom
    end
  end
end
