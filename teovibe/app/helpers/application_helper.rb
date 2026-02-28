module ApplicationHelper
  # 게시글 상세 경로 반환 (slug 기반 통합 라우트)
  def url_for_post(post)
    post_path(post)
  end

  # 현재 사용자에게 노출 가능한 게시글 카테고리 목록 (admin_only 필터 적용)
  def available_post_categories
    if Current.user&.admin?
      Category.for_posts.ordered
    else
      Category.for_posts.where(admin_only: false).ordered
    end
  end
end
