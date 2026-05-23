module Admin
  class CommentsController < BaseController
    def index
      @comments = Comment.includes(:user, :post).order(created_at: :desc)
      @pagy, @comments = pagy(:offset, @comments, limit: 20)
    end

    def destroy
      @comment = Comment.find(params[:id])
      @comment.destroy
      redirect_to admin_comments_path, notice: "댓글이 삭제되었습니다.", status: :see_other
    end
  end
end
