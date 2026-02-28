class QnasController < PostsBaseController
  before_action :set_qna_post, only: [:accept]
  before_action :set_comment_for_accept, only: [:accept]

  def accept
    unless @qna_post.user == Current.user
      redirect_to qna_path(@qna_post), alert: "질문 작성자만 채택할 수 있습니다."
      return
    end

    # 기존 채택 해제
    @qna_post.comments.where(accepted: true).update_all(accepted: false)
    @comment.update!(accepted: true)

    redirect_to qna_path(@qna_post), notice: "답변이 채택되었습니다."
  end

  private

  def category_record
    Category.find_by!(slug: "qna", record_type: :post)
  end

  def set_qna_post
    @qna_post = Post.find(params[:qna_id])
  end

  def set_comment_for_accept
    @comment = @qna_post.comments.find(params[:id])
  end
end
