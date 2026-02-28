class CommentsController < ApplicationController
  def create
    @post = Post.find(params[:post_id] || comment_params[:post_id])
    @comment = @post.comments.build(comment_params.merge(user: Current.user))

    if @comment.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to post_path(@post), notice: "댓글이 작성되었습니다." }
      end
    else
      redirect_to post_path(@post), alert: "댓글 작성에 실패했습니다."
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    unless @comment.user == Current.user || Current.user&.admin?
      return redirect_to root_path, alert: "권한이 없습니다."
    end

    @comment.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: root_path, notice: "댓글이 삭제되었습니다." }
    end
  end

  # QnA 답변 채택
  def accept
    @comment = Comment.find(params[:id])
    @post = @comment.post

    unless @post.user == Current.user
      redirect_to post_path(@post), alert: "질문 작성자만 채택할 수 있습니다."
      return
    end

    # 기존 채택 해제
    @post.comments.where(accepted: true).update_all(accepted: false)
    @comment.update!(accepted: true)

    redirect_to post_path(@post), notice: "답변이 채택되었습니다."
  end

  private

  def comment_params
    params.require(:comment).permit(:body, :post_id, :parent_id)
  end
end
