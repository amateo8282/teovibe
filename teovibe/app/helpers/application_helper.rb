module ApplicationHelper
  # 게시글 카테고리 slug 기반으로 라우트 경로 반환
  def url_for_post(post)
    slug = post.category&.slug
    case slug
    when "blog" then blog_path(post)
    when "tutorial" then tutorial_path(post)
    when "free-board" then free_board_path(post)
    when "qna" then qna_path(post)
    when "portfolio" then portfolio_path(post)
    when "notice" then notice_path(post)
    else post_path(post)
    end
  end
end
